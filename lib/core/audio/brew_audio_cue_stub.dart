import 'package:flutter/services.dart';

/// Native / VM fallback for offline audio cues when Web Audio API is unavailable.
class BrewAudioCue {
  static void unlock() {}

  static void playCountdownTick(int remainingSec) => _click();

  static void playPourStart() => _alert();

  static void playWaitCue() => _click();

  static void playDrawdownTargetReached() => _alert();

  static void playFinish() => _alert();

  static void playTestTone() => _click();

  static void _click() {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  static void _alert() {
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
