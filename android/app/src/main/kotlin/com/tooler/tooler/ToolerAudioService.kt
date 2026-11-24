package com.tooler.tooler

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import kotlin.concurrent.thread

class ToolerAudioService : Service() {

    companion object {
        const val CHANNEL_ID = "tooler_audio_foreground_channel"
        const val NOTIFICATION_ID = 4109

        const val ACTION_START_RECORDING_KEEPALIVE = "com.tooler.tooler.ACTION_START_RECORDING"
        const val ACTION_STOP_RECORDING_KEEPALIVE = "com.tooler.tooler.ACTION_STOP_RECORDING"
        const val ACTION_START_LOOPBACK = "com.tooler.tooler.ACTION_START_LOOPBACK"
        const val ACTION_UPDATE_LOOPBACK = "com.tooler.tooler.ACTION_UPDATE_LOOPBACK"
        const val ACTION_STOP_LOOPBACK = "com.tooler.tooler.ACTION_STOP_LOOPBACK"
        const val ACTION_STOP_ALL = "com.tooler.tooler.ACTION_STOP_ALL"

        const val EXTRA_CAPTURE_SOURCE = "captureSource" // "phone" or "earphone"
        const val EXTRA_LISTEN_OUTPUT = "listenOutput"   // "earphone" or "phone"
        const val EXTRA_GAIN = "gain"

        @Volatile var isRecordingKeepAlive: Boolean = false
        @Volatile var isLoopbackRunning: Boolean = false
        @Volatile var currentCaptureSource: String = "phone"
        @Volatile var currentListenOutput: String = "earphone"
        @Volatile var monitorGain: Float = 2.5f
        @Volatile var liveDb: Double = 36.0
        @Volatile var liveAmp: Double = 0.12
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var echoCanceler: AcousticEchoCanceler? = null
    private var noiseSuppressor: NoiseSuppressor? = null
    private var loopbackThread: Thread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ""

        when (action) {
            ACTION_START_RECORDING_KEEPALIVE -> {
                isRecordingKeepAlive = true
                promoteToForeground()
                acquireWakeLock()
            }
            ACTION_STOP_RECORDING_KEEPALIVE -> {
                isRecordingKeepAlive = false
                if (!isLoopbackRunning) {
                    shutdownService()
                    return START_NOT_STICKY
                } else {
                    updateNotification()
                }
            }
            ACTION_START_LOOPBACK, ACTION_UPDATE_LOOPBACK -> {
                val cap = intent?.getStringExtra(EXTRA_CAPTURE_SOURCE) ?: currentCaptureSource
                val out = intent?.getStringExtra(EXTRA_LISTEN_OUTPUT) ?: currentListenOutput
                val gain = intent?.getFloatExtra(EXTRA_GAIN, monitorGain) ?: monitorGain
                currentCaptureSource = cap
                currentListenOutput = out
                monitorGain = gain

                promoteToForeground()
                acquireWakeLock()
                startNativeLoopback(cap, out)
                updateNotification()
            }
            ACTION_STOP_LOOPBACK -> {
                stopNativeLoopback()
                if (!isRecordingKeepAlive) {
                    shutdownService()
                    return START_NOT_STICKY
                } else {
                    updateNotification()
                }
            }
            ACTION_STOP_ALL -> {
                isRecordingKeepAlive = false
                stopNativeLoopback()
                shutdownService()
                return START_NOT_STICKY
            }
            else -> {
                if (isRecordingKeepAlive || isLoopbackRunning) {
                    promoteToForeground()
                    acquireWakeLock()
                }
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        stopNativeLoopback()
        isRecordingKeepAlive = false
        releaseWakeLock()
        super.onDestroy()
    }

    private fun shutdownService() {
        releaseWakeLock()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {}
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Tooler Active Audio",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps Tooler voice recording and live audio monitor active in background"
                setSound(null, null)
                enableVibration(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingOpen = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = when {
            isRecordingKeepAlive && isLoopbackRunning -> "Tooler Audio Active (Recording + Monitor)"
            isRecordingKeepAlive -> "Tooler Sound Recorder Active"
            isLoopbackRunning -> "Tooler Live Audio Monitor Active"
            else -> "Tooler Audio Service"
        }

        val routeDesc = if (isLoopbackRunning) {
            val inLabel = if (currentCaptureSource == "earphone") "Earphone Mic" else "Phone Mic"
            val outLabel = if (currentListenOutput == "phone") "Phone Speaker" else "Earphone"
            "$inLabel → $outLabel"
        } else {
            "Running in background"
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle(title)
            .setContentText(routeDesc)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setContentIntent(pendingOpen)
            .build()
    }

    private fun promoteToForeground() {
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (_: Exception) {}
        }
    }

    private fun updateNotification() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification())
        } catch (_: Exception) {}
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Tooler::AudioServiceWakeLock")
                wakeLock?.setReferenceCounted(false)
            }
            if (wakeLock?.isHeld == false) {
                wakeLock?.acquire(12 * 60 * 60 * 1000L) // up to 12 hours safety cap
            }
        } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
    }

    private fun findInputDevice(audioManager: AudioManager, captureSource: String): AudioDeviceInfo? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
        val inputs = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
        return if (captureSource == "earphone") {
            inputs.firstOrNull {
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && it.type == AudioDeviceInfo.TYPE_BLE_HEADSET)
            } ?: inputs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_MIC }
        } else {
            inputs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_MIC }
        }
    }

    private fun findOutputDevice(audioManager: AudioManager, listenOutput: String): AudioDeviceInfo? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
        val outputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        return if (listenOutput == "phone") {
            outputs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
        } else {
            outputs.firstOrNull {
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                it.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && it.type == AudioDeviceInfo.TYPE_BLE_HEADSET)
            } ?: outputs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
        }
    }

    private fun startNativeLoopback(captureSource: String, listenOutput: String) {
        stopNativeLoopback()

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        try {
            val inputDev = findInputDevice(audioManager, captureSource)
            val isBtScoInput = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && inputDev != null && (
                inputDev.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && inputDev.type == AudioDeviceInfo.TYPE_BLE_HEADSET)
            )

            if (isBtScoInput) {
                try {
                    audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val commDevices = audioManager.availableCommunicationDevices
                        val btDev = commDevices.firstOrNull {
                            it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                            it.type == AudioDeviceInfo.TYPE_BLE_HEADSET
                        }
                        if (btDev != null) {
                            audioManager.setCommunicationDevice(btDev)
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        audioManager.startBluetoothSco()
                        @Suppress("DEPRECATION")
                        audioManager.isBluetoothScoOn = true
                    }
                } catch (_: Exception) {}
            } else {
                try {
                    audioManager.mode = AudioManager.MODE_NORMAL
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        audioManager.clearCommunicationDevice()
                    } else {
                        @Suppress("DEPRECATION")
                        audioManager.stopBluetoothSco()
                        @Suppress("DEPRECATION")
                        audioManager.isBluetoothScoOn = false
                    }
                } catch (_: Exception) {}
            }

            // Route phone speaker output: VOICE_COMMUNICATION usage + MODE_IN_COMMUNICATION
            // forces Android to play through BUILTIN_SPEAKER even when earphone is connected.
            // For earphone output: stay in NORMAL mode so USAGE_MEDIA routes through A2DP/wired naturally.
            if (listenOutput == "phone") {
                try {
                    audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val speakerDev = audioManager.availableCommunicationDevices.firstOrNull {
                            it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
                        }
                        if (speakerDev != null) {
                            audioManager.setCommunicationDevice(speakerDev)
                        } else {
                            @Suppress("DEPRECATION")
                            audioManager.isSpeakerphoneOn = true
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        audioManager.isSpeakerphoneOn = true
                    }
                } catch (_: Exception) {}
            } else {
                try {
                    @Suppress("DEPRECATION")
                    audioManager.isSpeakerphoneOn = false
                } catch (_: Exception) {}
            }

            val channelConfigIn = AudioFormat.CHANNEL_IN_MONO
            val channelConfigOut = AudioFormat.CHANNEL_OUT_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT

            // UNPROCESSED = raw mic hardware signal with zero Android processing (no AGC/NS/AEC).
            // This gives full sensitivity so quiet sounds are captured at real volume.
            // BT SCO still needs VOICE_COMMUNICATION which manages the SCO link.
            val audioSource = when {
                isBtScoInput -> MediaRecorder.AudioSource.VOICE_COMMUNICATION
                captureSource == "phone" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N ->
                    MediaRecorder.AudioSource.UNPROCESSED
                else -> MediaRecorder.AudioSource.MIC
            }

            // Safe multi-sample rate fallback
            val sampleRatesToTry = if (isBtScoInput) intArrayOf(16000, 8000) else intArrayOf(44100, 48000, 16000)
            var selectedSampleRate = sampleRatesToTry[0]
            var rec: AudioRecord? = null
            var bufferSize = 4096

            for (sr in sampleRatesToTry) {
                val minBufIn = AudioRecord.getMinBufferSize(sr, channelConfigIn, audioFormat)
                val minBufOut = AudioTrack.getMinBufferSize(sr, channelConfigOut, audioFormat)
                if (minBufIn > 0 && minBufOut > 0) {
                    bufferSize = Math.max(minBufIn, minBufOut).coerceAtLeast(2048) * 2
                    val candidate = try {
                        AudioRecord(audioSource, sr, channelConfigIn, audioFormat, bufferSize)
                    } catch (_: Exception) { null }
                    if (candidate != null && candidate.state == AudioRecord.STATE_INITIALIZED) {
                        rec = candidate
                        selectedSampleRate = sr
                        break
                    } else {
                        candidate?.release()
                    }
                }
            }

            if (rec == null || rec.state != AudioRecord.STATE_INITIALIZED) {
                rec?.release()
                return
            }

            val track = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // VOICE_COMMUNICATION usage keeps audio on BUILTIN_SPEAKER (via MODE_IN_COMMUNICATION).
                // MEDIA usage lets Android route to earphone/A2DP naturally.
                val usage = if (listenOutput == "phone") AudioAttributes.USAGE_VOICE_COMMUNICATION
                            else AudioAttributes.USAGE_MEDIA
                AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(usage)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(audioFormat)
                            .setSampleRate(selectedSampleRate)
                            .setChannelMask(channelConfigOut)
                            .build()
                    )
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()
            } else {
                val streamType = if (listenOutput == "phone") AudioManager.STREAM_VOICE_CALL else AudioManager.STREAM_MUSIC
                @Suppress("DEPRECATION")
                AudioTrack(streamType, selectedSampleRate, channelConfigOut, audioFormat, bufferSize, AudioTrack.MODE_STREAM)
            }

            // Explicit Hardware Device Routing (API 23+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                inputDev?.let { dev ->
                    rec.preferredDevice = dev
                }
                findOutputDevice(audioManager, listenOutput)?.let { dev ->
                    track.preferredDevice = dev
                }
            }

            // AEC & NS only help for Bluetooth SCO (VOICE_COMMUNICATION source).
            // For raw UNPROCESSED/MIC phone capture these effects crush quiet sounds — keep disabled.
            if (isBtScoInput) {
                try {
                    if (AcousticEchoCanceler.isAvailable()) {
                        echoCanceler = AcousticEchoCanceler.create(rec.audioSessionId)?.apply {
                            enabled = true
                        }
                    }
                    if (NoiseSuppressor.isAvailable()) {
                        noiseSuppressor = NoiseSuppressor.create(rec.audioSessionId)?.apply {
                            enabled = true
                        }
                    }
                } catch (_: Exception) {}
            }

            audioRecord = rec
            audioTrack = track

            track.play()
            rec.startRecording()
            isLoopbackRunning = true

            loopbackThread = thread(start = true, priority = Thread.MAX_PRIORITY, name = "ToolerAudioLoopback") {
                // Snappy 512-sample chunk (~11.6ms @ 44.1kHz) for ultra-low latency live listen
                val chunkShorts = 512
                val audioBuffer = ShortArray(chunkShorts)
                var consecutiveErrors = 0

                while (isLoopbackRunning && audioRecord != null && audioTrack != null) {
                    val readCount = try {
                        audioRecord?.read(audioBuffer, 0, audioBuffer.size) ?: 0
                    } catch (_: Exception) {
                        -1
                    }
                    if (readCount > 0) {
                        consecutiveErrors = 0
                        var sumSq = 0.0
                        var peak = 0
                        val gain = monitorGain
                        for (i in 0 until readCount) {
                            val raw = audioBuffer[i].toInt()
                            val absVal = if (raw < 0) -raw else raw
                            if (absVal > peak) peak = absVal
                            sumSq += raw.toDouble() * raw.toDouble()
                            if (gain != 1.0f) {
                                val amplified = (raw * gain).toInt()
                                audioBuffer[i] = Math.max(-32768, Math.min(32767, amplified)).toShort()
                            }
                        }
                        // Compute real live dB SPL & amplitude for the Decibel Gauge so it never freezes
                        val rms = Math.sqrt(sumSq / readCount)
                        val dbFs = 20.0 * Math.log10(if (rms > 1.0) rms / 32767.0 else 0.00003)
                        val spl = (98.0 + dbFs).coerceIn(28.0, 115.0)
                        liveDb = (liveDb * 0.45) + (spl * 0.55)
                        // Perceptual power curve for responsive waveform
                        val normFrac = (peak.toDouble() / 32768.0).coerceIn(0.0, 1.0)
                        liveAmp = Math.pow(normFrac, 0.35).coerceIn(0.08, 1.0)

                        try {
                            audioTrack?.write(audioBuffer, 0, readCount)
                        } catch (_: Exception) {}
                    } else if (readCount < 0) {
                        consecutiveErrors++
                        if (consecutiveErrors > 15) {
                            break
                        }
                        try { Thread.sleep(20) } catch (_: Exception) {}
                    } else {
                        try { Thread.sleep(5) } catch (_: Exception) {}
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopNativeLoopback()
        }
    }

    private fun stopNativeLoopback() {
        isLoopbackRunning = false
        try {
            echoCanceler?.release()
        } catch (_: Exception) {}
        echoCanceler = null

        try {
            noiseSuppressor?.release()
        } catch (_: Exception) {}
        noiseSuppressor = null

        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (_: Exception) {}
        audioRecord = null

        try {
            audioTrack?.stop()
            audioTrack?.release()
        } catch (_: Exception) {}
        audioTrack = null

        loopbackThread = null

        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.isSpeakerphoneOn = false
            audioManager.mode = AudioManager.MODE_NORMAL
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                audioManager.clearCommunicationDevice()
            } else {
                @Suppress("DEPRECATION")
                audioManager.stopBluetoothSco()
                @Suppress("DEPRECATION")
                audioManager.isBluetoothScoOn = false
            }
        } catch (_: Exception) {}
    }
}
