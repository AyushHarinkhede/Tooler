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
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
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
 * TOOLER STEP SERVICE (Ultra-Safe Hardware Pedometer Service)
 * ---------------------------------------------------------------------------
 * - Direct Hardware Step Counter (Sensor.TYPE_STEP_COUNTER) with reboot recovery
 * - Hardware Step Detector (Sensor.TYPE_STEP_DETECTOR) with cadence debounce
 * - Accelerometer (Sensor.TYPE_ACCELEROMETER) safe fallback
 * - 0% Background battery drain: strictly hardware sensor driven (Zero GPS drain)
 * - Android 14 (API 34) Foreground Service Health compliance with full crash-safety
 * - Synchronized with Flutter SharedPreferences
 * ---------------------------------------------------------------------------
 */
class ToolerStepService : Service(), SensorEventListener {

    companion object {
        const val CHANNEL_ID = "tooler_step_counter_channel"
        const val NOTIFICATION_ID = 5120

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

        // Active Event Sink for real-time Flutter push
        var eventSink: EventChannel.EventSink? = null
        private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
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
    }

    private var sensorManager: SensorManager? = null
    private var stepCounterSensor: Sensor? = null
    private var stepDetectorSensor: Sensor? = null
    private var accelSensor: Sensor? = null

    private var prefs: SharedPreferences? = null
    private var lastStepTimestamp: Long = 0L

    // Step Detector Cadence & Debounce Buffer
    private val detectorTimestamps = ArrayList<Long>()
    private var isDetectorCadenceActive = false
    private val REQUIRED_COMMIT_STEPS = 5
    private val MIN_STEP_INTERVAL_MS = 250L
    private val MAX_STEP_INTERVAL_MS = 1400L
    private val CADENCE_TIMEOUT_MS = 2200L

    // Accelerometer fallback filter
    private var lastAccelStepMs = 0L
    private var isAccelPeakRising = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        try {
            prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager

            initInstallTimestamp()
            loadPersistedState()
            checkDayRollover()
            createNotificationChannel()
        } catch (_: Throwable) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val action = intent?.action ?: ACTION_START_TRACKING

