import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/services.dart';

/// 100% offline Web Audio API cue synthesizer for Live Brew Timer.
/// Generates warm, gentle sine bell tones with smooth gain envelopes
/// (zero external audio files, zero network calls, mobile Safari & Chrome safe).
class BrewAudioCue {
  static JSObject? _ctx;
  static bool _unlocked = false;

  static JSObject? _ensureContext() {
    if (_ctx != null) return _ctx;
    try {
      final ctor = globalContext['AudioContext'] ??
          globalContext['webkitAudioContext'];
      if (ctor == null || ctor.isUndefinedOrNull) return null;
      _ctx = (ctor as JSFunction).callAsConstructor<JSObject>();
      return _ctx;
    } catch (_) {
      return null;
    }
  }

  /// Must be called synchronously inside a user tap/click handler so iOS Safari
  /// and mobile Chrome unlock audio playback for subsequent timer ticks.
  static void unlock() {
    try {
      final ctx = _ensureContext();
      if (ctx == null) return;
      final state = (ctx['state'] as JSString?)?.toDart;
      if (state == 'suspended' || state == 'interrupted') {
        ctx.callMethod<JSAny?>('resume'.toJS);
      }
      if (!_unlocked) {
        _unlocked = true;
        // Brief near-silent pulse reliably unlocks AudioContext on iOS Safari.
        _playTone(ctx, hz: 440, delaySec: 0.0, durationSec: 0.015, gain: 0.0001);
      }
    } catch (_) {
      // Never disrupt timer UI in restricted browser environments.
    }
  }

  /// Soft 3-2-1 countdown ping before the next pour starts.
  static void playCountdownTick(int remainingSec) {
    final ctx = _readyContext();
    if (ctx == null) {
      _fallbackClick();
      return;
    }
    final isFinal = remainingSec <= 1;
    _playTone(
      ctx,
      hz: isFinal ? 740.0 : 587.33,
      delaySec: 0.0,
      durationSec: isFinal ? 0.14 : 0.11,
      gain: isFinal ? 0.24 : 0.18,
    );
  }

  /// Warm ascending 2-note bell chime signaling: start pouring now.
  static void playPourStart() {
    final ctx = _readyContext();
    if (ctx == null) {
      _fallbackClick();
      return;
    }
    _playTone(ctx, hz: 523.25, delaySec: 0.0, durationSec: 0.15, gain: 0.24);
    _playTone(ctx, hz: 783.99, delaySec: 0.095, durationSec: 0.26, gain: 0.26);
  }

  /// Subtle descending cue signaling: pour target reached, swirl / let drain.
  static void playWaitCue() {
    final ctx = _readyContext();
    if (ctx == null) return;
    _playTone(ctx, hz: 659.25, delaySec: 0.0, durationSec: 0.11, gain: 0.14);
    _playTone(ctx, hz: 493.88, delaySec: 0.09, durationSec: 0.16, gain: 0.13);
  }

  /// Gentle double chime when elapsed time reaches target drawdown (timer continues).
  static void playDrawdownTargetReached() {
    final ctx = _readyContext();
    if (ctx == null) {
      _fallbackClick();
      return;
    }
    _playTone(ctx, hz: 587.33, delaySec: 0.0, durationSec: 0.14, gain: 0.18);
    _playTone(ctx, hz: 659.25, delaySec: 0.12, durationSec: 0.22, gain: 0.18);
  }

  /// Warm 3-note major chime when user lifts dripper / completes brew.
  static void playFinish() {
    final ctx = _readyContext();
    if (ctx == null) {
      _fallbackClick();
      return;
    }
    _playTone(ctx, hz: 523.25, delaySec: 0.0, durationSec: 0.15, gain: 0.24);
    _playTone(ctx, hz: 659.25, delaySec: 0.10, durationSec: 0.18, gain: 0.24);
    _playTone(ctx, hz: 783.99, delaySec: 0.20, durationSec: 0.34, gain: 0.26);
  }

  /// Crisp test chime when user unmutes sound to confirm audio is working.
  static void playTestTone() {
    unlock();
    final ctx = _readyContext();
    if (ctx == null) {
      _fallbackClick();
      return;
    }
    _playTone(ctx, hz: 523.25, delaySec: 0.0, durationSec: 0.10, gain: 0.18);
    _playTone(ctx, hz: 659.25, delaySec: 0.08, durationSec: 0.16, gain: 0.18);
  }

  static JSObject? _readyContext() {
    try {
      final ctx = _ensureContext();
      if (ctx == null) return null;
      final state = (ctx['state'] as JSString?)?.toDart;
      if (state == 'suspended' || state == 'interrupted') {
        ctx.callMethod<JSAny?>('resume'.toJS);
      }
      return ctx;
    } catch (_) {
      return null;
    }
  }

  static void _playTone(
    JSObject ctx, {
    required double hz,
    required double delaySec,
    required double durationSec,
    required double gain,
    String wave = 'sine',
  }) {
    try {
      final now = (ctx['currentTime'] as JSNumber?)?.toDartDouble ?? 0.0;
      final start = now + delaySec;
      final end = start + durationSec;

      final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
      final gainNode = ctx.callMethod<JSObject>('createGain'.toJS);

      osc['type'] = wave.toJS;
      final freqParam = osc['frequency'] as JSObject;
      freqParam.callMethod<JSAny?>('setValueAtTime'.toJS, hz.toJS, start.toJS);

      final gainParam = gainNode['gain'] as JSObject;
      gainParam.callMethod<JSAny?>(
        'setValueAtTime'.toJS,
        0.0001.toJS,
        start.toJS,
      );
      gainParam.callMethod<JSAny?>(
        'linearRampToValueAtTime'.toJS,
        gain.toJS,
        (start + 0.014).toJS,
      );
      gainParam.callMethod<JSAny?>(
        'exponentialRampToValueAtTime'.toJS,
        0.0001.toJS,
        end.toJS,
      );

      osc.callMethod<JSAny?>('connect'.toJS, gainNode);
      gainNode.callMethod<JSAny?>('connect'.toJS, ctx['destination']);

      osc.callMethod<JSAny?>('start'.toJS, start.toJS);
      osc.callMethod<JSAny?>('stop'.toJS, (end + 0.03).toJS);
    } catch (_) {
      // Ignore synthesis errors safely.
    }
  }

  static void _fallbackClick() {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
