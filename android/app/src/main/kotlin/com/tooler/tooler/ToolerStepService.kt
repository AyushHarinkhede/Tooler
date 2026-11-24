package com.tooler.tooler

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.sqrt

/**
 * ---------------------------------------------------------------------------
 * TOOLER STEP SERVICE (Hardware Sensor Hub + Foreground-Only Live Listener)
 * ---------------------------------------------------------------------------
 * - Reads Android's always-on Hardware Step Counter (Sensor.TYPE_STEP_COUNTER)
 *   without locking a 24/7 foreground service or appearing in Active Apps
 * - While the app UI is visible in foreground, streams real-time step events
 * - When the app moves to background, stops the active listener and relies on
 *   the low-power hardware co-processor + JobScheduler periodic snapshot sync
 * ---------------------------------------------------------------------------
 */
class ToolerStepService : Service(), SensorEventListener {

    companion object {
        const val ACTION_START_TRACKING = "com.tooler.tooler.ACTION_START_STEP_TRACKING"
        const val ACTION_STOP_TRACKING = "com.tooler.tooler.ACTION_STOP_STEP_TRACKING"
        const val ACTION_RESET_DATA = "com.tooler.tooler.ACTION_RESET_STEP_DATA"

        // SharedPreferences Keys (Prefixed with "flutter." for Flutter's shared_preferences)
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val KEY_TODAY_STEPS = "flutter.tooler_steps_today_count_v2"
        const val KEY_DAILY_GOAL = "flutter.tooler_steps_daily_goal_v2"
        const val KEY_ACTIVE_SECONDS = "flutter.tooler_steps_active_seconds_v2"
        const val KEY_LAST_DATE = "flutter.tooler_steps_last_active_date_v2"
        const val KEY_TRAIL_POINTS = "flutter.tooler_steps_today_trail_v2"
        const val KEY_HISTORY = "flutter.tooler_steps_history_records_v2"
        const val KEY_INSTALLED_TIME = "flutter.tooler_steps_installed_time_v2"
        const val KEY_HARDWARE_BASELINE = "flutter.tooler_steps_hw_baseline_v2"
        const val KEY_HAS_BASELINE = "flutter.tooler_steps_has_hw_baseline_v2"
        const val KEY_LAST_HARDWARE_VALUE = "flutter.tooler_steps_last_hw_val_v2"
        const val KEY_VEHICLE_MODE = "flutter.tooler_steps_vehicle_mode_v2"

        // Live in-memory telemetry states
        @Volatile var isServiceRunning: Boolean = false
        @Volatile var liveTodaySteps: Int = 0
        @Volatile var liveActiveSeconds: Int = 0
        @Volatile var isHardwareSynced: Boolean = false
        @Volatile var isWalkingNow: Boolean = false
        @Volatile var isVehicleMode: Boolean = false
        @Volatile var liveSpeedKmh: Double = 0.0
        @Volatile var liveDistanceKm: Double = 0.0
        @Volatile var currentActivity: String = "Stationary"
        @Volatile var hasNavicFix: Boolean = false
        @Volatile var gnssSatellitesCount: Int = 0
        @Volatile var lastLatitude: Double = 0.0
        @Volatile var lastLongitude: Double = 0.0

        var eventSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())
        private var lastPushTimestamp = 0L

        fun pushLiveTelemetry(force: Boolean = false) {
            val now = System.currentTimeMillis()
            if (!force && (now - lastPushTimestamp < 350L)) return
            lastPushTimestamp = now

            mainHandler.post {
                try {
                    val sink = eventSink ?: return@post
                    val data = mapOf(
                        "type" to "step_telemetry",
                        "todaySteps" to liveTodaySteps,
                        "activeSeconds" to liveActiveSeconds,
                        "distanceKm" to liveDistanceKm,
                        "avgSpeedKmh" to liveSpeedKmh,
                        "isHardwareSynced" to isHardwareSynced,
                        "isWalking" to isWalkingNow,
                        "isVehicle" to isVehicleMode,
                        "activity" to currentActivity,
                        "hasNavicFix" to false,
                        "satellites" to 0,
                        "latitude" to lastLatitude,
                        "longitude" to lastLongitude
                    )
                    sink.success(data)
                } catch (_: Throwable) {}
            }
        }