            when (action) {
                ACTION_START_TRACKING -> {
                    startForegroundTracking()
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

        return START_STICKY
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

    private fun loadPersistedState() {
        try {
            val p = prefs ?: return
            liveTodaySteps = p.getInt(KEY_TODAY_STEPS, 0)
            liveActiveSeconds = p.getInt(KEY_ACTIVE_SECONDS, 0)
            liveDistanceKm = String.format(Locale.US, "%.2f", (liveTodaySteps * 0.762) / 1000.0).toDoubleOrNull() ?: 0.0
            recalculateSpeed()
        } catch (_: Throwable) {}
    }

    private fun recalculateSpeed() {
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

    private fun startForegroundTracking() {
        isServiceRunning = true

        try {
            registerSensors()
        } catch (_: Throwable) {}

        pushLiveTelemetry(force = true)

        val hasActivity = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED
        } else true

        if (!hasActivity) {
            return
        }

        try {
            val notification = buildOngoingNotification(
                "Tooler Step Counter Active",
                "$liveTodaySteps steps today · ${String.format(Locale.US, "%.2f", liveDistanceKm)} km"
            ) ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Throwable) {
            // Never crash if foreground service cannot start - remain running safely as background service
        }
    }

    private fun stopTracking() {
        isServiceRunning = false
        try {
            sensorManager?.unregisterListener(this)
        } catch (_: Throwable) {}
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } catch (_: Throwable) {}
    }

    private fun registerSensors() {
        val sm = sensorManager ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val hasPerm = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED
                if (!hasPerm) {
                    isHardwareSynced = false
                    return
                }
            }

            // 1. Hardware Step Counter (Priority #1)
            stepCounterSensor = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (stepCounterSensor != null) {
                val registered = sm.registerListener(this, stepCounterSensor, SensorManager.SENSOR_DELAY_UI)
                if (registered) {
                    isHardwareSynced = true
                    return
                }
            }

            // 2. Hardware Step Detector (Priority #2)
            stepDetectorSensor = sm.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
            if (stepDetectorSensor != null) {
                val registered = sm.registerListener(this, stepDetectorSensor, SensorManager.SENSOR_DELAY_UI)
                if (registered) {
                    isHardwareSynced = true
                    return
                }
            }

            // 3. Accelerometer (Fallback on older hardware)
            accelSensor = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            if (accelSensor != null) {
                val registered = sm.registerListener(this, accelSensor, SensorManager.SENSOR_DELAY_UI)
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
            checkDayRollover()

            when (event.sensor.type) {
                Sensor.TYPE_STEP_COUNTER -> {
                    val currentHwVal = event.values[0].toInt()
                    handleHardwareStepCounter(currentHwVal)
                }
                Sensor.TYPE_STEP_DETECTOR -> {
                    if (event.values[0] == 1.0f) {
                        handleStepDetectorEvent(now)
                    }
                }
                Sensor.TYPE_ACCELEROMETER -> {
                    // Only process accelerometer if hardware step counter & detector are absent
                    if (stepCounterSensor == null && stepDetectorSensor == null) {
                        handleAccelerometerFallback(event.values[0], event.values[1], event.values[2], now)
                    }
                }
            }
        } catch (_: Throwable) {}
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun handleHardwareStepCounter(currentHwVal: Int) {
        val p = prefs ?: return
        val savedBaseline = p.getInt(KEY_HARDWARE_BASELINE, -1)
        val lastHwVal = p.getInt(KEY_LAST_HARDWARE_VALUE, currentHwVal)

        val newBaseline: Int
        if (savedBaseline == -1 || currentHwVal < lastHwVal) {
            // Initial baseline or phone reboot reset
            newBaseline = (currentHwVal - liveTodaySteps).coerceAtLeast(0)
            p.edit()
                .putInt(KEY_HARDWARE_BASELINE, newBaseline)
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
            recalculateSpeed()
            currentActivity = if (liveSpeedKmh > 7.0) "Running" else (if (liveSpeedKmh > 4.5) "Brisk Walk" else "Walking")
            lastStepTimestamp = System.currentTimeMillis()

            p.edit()
                .putInt(KEY_TODAY_STEPS, liveTodaySteps)
                .putInt(KEY_ACTIVE_SECONDS, liveActiveSeconds)
                .putInt(KEY_LAST_HARDWARE_VALUE, currentHwVal)
                .apply()

            updateNotification()
            pushLiveTelemetry()
        }
    }

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
        val minMag = 11.2 // Heel-strike acceleration threshold (m/s² with gravity)
        val minInterval = 280L // ~3.5 steps/sec max
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
        recalculateSpeed()
        currentActivity = if (liveSpeedKmh > 7.0) "Running" else (if (liveSpeedKmh > 4.5) "Brisk Walk" else "Walking")
        lastStepTimestamp = System.currentTimeMillis()

        prefs?.edit()
            ?.putInt(KEY_TODAY_STEPS, liveTodaySteps)
            ?.putInt(KEY_ACTIVE_SECONDS, liveActiveSeconds)
            ?.apply()

        if (liveTodaySteps % 5 == 0 || count > 1) {
            updateNotification()
        }
        pushLiveTelemetry()
    }

    private fun checkDayRollover() {
        val p = prefs ?: return
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
                .apply()

            updateNotification()
            pushLiveTelemetry(force = true)
        } else if (lastDateStr == null) {
            p.edit().putString(KEY_LAST_DATE, todayStr).apply()
        }
    }

    private fun resetAllData() {
        val p = prefs ?: return
        liveTodaySteps = 0
        liveActiveSeconds = 0
        liveDistanceKm = 0.0
        p.edit()
            .putInt(KEY_TODAY_STEPS, 0)
            .putInt(KEY_ACTIVE_SECONDS, 0)
            .putString(KEY_TRAIL_POINTS, "[]")
            .putString(KEY_HISTORY, "[]")
            .remove(KEY_HARDWARE_BASELINE)
            .remove(KEY_LAST_HARDWARE_VALUE)
            .apply()
        updateNotification()
        pushLiveTelemetry(force = true)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val name = "Pedometer & Step Tracker"
                val desc = "Hardware step counter active tracking"
                val importance = NotificationManager.IMPORTANCE_LOW
                val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                    description = desc
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                }
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.createNotificationChannel(channel)
            } catch (_: Throwable) {}
        }
    }

    private fun buildOngoingNotification(title: String, text: String): Notification? {
        return try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            builder.setSmallIcon(android.R.drawable.ic_menu_directions)
                .setContentTitle(title)
                .setContentText(text)
                .setOngoing(true)
                .setAutoCancel(false)
                .setContentIntent(pendingIntent)
                .build()
        } catch (_: Throwable) {
            null
        }
    }

    private fun updateNotification() {
        if (!isServiceRunning) return
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            val notif = buildOngoingNotification(
                "Tooler Step Counter Active",
                "$liveTodaySteps steps today · ${String.format(Locale.US, "%.2f", liveDistanceKm)} km"
            ) ?: return
            nm?.notify(NOTIFICATION_ID, notif)
        } catch (_: Throwable) {}
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }
}
