import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  void playClick() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
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
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
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
}
