import 'package:flutter/services.dart';

/// Native Android / VM offline audio cue engine.
/// Uses a zero-dependency native Android AudioTrack PCM chime synthesizer via MethodChannel
/// so warm pour-over bell tones play clearly on Android phones (ignoring silent touch-sounds).
class BrewAudioCue {
  static const MethodChannel _channel =
      MethodChannel('com.pocketbrew.pocket_brew/audio_cue');

  static void unlock() {}

  static void playCountdownTick(int remainingSec) =>
      _invoke('countdown', remainingSec: remainingSec);

  static void playPourStart() => _invoke('pourStart');

  static void playWaitCue() => _invoke('waitCue');

  static void playDrawdownTargetReached() => _invoke('drawdownTarget');

  static void playFinish() => _invoke('finish');

  static void playTestTone() => _invoke('test');

  static void _invoke(String type, {int? remainingSec}) {
    _channel.invokeMethod<void>('playCue', {
      'type': type,
      'remainingSec': ?remainingSec,
    }).catchError((_) {
      // Safe fallback in unit tests or unsupported desktop VMs.
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    });
  }
}
