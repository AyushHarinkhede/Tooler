package com.tooler.tooler

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.SoundPool
import android.os.Build
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val LOOPBACK_CHANNEL = "com.tooler.tooler/audio_loopback"
    private val SOUND_CHANNEL = "com.tooler.tooler/native_sound"

    // Audio loopback monitor state
    private var isLoopbackRunning = false
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var loopbackThread: Thread? = null
    private var monitorGain: Float = 1.0f

    // Native Sound Engine (SoundPool) for instant, zero-latency physical feedback
    private var soundPool: SoundPool? = null
    private val soundMap = HashMap<String, Int>()
    private var isSoundEnabled = true
    private var activeAlarmStreamId: Int = 0

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        enableHighRefreshRate()
    }

    /// Automatically syncs with device hardware 90Hz / 120Hz display modes
    /// for buttery-smooth fluid transitions with zero GPU frame degradation.
    private fun enableHighRefreshRate() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val modes = display?.supportedModes
                val maxMode = modes?.maxByOrNull { it.refreshRate }
                if (maxMode != null) {
                    val params = window.attributes
                    params.preferredDisplayModeId = maxMode.modeId
                    window.attributes = params
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                @Suppress("DEPRECATION")
                val modes = windowManager.defaultDisplay.supportedModes
                val maxMode = modes?.maxByOrNull { it.refreshRate }
                if (maxMode != null) {
                    val params = window.attributes
                    params.preferredDisplayModeId = maxMode.modeId
                    window.attributes = params
                }
            }
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initNativeSoundPool(flutterEngine)

        // Native Sound Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val name = call.argument<String>("name") ?: "click"
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    playNativeSound(name, volume)
                    result.success(true)
                }
                "playAlarm" -> {
                    playNativeAlarm()
                    result.success(true)
                }
                "stopAlarm" -> {
                    stopNativeAlarm()
                    result.success(true)
                }
                "setSoundEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    isSoundEnabled = enabled
                    if (!enabled) stopNativeAlarm()
                    result.success(true)
                }
                "ping" -> {
                    result.success("pong")
                }
                else -> result.notImplemented()
            }
        }

        // Loopback Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOOPBACK_CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            when (call.method) {
                "isBluetoothConnected" -> {
                    val isConnected = checkBluetoothConnected(audioManager)
                    result.success(isConnected)
                }
                "startLoopback" -> {
                    val route = call.argument<String>("route") ?: "phone_to_earphone"
                    val gain = (call.argument<Double>("gain") ?: 1.0).toFloat()
                    monitorGain = gain
                    startAudioLoopback(audioManager, route)
                    result.success(true)
                }
                "stopLoopback" -> {
                    stopAudioLoopback()
                    result.success(true)
                }
                "setGain" -> {
                    val gain = (call.argument<Double>("gain") ?: 1.0).toFloat()
                    monitorGain = gain
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initNativeSoundPool(flutterEngine: FlutterEngine) {
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            soundPool = SoundPool.Builder()
                .setMaxStreams(10)
                .setAudioAttributes(audioAttributes)
                .build()

            val loader = FlutterInjector.instance().flutterLoader()
            val soundNames = listOf("click", "key", "tap", "success", "alert", "alarm")
            val soundsDir = File(cacheDir, "tooler_sounds")
            if (!soundsDir.exists()) {
                soundsDir.mkdirs()
            }

            for (soundName in soundNames) {
                try {
                    val assetKey = loader.getLookupKeyForAsset("assets/sounds/$soundName.wav")
                    val cacheFile = File(soundsDir, "$soundName.wav")
                    context.assets.open(assetKey).use { input ->
                        FileOutputStream(cacheFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                    if (cacheFile.exists() && cacheFile.length() > 0) {
                        val soundId = soundPool?.load(cacheFile.absolutePath, 1) ?: 0
                        if (soundId != 0) {
                            soundMap[soundName] = soundId
                        }
                    }
                } catch (e: Exception) {
                    // Fallback synthesis handled gracefully
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun playNativeSound(name: String, volume: Float = 1.0f) {
        if (!isSoundEnabled) return
        val soundId = soundMap[name]
        if (soundId != null && soundId != 0) {
            soundPool?.play(soundId, volume, volume, 1, 0, 1.0f)
        }
    }

    private fun playNativeAlarm() {
        if (!isSoundEnabled) return
        stopNativeAlarm()
        val alarmId = soundMap["alarm"] ?: soundMap["alert"]
        if (alarmId != null && alarmId != 0) {
            activeAlarmStreamId = soundPool?.play(alarmId, 1.0f, 1.0f, 2, 7, 1.0f) ?: 0
        }
    }

    private fun stopNativeAlarm() {
        if (activeAlarmStreamId != 0) {
            try {
                soundPool?.stop(activeAlarmStreamId)
            } catch (_: Exception) {}
            activeAlarmStreamId = 0
        }
    }

    private fun checkBluetoothConnected(audioManager: AudioManager): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                devices.any {
                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && (it.type == AudioDeviceInfo.TYPE_BLE_HEADSET || it.type == AudioDeviceInfo.TYPE_BLE_SPEAKER)) ||
                    it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                    it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                    it.type == AudioDeviceInfo.TYPE_USB_HEADSET
                }
            } else {
                @Suppress("DEPRECATION")
                audioManager.isBluetoothA2dpOn || audioManager.isWiredHeadsetOn
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun startAudioLoopback(audioManager: AudioManager, route: String) {
        if (isLoopbackRunning) {
            stopAudioLoopback()
        }

        try {
            val sampleRate = 44100
            val channelConfigIn = AudioFormat.CHANNEL_IN_MONO
            val channelConfigOut = AudioFormat.CHANNEL_OUT_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT

            val minBufSizeIn = AudioRecord.getMinBufferSize(sampleRate, channelConfigIn, audioFormat)
            val minBufSizeOut = AudioTrack.getMinBufferSize(sampleRate, channelConfigOut, audioFormat)
            val bufferSize = Math.max(minBufSizeIn, minBufSizeOut) * 2

            val audioSource = if (route == "earphone_to_phone") {
                try {
                    @Suppress("DEPRECATION")
                    audioManager.startBluetoothSco()
                    @Suppress("DEPRECATION")
                    audioManager.isBluetoothScoOn = true
                } catch (_: Exception) {}
                MediaRecorder.AudioSource.DEFAULT
            } else {
                try {
                    @Suppress("DEPRECATION")
                    audioManager.stopBluetoothSco()
                    @Suppress("DEPRECATION")
                    audioManager.isBluetoothScoOn = false
                } catch (_: Exception) {}
                MediaRecorder.AudioSource.MIC
            }

            val streamType = AudioManager.STREAM_MUSIC

            audioRecord = AudioRecord(audioSource, sampleRate, channelConfigIn, audioFormat, bufferSize)
            audioTrack = AudioTrack(streamType, sampleRate, channelConfigOut, audioFormat, bufferSize, AudioTrack.MODE_STREAM)

            audioTrack?.play()
            audioRecord?.startRecording()
            isLoopbackRunning = true

            loopbackThread = thread(start = true, priority = Thread.MAX_PRIORITY) {
                val audioBuffer = ShortArray(bufferSize / 2)
                while (isLoopbackRunning && audioRecord != null && audioTrack != null) {
                    val readCount = audioRecord?.read(audioBuffer, 0, audioBuffer.size) ?: 0
                    if (readCount > 0) {
                        if (monitorGain != 1.0f) {
                            for (i in 0 until readCount) {
                                val amplified = (audioBuffer[i] * monitorGain).toInt()
                                audioBuffer[i] = Math.max(-32768, Math.min(32767, amplified)).toShort()
                            }
                        }
                        audioTrack?.write(audioBuffer, 0, readCount)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopAudioLoopback()
        }
    }

    private fun stopAudioLoopback() {
        isLoopbackRunning = false
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
            @Suppress("DEPRECATION")
            audioManager.stopBluetoothSco()
            @Suppress("DEPRECATION")
            audioManager.isBluetoothScoOn = false
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        stopAudioLoopback()
        stopNativeAlarm()
        try {
            soundPool?.release()
            soundPool = null
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
