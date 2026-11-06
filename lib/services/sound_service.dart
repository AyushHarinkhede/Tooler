import 'dart:async';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool soundEnabled = true;
  bool hapticsEnabled = true;
  Timer? _alarmRingtoneTimer;

  void playClick() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void playTap() => playClick();

  /// Distinct special click for important actions (favorite, tab switch, mode switch)
  void playSpecialClick() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
      Timer(const Duration(milliseconds: 60), () {
        if (soundEnabled) SystemSound.play(SystemSoundType.click);
      });
    }
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void playKey() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void playSuccess() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void playTaskComplete() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
      Timer(const Duration(milliseconds: 90), () {
        if (soundEnabled) SystemSound.play(SystemSoundType.alert);
      });
    }
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  void playAlert() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Repeating ringing alarm sequence when a timer completes
  void playTimerAlarm() {
    stopTimerAlarm();
    if (!soundEnabled && !hapticsEnabled) return;

    int chimeCount = 0;
    void chime() {
      if (soundEnabled) {
        SystemSound.play(SystemSoundType.alert);
      }
      if (hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }
      chimeCount++;
      if (chimeCount >= 8) {
        stopTimerAlarm();
      }
    }

    chime();
    _alarmRingtoneTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      chime();
    });
  }

  void stopTimerAlarm() {
    _alarmRingtoneTimer?.cancel();
    _alarmRingtoneTimer = null;
  }
}
