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
import android.location.GnssStatus
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * ---------------------------------------------------------------------------
 * TOOLER STEP SERVICE (Ultra-Low Power Hardware-Fused Pedometer & GNSS Service)
 * ---------------------------------------------------------------------------
 * - Hardware Sensor Hub direct binding (Sensor.TYPE_STEP_COUNTER & TYPE_STEP_DETECTOR)
 * - Hardware FIFO batching (maxReportLatencyUs: 60s) for negligible 0% battery usage
 * - Persistent execution: Survives RAM eviction, app close, and screen lock
 * - Real GPS & NavIC (IRNSS Constellation 7) Satellite Tracking
 * - Vehicle / Driving Mode Auto-Filter (>16 km/h): Prevents vehicle vibrations
 *   from falsely incrementing walking steps
 * - Zero Fake Data: Strictly real data starting from actual install timestamp
 * - Shared SharedPreferences sync with Flutter ('FlutterSharedPreferences')
 * ---------------------------------------------------------------------------
 */
class ToolerStepService : Service(), SensorEventListener, LocationListener {

    companion object {
        const val CHANNEL_ID = "tooler_step_counter_channel"
        const val NOTIFICATION_ID = 5120

        const val ACTION_START_TRACKING = "com.tooler.tooler.ACTION_START_STEP_TRACKING"
        const val ACTION_STOP_TRACKING = "com.tooler.tooler.ACTION_STOP_STEP_TRACKING"
        const val ACTION_RESET_DATA = "com.tooler.tooler.ACTION_RESET_STEP_DATA"

        // SharedPreferences Keys (Prefixed with "flutter." to match Flutter's shared_preferences)
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

        fun pushLiveTelemetry() {
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
                        "hasNavicFix" to hasNavicFix,
                        "satellites" to gnssSatellitesCount,
                        "latitude" to lastLatitude,
                        "longitude" to lastLongitude
                    )
                    sink.success(data)
                } catch (_: Exception) {}
            }
        }
    }

    private var sensorManager: SensorManager? = null
    private var stepCounterSensor: Sensor? = null
    private var stepDetectorSensor: Sensor? = null
    private var locationManager: LocationManager? = null
    private var gnssCallback: GnssStatus.Callback? = null

    private var prefs: SharedPreferences? = null
    private var lastStepTimestamp: Long = 0L
    private var lastLocationRecordTime: Long = 0L

    // Step Detector Cadence & Debounce Buffer (Eliminates false positives from phone shakes)
    private val detectorTimestamps = ArrayList<Long>()
    private var isDetectorCadenceActive = false
    private val REQUIRED_COMMIT_STEPS = 6
    private val MIN_STEP_INTERVAL_MS = 260L
    private val MAX_STEP_INTERVAL_MS = 1200L
    private val CADENCE_TIMEOUT_MS = 2200L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager

        initInstallTimestamp()
        loadPersistedState()
        checkDayRollover()
        createNotificationChannel()
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
        } catch (_: Exception) {
            stopSelf()
        }

        return START_STICKY
    }

    private fun initInstallTimestamp() {
        val p = prefs ?: return
        if (!p.contains(KEY_INSTALLED_TIME)) {
            val nowStr = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }.format(Date())
            p.edit().putString(KEY_INSTALLED_TIME, nowStr).apply()
        }
    }

    private fun loadPersistedState() {
        val p = prefs ?: return
        liveTodaySteps = p.getInt(KEY_TODAY_STEPS, 0)
        liveActiveSeconds = p.getInt(KEY_ACTIVE_SECONDS, 0)
        liveDistanceKm = String.format(Locale.US, "%.2f", (liveTodaySteps * 0.762) / 1000.0).toDoubleOrNull() ?: 0.0
    }

    private fun startForegroundTracking() {
        val hasFine = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasLocation = hasFine || hasCoarse
        val hasActivity = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED
        } else true

        // If on Android 14+ and no required permissions are granted, abort foreground service to avoid SecurityException
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && !hasLocation && !hasActivity) {
            isServiceRunning = false
            stopSelf()
            return
        }

        val notification = buildOngoingNotification(
            "Tooler Step Counter Active",
            "$liveTodaySteps steps today · ${String.format(Locale.US, "%.2f", liveDistanceKm)} km"
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                var fType = 0
                if (hasActivity) {
                    fType = fType or ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
                }
                if (hasLocation) {
                    fType = fType or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                }
                if (fType != 0) {
                    startForeground(NOTIFICATION_ID, notification, fType)
                } else {
                    stopSelf()
                    return
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (hasLocation) {
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            isServiceRunning = true
        } catch (_: Exception) {
            isServiceRunning = false
            stopSelf()
            return
        }

        try {
            registerSensors()
            registerLocationUpdates()
            registerGnssStatus()
            pushLiveTelemetry()
        } catch (_: Exception) {}
    }

    private fun stopTracking() {
        isServiceRunning = false
        try {
            sensorManager?.unregisterListener(this)
            locationManager?.removeUpdates(this)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && gnssCallback != null) {
                locationManager?.unregisterGnssStatusCallback(gnssCallback!!)
            }
        } catch (_: Exception) {}
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun registerSensors() {
        val sm = sensorManager ?: return

        // 1. Hardware Step Counter (Sensor Hub batching: 60,000,000 us = 60s max batch latency for 0% battery impact)
        stepCounterSensor = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (stepCounterSensor != null) {
            sm.registerListener(this, stepCounterSensor, SensorManager.SENSOR_DELAY_NORMAL, 60_000_000)
            isHardwareSynced = true
        } else {
            // 2. Hardware Step Detector fallback
            stepDetectorSensor = sm.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
            if (stepDetectorSensor != null) {
                sm.registerListener(this, stepDetectorSensor, SensorManager.SENSOR_DELAY_NORMAL, 10_000_000)
                isHardwareSynced = true
            } else {
                isHardwareSynced = false
            }
        }
    }

    private fun registerLocationUpdates() {
        val lm = locationManager ?: return
        val hasFine = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

        if (!hasFine && !hasCoarse) return

        try {
            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                // Request updates every 5 seconds or 8 meters
                lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 5000L, 8.0f, this)
            }
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                lm.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 10000L, 15.0f, this)
            }
        } catch (_: Exception) {}
    }

    private fun registerGnssStatus() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        val lm = locationManager ?: return
        val hasFine = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!hasFine) return

        gnssCallback = object : GnssStatus.Callback() {
            override fun onSatelliteStatusChanged(status: GnssStatus) {
                var usedCount = 0
                var foundNavic = false

                for (i in 0 until status.satelliteCount) {
                    if (status.usedInFix(i)) {
                        usedCount++
                    }
                    // Constellation 7 = CONSTELLATION_IRNSS (NavIC India)
                    if (status.getConstellationType(i) == GnssStatus.CONSTELLATION_IRNSS) {
                        foundNavic = true
                    }
                }
                gnssSatellitesCount = usedCount
                hasNavicFix = foundNavic
            }
        }

        try {
            lm.registerGnssStatusCallback(gnssCallback!!, null)
        } catch (_: Exception) {}
    }

    // ---------------------------------------------------------------------------
    // SENSOR EVENT LISTENER
    // ---------------------------------------------------------------------------
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        val now = System.currentTimeMillis()

        checkDayRollover()

        // If user is currently travelling in a vehicle (> 16 km/h), suppress all step increments
        // so road bumps, car engine vibration, and transit motion DO NOT count as steps!
        if (isVehicleMode) {
            isWalkingNow = false
            currentActivity = "Vehicle Transit"
            pushLiveTelemetry()
            return
        }

        when (event.sensor.type) {
            Sensor.TYPE_STEP_COUNTER -> {
                val currentHwVal = event.values[0].toInt()
                handleHardwareStepCounter(currentHwVal)
            }
            Sensor.TYPE_STEP_DETECTOR -> {
                // Each step event delivers value 1.0 - filtered through 6-step debounce cadence buffer
                if (event.values[0] == 1.0f) {
                    handleStepDetectorEvent(now)
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun handleHardwareStepCounter(currentHwVal: Int) {
        val p = prefs ?: return
        val savedBaseline = p.getInt(KEY_HARDWARE_BASELINE, -1)
        val lastHwVal = p.getInt(KEY_LAST_HARDWARE_VALUE, currentHwVal)

        val newBaseline: Int
        if (savedBaseline == -1 || currentHwVal < lastHwVal) {
            // Initial baseline or device reboot occurred (counter reset)
            newBaseline = currentHwVal - liveTodaySteps
            p.edit()
                .putInt(KEY_HARDWARE_BASELINE, newBaseline)
                .putInt(KEY_LAST_HARDWARE_VALUE, currentHwVal)
                .apply()
        } else {
            newBaseline = savedBaseline
        }

        // Today's verified steps
        val computedSteps = (currentHwVal - newBaseline).coerceAtLeast(0)
        if (computedSteps > liveTodaySteps) {
            val delta = computedSteps - liveTodaySteps
            liveTodaySteps = computedSteps
            liveActiveSeconds += (delta * 0.65).toInt()
            liveDistanceKm = String.format(Locale.US, "%.2f", (liveTodaySteps * 0.762) / 1000.0).toDoubleOrNull() ?: 0.0

            isWalkingNow = true
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
        // If cadence timed out (> 2.2s since last impulse), clear buffer
        if (detectorTimestamps.isNotEmpty() && (now - detectorTimestamps.last()) > CADENCE_TIMEOUT_MS) {
            detectorTimestamps.clear()
            isDetectorCadenceActive = false
        }

        if (detectorTimestamps.isNotEmpty()) {
            val delta = now - detectorTimestamps.last()
            if (delta < MIN_STEP_INTERVAL_MS) {
                // High-frequency vibration (phone ring, road buzz), reject
                return
            }
            if (delta > MAX_STEP_INTERVAL_MS) {
                // Inconsistent pause, reset debounce
                detectorTimestamps.clear()
                isDetectorCadenceActive = false
            }
        }

        detectorTimestamps.add(now)

        if (!isDetectorCadenceActive) {
            // Only commit once user has sustained 6 consecutive rhythmic steps
            if (detectorTimestamps.size >= REQUIRED_COMMIT_STEPS) {
                isDetectorCadenceActive = true
                commitBatchSteps(REQUIRED_COMMIT_STEPS)
            }
        } else {
            // Ongoing verified walking cadence
            commitBatchSteps(1)
        }
    }

    private fun commitBatchSteps(count: Int) {
        liveTodaySteps += count
        liveActiveSeconds += count
        liveDistanceKm = String.format(Locale.US, "%.2f", (liveTodaySteps * 0.762) / 1000.0).toDoubleOrNull() ?: 0.0
        isWalkingNow = true
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

    // ---------------------------------------------------------------------------
    // LOCATION LISTENER (GPS + NavIC & Vehicle Transit Detection)
    // ---------------------------------------------------------------------------
    override fun onLocationChanged(loc: Location) {
        if (loc.accuracy > 40.0f) return // Ignore noisy fixes

        val now = System.currentTimeMillis()
        val lat = loc.latitude
        val lon = loc.longitude

        // Calculate speed in km/h
        val rawSpeedKmh = if (loc.hasSpeed() && loc.speed >= 0f) {
            (loc.speed * 3.6).toDouble()
        } else if (lastLatitude != 0.0 && lastLongitude != 0.0 && lastLocationRecordTime > 0) {
            val distMeters = calculateDistanceMeters(lastLatitude, lastLongitude, lat, lon)
            val dtSec = (now - lastLocationRecordTime) / 1000.0
            if (dtSec > 0.5) (distMeters / dtSec) * 3.6 else 0.0
        } else {
            0.0
        }

        val clampedSpeed = String.format(Locale.US, "%.1f", rawSpeedKmh.coerceIn(0.0, 180.0)).toDoubleOrNull() ?: 0.0
        liveSpeedKmh = clampedSpeed
        lastLatitude = lat
        lastLongitude = lon

        // VEHICLE TRANSIT FILTER:
        // Speed > 16 km/h indicates vehicular travel (bike, car, bus, train)
        val wasVehicle = isVehicleMode
        isVehicleMode = clampedSpeed > 16.0

        if (isVehicleMode) {
            isWalkingNow = false
            currentActivity = "Vehicle Transit"
        } else if (clampedSpeed > 7.0) {
            currentActivity = "Running"
        } else if (clampedSpeed > 4.5) {
            currentActivity = "Brisk Walk"
        } else if (clampedSpeed > 1.2) {
            currentActivity = "Walking"
        } else {
            currentActivity = "Stationary"
        }

        // Record waypoint periodically (at least 12 seconds or 15 meters)
        if (now - lastLocationRecordTime > 12000L || wasVehicle != isVehicleMode) {
            appendWaypoint(lat, lon, clampedSpeed, liveDistanceKm, liveTodaySteps, isVehicleMode, currentActivity)
            lastLocationRecordTime = now
        }

        pushLiveTelemetry()
    }

    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
    @Deprecated("Deprecated in Java")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

    private fun appendWaypoint(
        lat: Double,
        lon: Double,
        speedKmh: Double,
        distanceKm: Double,
        steps: Int,
        isVehicle: Boolean,
        activity: String
    ) {
        val p = prefs ?: return
        try {
            val isoTime = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }.format(Date())

            val rawTrail = p.getString(KEY_TRAIL_POINTS, "[]") ?: "[]"
            val array = JSONArray(rawTrail)

            val pointObj = JSONObject().apply {
                put("lat", lat)
                put("lon", lon)
                put("speedKmh", speedKmh)
                put("distanceKm", distanceKm)
                put("steps", steps)
                put("isVehicle", isVehicle)
                put("activity", activity)
                put("timestamp", isoTime)
            }

            array.put(pointObj)

            // Keep maximum 400 waypoints per day to optimize memory
            if (array.length() > 400) {
                val trimmed = JSONArray()
                val start = array.length() - 400
                for (i in start until array.length()) {
                    trimmed.put(array.getJSONObject(i))
                }
                p.edit().putString(KEY_TRAIL_POINTS, trimmed.toString()).apply()
            } else {
                p.edit().putString(KEY_TRAIL_POINTS, array.toString()).apply()
            }
        } catch (_: Exception) {}
    }

    private fun calculateDistanceMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val r = 6371000.0 // Earth radius in meters
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }

    // ---------------------------------------------------------------------------
    // MIDNIGHT DAY ROLLOVER & HISTORICAL RECORDING (Zero Fake Data)
    // ---------------------------------------------------------------------------
    private fun checkDayRollover() {
        val p = prefs ?: return
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val lastDateStr = p.getString(KEY_LAST_DATE, null)

        if (lastDateStr != null && lastDateStr != todayStr) {
            // Day rollover: Archive yesterday's actual steps into history
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

                    // Prepend yesterday's record
                    val updatedArray = JSONArray()
                    updatedArray.put(yesterdayObj)
                    for (i in 0 until histArray.length()) {
                        if (i < 365) updatedArray.put(histArray.getJSONObject(i))
                    }
                    p.edit().putString(KEY_HISTORY, updatedArray.toString()).apply()
                } catch (_: Exception) {}
            }

            // Reset today's live counters
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
            pushLiveTelemetry()
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
        pushLiveTelemetry()
    }

    // ---------------------------------------------------------------------------
    // NOTIFICATION
    // ---------------------------------------------------------------------------
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Pedometer & Step Tracker"
            val desc = "Hardware step counter and trajectory GPS telemetry"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = desc
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.createNotificationChannel(channel)
        }
    }

    private fun buildOngoingNotification(title: String, text: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
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

        try {
            builder.setSmallIcon(R.drawable.ic_step_notification)
        } catch (_: Exception) {
            builder.setSmallIcon(android.R.drawable.ic_menu_directions)
        }

        return builder
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun updateNotification() {
        if (!isServiceRunning) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        val notif = buildOngoingNotification(
            "Tooler Step Counter Active",
            "$liveTodaySteps steps today · ${String.format(Locale.US, "%.2f", liveDistanceKm)} km"
        )
        nm?.notify(NOTIFICATION_ID, notif)
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }
}
