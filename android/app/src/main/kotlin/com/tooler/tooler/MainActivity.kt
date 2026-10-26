package com.tooler.tooler

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tooler.tooler/audio_loopback"
    private var isLoopbackRunning = false
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var loopbackThread: Thread? = null
    private var monitorGain: Float = 1.0f

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
        super.onDestroy()
    }
}