        fun hasActivityPermission(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.ACTIVITY_RECOGNITION
                ) == PackageManager.PERMISSION_GRANTED
            } else true
        }

        fun loadPersistedIntoMemory(context: Context) {
            try {
                val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                liveTodaySteps = p.getInt(KEY_TODAY_STEPS, 0)
                liveActiveSeconds = p.getInt(KEY_ACTIVE_SECONDS, 0)
                liveDistanceKm = String.format(Locale.US, "%.2f", (liveTodaySteps * 0.762) / 1000.0).toDoubleOrNull() ?: 0.0
                recalculateSpeedStatic()
            } catch (_: Throwable) {}
        }

        private fun recalculateSpeedStatic() {
            if (liveActiveSeconds > 10 && liveDistanceKm > 0.01) {
                val hours = liveActiveSeconds / 3600.0
                if (hours > 0) {
                    val rawSpeed = liveDistanceKm / hours
                    liveSpeedKmh = String.format(Locale.US, "%.1f", rawSpeed.coerceIn(1.5, 12.0)).toDoubleOrNull() ?: 4.5
                    return
                }
            }
            liveSpeedKmh = if (isWalkingNow) 4.5 else 0.0
        }

        fun checkDayRolloverStatic(context: Context) {
            val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val lastDateStr = p.getString(KEY_LAST_DATE, null)

            if (lastDateStr != null && lastDateStr != todayStr) {
                if (liveTodaySteps > 0) {
                    try {
                        val rawHist = p.getString(KEY_HISTORY, "[]") ?: "[]"
                        val histArray = JSONArray(rawHist)

                        val yesterdayObj = JSONObject().apply {
                            put("date", "${lastDateStr}T00:00:00.000Z")
                            put("steps", liveTodaySteps)
                            put("distanceKm", liveDistanceKm)
                            put("avgSpeedKmh", if (liveSpeedKmh > 0) liveSpeedKmh else 4.5)
                            put("caloriesKcal", (liveTodaySteps * 0.042).toInt())
                            put("activeMinutes", (liveActiveSeconds / 60))
                        }

                        val updatedArray = JSONArray()
                        updatedArray.put(yesterdayObj)
                        for (i in 0 until histArray.length()) {
                            if (i < 365) updatedArray.put(histArray.getJSONObject(i))
                        }
                        p.edit().putString(KEY_HISTORY, updatedArray.toString()).apply()
                    } catch (_: Throwable) {}
                }

                liveTodaySteps = 0
                liveActiveSeconds = 0
                liveDistanceKm = 0.0
                p.edit()
                    .putInt(KEY_TODAY_STEPS, 0)
                    .putInt(KEY_ACTIVE_SECONDS, 0)
                    .putString(KEY_TRAIL_POINTS, "[]")
                    .putString(KEY_LAST_DATE, todayStr)
                    .remove(KEY_HARDWARE_BASELINE)
                    .putBoolean(KEY_HAS_BASELINE, false)
                    .remove("flutter.tooler_step_goal_notif_date")
                    .putInt("flutter.tooler_last_step_milestone_notified", 0)
                    .apply()

                pushLiveTelemetry(force = true)
            } else if (lastDateStr == null) {
                p.edit().putString(KEY_LAST_DATE, todayStr).apply()
            }
        }

        fun processHardwareStepValue(context: Context, currentHwVal: Int) {
            loadPersistedIntoMemory(context)
            checkDayRolloverStatic(context)

            val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val hasBaseline = p.getBoolean(KEY_HAS_BASELINE, false) || p.contains(KEY_HARDWARE_BASELINE)
            val savedBaseline = p.getInt(KEY_HARDWARE_BASELINE, 0)
            val lastHwVal = p.getInt(KEY_LAST_HARDWARE_VALUE, currentHwVal)

            val newBaseline: Int
            if (!hasBaseline || currentHwVal < lastHwVal) {
                // Initial setup or post-reboot reset: preserve today's steps even if negative baseline is needed
                newBaseline = currentHwVal - liveTodaySteps
                p.edit()
                    .putInt(KEY_HARDWARE_BASELINE, newBaseline)
                    .putBoolean(KEY_HAS_BASELINE, true)
                    .putInt(KEY_LAST_HARDWARE_VALUE, currentHwVal)
                    .apply()
            } else {
                newBaseline = savedBaseline
            }

            val computedSteps = (currentHwVal - newBaseline).coerceAtLeast(0)
            if (computedSteps > liveTodaySteps) {
                val delta = computedSteps - liveTodaySteps
                liveTodaySteps = computedSteps
                liveActiveSeconds += (delta * 0.7).toInt().coerceAtLeast(1)
                liveDistanceKm = String.format(Locale.US, "%.2f", (liveTodaySteps * 0.762) / 1000.0).toDoubleOrNull() ?: 0.0

                isWalkingNow = true
                recalculateSpeedStatic()
                currentActivity = if (liveSpeedKmh > 7.0) "Running" else (if (liveSpeedKmh > 4.5) "Brisk Walk" else "Walking")

                p.edit()
                    .putInt(KEY_TODAY_STEPS, liveTodaySteps)
                    .putInt(KEY_ACTIVE_SECONDS, liveActiveSeconds)
                    .putInt(KEY_LAST_HARDWARE_VALUE, currentHwVal)
                    .apply()

                checkBackgroundStepMilestonesStatic(context, p)
                ToolerStepWidgetProvider.updateAllWidgets(context)
                pushLiveTelemetry()
            } else if (currentHwVal != lastHwVal) {
                p.edit().putInt(KEY_LAST_HARDWARE_VALUE, currentHwVal).apply()
            }
        }

        /**
         * Reads a single batched value from the device's always-on hardware step sensor
         * without starting a foreground service, then immediately unregisters.
         */
        fun syncHardwareSnapshotOnce(context: Context, onComplete: (() -> Unit)? = null) {
            val appCtx = context.applicationContext
            if (!hasActivityPermission(appCtx)) {
                onComplete?.invoke()
                return
            }

            val sm = appCtx.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            val stepSensor = sm?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (sm == null || stepSensor == null) {
                onComplete?.invoke()
                return
            }

            var finished = false
            lateinit var listener: SensorEventListener
            val timeoutRunnable = Runnable {
                if (!finished) {
                    finished = true
                    try { sm.unregisterListener(listener) } catch (_: Throwable) {}
                    onComplete?.invoke()
                }
            }

            listener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent?) {
                    if (finished) return
                    finished = true
                    mainHandler.removeCallbacks(timeoutRunnable)
                    try { sm.unregisterListener(this) } catch (_: Throwable) {}
                    if (event != null && event.sensor.type == Sensor.TYPE_STEP_COUNTER) {
                        isHardwareSynced = true
                        processHardwareStepValue(appCtx, event.values[0].toInt())
                    }
                    onComplete?.invoke()
                }

                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
            }

            try {
                val registered = sm.registerListener(listener, stepSensor, SensorManager.SENSOR_DELAY_NORMAL, 0)
                if (!registered) {
                    onComplete?.invoke()
                    return
                }
                mainHandler.postDelayed(timeoutRunnable, 1200L)
            } catch (_: Throwable) {
                try { sm.unregisterListener(listener) } catch (_: Throwable) {}
                onComplete?.invoke()
            }
        }

        private fun checkBackgroundStepMilestonesStatic(context: Context, p: SharedPreferences) {
            try {
                val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                val goal = p.getInt(KEY_DAILY_GOAL, 10000)

                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val fitnessChannel = NotificationChannel(
                        "tooler_fitness_channel",
                        "Step Counter Goals & Milestones",
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "Daily step goal completions, 1,000-step milestones & 6-hour progress checks"
                        enableVibration(true)
                    }
                    nm.createNotificationChannel(fitnessChannel)
                }

                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java)
                val pi = PendingIntent.getActivity(
                    context,
                    4000,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // 1. Goal Complete Check
                if (liveTodaySteps >= goal && liveTodaySteps > 0) {
                    val lastGoalDate = p.getString("flutter.tooler_step_goal_notif_date", null)
                    if (lastGoalDate != todayStr) {
                        p.edit().putString("flutter.tooler_step_goal_notif_date", todayStr).apply()
                        val calories = (liveTodaySteps * 0.042).toInt()
                        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Notification.Builder(context, "tooler_fitness_channel")
                        } else {
                            @Suppress("DEPRECATION")
                            Notification.Builder(context)
                        }
                        val notif = builder
                            .setSmallIcon(R.drawable.ic_step_notification)
                            .setContentTitle("🏆 Daily Step Goal Achieved! 🎉")
                            .setContentText("Incredible effort! You hit your goal of $goal steps today ($liveDistanceKm km, $calories kcal burned). Keep up the great streak!")
                            .setAutoCancel(true)
                            .setContentIntent(pi)
                            .build()
                        nm.notify(4001, notif)
                    }
                }

                // 2. 1,000 Step Milestone Check
                val lastMilestone = p.getInt("flutter.tooler_last_step_milestone_notified", 0)
                if (liveTodaySteps >= lastMilestone + 1000 && liveTodaySteps >= 1000) {
                    val currentMilestone = (liveTodaySteps / 1000) * 1000
                    if (currentMilestone > lastMilestone) {
                        p.edit().putInt("flutter.tooler_last_step_milestone_notified", currentMilestone).apply()
                        val calories = (liveTodaySteps * 0.042).toInt()
                        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Notification.Builder(context, "tooler_fitness_channel")
                        } else {
                            @Suppress("DEPRECATION")
                            Notification.Builder(context)
                        }
                        val notif = builder
                            .setSmallIcon(R.drawable.ic_step_notification)
                            .setContentTitle("👟 Step Milestone: $currentMilestone Steps!")
                            .setContentText("You've covered $liveDistanceKm km and burned $calories kcal today.")
                            .setAutoCancel(true)
                            .setContentIntent(pi)
                            .build()
                        nm.notify(4002, notif)
                    }
                }

                // 3. Every 6 Hours Periodic Check (8:00 AM to 10:00 PM)
                val nowMs = System.currentTimeMillis()
                val last6HrMs = p.getLong("flutter.tooler_last_step_6hr_notif_time", 0L)
                val cal = java.util.Calendar.getInstance()
                val hour = cal.get(java.util.Calendar.HOUR_OF_DAY)
                if ((nowMs - last6HrMs >= 6 * 3600 * 1000L) && hour in 8..22 && liveTodaySteps > 0) {
                    p.edit().putLong("flutter.tooler_last_step_6hr_notif_time", nowMs).apply()
                    val calories = (liveTodaySteps * 0.042).toInt()
                    val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        Notification.Builder(context, "tooler_fitness_channel")
                    } else {
                        @Suppress("DEPRECATION")
                        Notification.Builder(context)
                    }
                    val notif = builder
                        .setSmallIcon(R.drawable.ic_step_notification)
                        .setContentTitle("🚶 6-Hour Step Progress")
                        .setContentText("Active progress: $liveTodaySteps steps ($liveDistanceKm km · $calories kcal). Stay energized!")
                        .setAutoCancel(true)
                        .setContentIntent(pi)
                        .build()
                    nm.notify(4003, notif)
                }
            } catch (_: Throwable) {}
        }
    }

    private var sensorManager: SensorManager? = null
    private var stepCounterSensor: Sensor? = null
    private var stepDetectorSensor: Sensor? = null
    private var accelSensor: Sensor? = null

    private var prefs: SharedPreferences? = null
    private var lastStepTimestamp: Long = 0L

    private val detectorTimestamps = ArrayList<Long>()
    private var isDetectorCadenceActive = false
    private val REQUIRED_COMMIT_STEPS = 5
    private val MIN_STEP_INTERVAL_MS = 250L
    private val MAX_STEP_INTERVAL_MS = 1400L
    private val CADENCE_TIMEOUT_MS = 2200L

    private var lastAccelStepMs = 0L
    private var isAccelPeakRising = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        try {
            prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager

            initInstallTimestamp()
            loadPersistedIntoMemory(this)
            checkDayRolloverStatic(this)
        } catch (_: Throwable) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val action = intent?.action ?: ACTION_START_TRACKING

            when (action) {
                ACTION_START_TRACKING -> {
                    startLiveForegroundOnlyTracking()
                    ToolerStepSyncJobService.schedule(this)
                }
                ACTION_STOP_TRACKING -> {
                    stopTracking()
                    stopSelf()
                }
                ACTION_RESET_DATA -> {
                    resetAllData()
                }
            }
        } catch (_: Throwable) {}

        return START_NOT_STICKY
    }

    private fun initInstallTimestamp() {
        try {
            val p = prefs ?: return
            if (!p.contains(KEY_INSTALLED_TIME)) {
                val nowStr = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }.format(Date())
                p.edit().putString(KEY_INSTALLED_TIME, nowStr).apply()
            }
        } catch (_: Throwable) {}
    }

    private fun startLiveForegroundOnlyTracking() {
        isServiceRunning = true
        try {
            registerSensors()
        } catch (_: Throwable) {}
        pushLiveTelemetry(force = true)
    }

    private fun stopTracking() {
        isServiceRunning = false
        try {
            sensorManager?.unregisterListener(this)
        } catch (_: Throwable) {}
    }

    private fun registerSensors() {
        val sm = sensorManager ?: return
        try {
            if (!hasActivityPermission(this)) {
                isHardwareSynced = false
                return
            }

            // 1. Hardware Step Counter (Priority #1 — runs in hardware co-processor)
            stepCounterSensor = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (stepCounterSensor != null) {
                val registered = sm.registerListener(this, stepCounterSensor, SensorManager.SENSOR_DELAY_NORMAL)
                if (registered) {
                    isHardwareSynced = true
                    return
                }
            }

            // 2. Hardware Step Detector (Priority #2)
            stepDetectorSensor = sm.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
            if (stepDetectorSensor != null) {
                val registered = sm.registerListener(this, stepDetectorSensor, SensorManager.SENSOR_DELAY_NORMAL)
                if (registered) {
                    isHardwareSynced = true
                    return
                }
            }

            // 3. Accelerometer (Fallback only while UI is open in foreground)
            accelSensor = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            if (accelSensor != null) {
                val registered = sm.registerListener(this, accelSensor, SensorManager.SENSOR_DELAY_NORMAL)
                isHardwareSynced = registered
            } else {
                isHardwareSynced = false
            }
        } catch (_: Throwable) {
            isHardwareSynced = false
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        val now = System.currentTimeMillis()

        try {
            checkDayRolloverStatic(this)

            when (event.sensor.type) {
                Sensor.TYPE_STEP_COUNTER -> {
                    val currentHwVal = event.values[0].toInt()
                    lastStepTimestamp = now
                    processHardwareStepValue(this, currentHwVal)
                }
                Sensor.TYPE_STEP_DETECTOR -> {
                    if (event.values[0] == 1.0f) {
                        handleStepDetectorEvent(now)
                    }
                }
                Sensor.TYPE_ACCELEROMETER -> {
                    if (stepCounterSensor == null && stepDetectorSensor == null) {
                        handleAccelerometerFallback(event.values[0], event.values[1], event.values[2], now)
                    }
                }
            }
        } catch (_: Throwable) {}
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun handleStepDetectorEvent(now: Long) {
        if (detectorTimestamps.isNotEmpty() && (now - detectorTimestamps.last()) > CADENCE_TIMEOUT_MS) {
            detectorTimestamps.clear()
            isDetectorCadenceActive = false
        }

        if (detectorTimestamps.isNotEmpty()) {
            val delta = now - detectorTimestamps.last()
            if (delta < MIN_STEP_INTERVAL_MS) return
            if (delta > MAX_STEP_INTERVAL_MS) {
                detectorTimestamps.clear()
                isDetectorCadenceActive = false
            }
        }

        detectorTimestamps.add(now)

        if (!isDetectorCadenceActive) {
            if (detectorTimestamps.size >= REQUIRED_COMMIT_STEPS) {
                isDetectorCadenceActive = true
                commitBatchSteps(REQUIRED_COMMIT_STEPS)
            }
        } else {
            commitBatchSteps(1)
        }
    }

    private fun handleAccelerometerFallback(x: Float, y: Float, z: Float, now: Long) {
        val mag = sqrt((x * x + y * y + z * z).toDouble())
        val minMag = 11.2
        val minInterval = 280L
        val maxInterval = 1400L

        if (mag > minMag && !isAccelPeakRising && (now - lastAccelStepMs > minInterval)) {
            val delta = now - lastAccelStepMs
            isAccelPeakRising = true
            lastAccelStepMs = now

            if (delta >= minInterval && delta <= maxInterval) {
                commitBatchSteps(1)
            }
        } else if (mag < 9.6) {
            isAccelPeakRising = false
        }
    }

    private fun commitBatchSteps(count: Int) {
        liveTodaySteps += count
        liveActiveSeconds += count
        liveDistanceKm = String.format(Locale.US, "%.2f", (liveTodaySteps * 0.762) / 1000.0).toDoubleOrNull() ?: 0.0
        isWalkingNow = true
        recalculateSpeedStatic()
        currentActivity = if (liveSpeedKmh > 7.0) "Running" else (if (liveSpeedKmh > 4.5) "Brisk Walk" else "Walking")
        lastStepTimestamp = System.currentTimeMillis()

        val p = prefs ?: getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        p.edit()
            .putInt(KEY_TODAY_STEPS, liveTodaySteps)
            .putInt(KEY_ACTIVE_SECONDS, liveActiveSeconds)
            .apply()

        if (liveTodaySteps % 5 == 0 || count > 1) {
            checkBackgroundStepMilestonesStatic(this, p)
            ToolerStepWidgetProvider.updateAllWidgets(this)
        }
        pushLiveTelemetry()
    }

    private fun resetAllData() {
        val p = prefs ?: getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        liveTodaySteps = 0
        liveActiveSeconds = 0
        liveDistanceKm = 0.0
        p.edit()
            .putInt(KEY_TODAY_STEPS, 0)
            .putInt(KEY_ACTIVE_SECONDS, 0)
            .putString(KEY_TRAIL_POINTS, "[]")
            .putString(KEY_HISTORY, "[]")
            .remove(KEY_HARDWARE_BASELINE)
            .putBoolean(KEY_HAS_BASELINE, false)
            .remove(KEY_LAST_HARDWARE_VALUE)
            .apply()
        pushLiveTelemetry(force = true)
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }
}
