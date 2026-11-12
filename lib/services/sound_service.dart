import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const MethodChannel _nativeChannel = MethodChannel('com.tooler.tooler/native_sound');

  bool soundEnabled = true;
  bool hapticsEnabled = true;
  bool _initialized = false;
  Timer? _alarmRingtoneTimer;

  // Fallback AudioPlayer for non-native / fallback environments
  AudioPlayer? _fallbackPlayer;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      soundEnabled = await StorageService().loadSoundEnabled();
      hapticsEnabled = await StorageService().loadHapticsEnabled();
      _syncNativeSoundState();
    } catch (_) {}
  }

  void _syncNativeSoundState() {
    try {
      _nativeChannel.invokeMethod('setSoundEnabled', {'enabled': soundEnabled});
    } catch (_) {}
  }

  void setSound(bool enabled) {
    soundEnabled = enabled;
    _syncNativeSoundState();
    StorageService().saveSoundEnabled(enabled);
  }

  void setHaptics(bool enabled) {
    hapticsEnabled = enabled;
    StorageService().saveHapticsEnabled(enabled);
  }

  /// Plays sound via native SoundPool (zero latency, bypasses system touch sounds mute),
  /// falling back to audioplayers and then SystemSound.
  Future<void> _playSound(String name, {double volume = 1.0}) async {
    if (!soundEnabled) return;

    try {
      // 1. Primary: Native SoundPool (< 1ms zero-latency on Android)
      await _nativeChannel.invokeMethod('play', {'name': name, 'volume': volume});
    } catch (_) {
      // 2. Secondary: audioplayers
      _playFallback(name, volume);
    }
  }

  void _playFallback(String name, double volume) {
    try {
      _fallbackPlayer ??= AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _fallbackPlayer?.stop();
      _fallbackPlayer?.setVolume(volume);
      _fallbackPlayer?.play(AssetSource('sounds/$name.wav'));
    } catch (_) {
      // 3. Tertiary: SystemSound fallback
      if (name == 'alert' || name == 'success') {
        SystemSound.play(SystemSoundType.alert);
      } else {
        SystemSound.play(SystemSoundType.click);
      }
    }
  }

  /// Crisp, modern UI click (clean glass / wood acoustic click)
  void playClick() {
    _playSound('click', volume: 1.0);
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Soft touch tap for subtle controls
  void playTap() {
    _playSound('tap', volume: 0.9);
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Distinct special click for important actions (favorite, tab switch, mode switch)
  void playSpecialClick() {
    _playSound('click', volume: 1.0);
    Timer(const Duration(milliseconds: 65), () {
      if (soundEnabled) _playSound('tap', volume: 0.85);
    });
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Satisfying mechanical keyboard / calculator key click
  void playKey() {
    _playSound('key', volume: 1.0);
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Cheerful 3-note ascending chime (C5-E5-G5) for calculation / task / timer
  void playSuccess() {
    _playSound('success', volume: 1.0);
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void playTaskComplete() {
    _playSound('success', volume: 1.0);
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Warm attention chime for notices & alerts
  void playAlert() {
    _playSound('alert', volume: 1.0);
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Repeating ringing alarm sequence when a timer completes
  void playTimerAlarm() {
    stopTimerAlarm();
    if (!soundEnabled && !hapticsEnabled) return;

    if (soundEnabled) {
      try {
        _nativeChannel.invokeMethod('playAlarm');
      } catch (_) {
        _playSound('alarm', volume: 1.0);
      }
    }

    int chimeCount = 0;
    void pulse() {
      if (hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }
      chimeCount++;
      if (chimeCount >= 8) {
        stopTimerAlarm();
      }
    }

    pulse();
    _alarmRingtoneTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      pulse();
    });
  }

  void stopTimerAlarm() {
    _alarmRingtoneTimer?.cancel();
    _alarmRingtoneTimer = null;
    try {
      _nativeChannel.invokeMethod('stopAlarm');
    } catch (_) {}
    try {
      _fallbackPlayer?.stop();
    } catch (_) {}
  }
}
