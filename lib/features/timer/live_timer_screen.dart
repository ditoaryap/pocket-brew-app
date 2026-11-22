import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/audio/brew_audio_cue.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/canvas/dual_phase_timer_ring.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/engines/brew_timer_engine.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Continuous 60/120fps Live Brew Timer:
/// - Ready state shows a crisp setup summary + vertical pour schedule preview.
/// - Counts continuously from first drop (00:00) through Pouring, Wait/Swirl,
///   and Final Drawdown (never auto-stops past target drawdown) until the user
///   lifts the dripper and presses "Angkat Dripper · Selesai".
/// - Synthesizes 100% offline audio cues (Web Audio API on web, SystemSound on native).
class LiveTimerScreen extends ConsumerStatefulWidget {
  const LiveTimerScreen({super.key});

  @override
  ConsumerState<LiveTimerScreen> createState() => _LiveTimerScreenState();
}

class _LiveTimerScreenState extends ConsumerState<LiveTimerScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _elapsedMsNotifier = ValueNotifier<int>(0);
  int _accumulatedMs = 0;
  int _lastTickMs = 0;
  bool _running = false;
  bool _completed = false;
  bool _muted = false;

  // 3-2-1 prep countdown before brew timer starts at 00:00
  int _prepCountdownSec = 0;
  Timer? _prepTimer;

  // Audio/haptic transition tracking (ensures each cue fires exactly once).
  int _lastProcessedSec = -1;
  int _lastStageIdx = -1;
  TimerPhase _lastPhase = TimerPhase.ready;
  bool _firedTargetDrawdownCue = false;

  bool get _isPrepping => _prepCountdownSec > 0;
  int get _elapsedSec => _accumulatedMs ~/ 1000;

  @override
  void initState() {
    super.initState();
    _muted = !ref.read(pocketStoreProvider).prefs.soundCue;
    _ticker = createTicker((elapsed) {
      if (!_running) return;
      final nowMs = elapsed.inMilliseconds;
      final delta = nowMs - _lastTickMs;
      _lastTickMs = nowMs;
      if (delta > 0 && mounted) {
        final prevSec = _elapsedSec;
        _accumulatedMs += delta;
        // Drives 60-120fps ring smoothly via ValueListenableBuilder without rebuilding the whole screen!
        _elapsedMsNotifier.value = _accumulatedMs;
        final newSec = _elapsedSec;
        if (newSec != prevSec) {
          setState(() {});
          _evaluateLiveCues(newSec);
        }
      }
    });
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _ticker.dispose();
    _elapsedMsNotifier.dispose();
    super.dispose();
  }

  bool get _soundActive => !_muted;

  void _evaluateLiveCues(int sec) {
    if (!_running || _completed || sec == _lastProcessedSec) return;
    final store = ref.read(pocketStoreProvider);
    final plan = store.currentPlan;
    final targetSec = store.activeTargetDrawdownSec;
    final hapticOn = store.prefs.hapticCue;

    final snap = BrewTimerEngine.compute(
      elapsedSec: sec,
      stages: plan.stages,
      targetDrawdownSec: targetSec,
      isRunning: _running,
      isCompleted: _completed,
    );

    if (snap.phase == TimerPhase.pouring &&
        (_lastPhase != TimerPhase.pouring ||
            _lastStageIdx != snap.currentStageIndex)) {
      if (_soundActive) BrewAudioCue.playPourStart();
      if (hapticOn) HapticFeedback.mediumImpact();
    } else if (snap.phase == TimerPhase.waitingSwirl &&
        _lastPhase == TimerPhase.pouring) {
      if (_soundActive) BrewAudioCue.playWaitCue();
      if (hapticOn) HapticFeedback.lightImpact();
    }

    if (snap.isPreCue &&
        snap.secondsToNextTransition >= 1 &&
        snap.secondsToNextTransition <= 3) {
      if (_soundActive) {
        BrewAudioCue.playCountdownTick(snap.secondsToNextTransition);
      }
      if (hapticOn) HapticFeedback.selectionClick();
    }

    if (snap.isFinalDrawdown &&
        !_firedTargetDrawdownCue &&
        sec >= targetSec) {
      _firedTargetDrawdownCue = true;
      if (_soundActive) BrewAudioCue.playDrawdownTargetReached();
      if (hapticOn) HapticFeedback.mediumImpact();
    }

    _lastProcessedSec = sec;
    _lastStageIdx = snap.currentStageIndex;
    _lastPhase = snap.phase;
  }

  void _toggleSound() {
    final nextMuted = !_muted;
    setState(() => _muted = nextMuted);
    if (!nextMuted) {
      // Unlock & play a soft confirmation chime inside the user gesture.
      BrewAudioCue.playTestTone();
      if (ref.read(pocketStoreProvider).prefs.hapticCue) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _startOrResume() {
    final hapticOn = ref.read(pocketStoreProvider).prefs.hapticCue;
    // Must unlock Web Audio API synchronously inside the tap gesture.
    BrewAudioCue.unlock();

    if (_accumulatedMs == 0 && !_isPrepping) {
      // Fresh start -> launch crisp 3-2-1 preparation countdown so hands can grip the kettle!
      _startPrepCountdown(hapticOn: hapticOn);
      return;
    }

    _beginLiveTimerNow();
  }

  void _startPrepCountdown({required bool hapticOn}) {
    _prepTimer?.cancel();
    if (hapticOn) HapticFeedback.lightImpact();
    if (_soundActive) BrewAudioCue.playCountdownTick(3);
    setState(() {
      _prepCountdownSec = 3;
      _completed = false;
    });

    _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _prepCountdownSec - 1;
      if (next > 0) {
        if (ref.read(pocketStoreProvider).prefs.hapticCue) {
          HapticFeedback.selectionClick();
        }
        if (_soundActive) BrewAudioCue.playCountdownTick(next);
        setState(() => _prepCountdownSec = next);
      } else {
        timer.cancel();
        _beginLiveTimerNow();
      }
    });
  }

  void _cancelPrepCountdown() {
    _prepTimer?.cancel();
    setState(() => _prepCountdownSec = 0);
  }

  void _beginLiveTimerNow() {
    _prepTimer?.cancel();
    final hapticOn = ref.read(pocketStoreProvider).prefs.hapticCue;
    if (hapticOn) HapticFeedback.mediumImpact();
    BrewAudioCue.unlock();

    final isFreshStart = _accumulatedMs == 0;
    setState(() {
      _prepCountdownSec = 0;
      _running = true;
      _completed = false;
    });
    _lastTickMs = 0;

    if (isFreshStart) {
      _lastProcessedSec = 0;
      _lastStageIdx = 0;
      _lastPhase = TimerPhase.pouring;
      _firedTargetDrawdownCue = false;
      if (_soundActive) BrewAudioCue.playPourStart();
    }

    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _pause() {
    if (ref.read(pocketStoreProvider).prefs.hapticCue) {
      HapticFeedback.selectionClick();
    }
    _ticker.stop();
    setState(() => _running = false);
  }

  void _reset() {
    _prepTimer?.cancel();
    _ticker.stop();
    _elapsedMsNotifier.value = 0;
    setState(() {
      _prepCountdownSec = 0;
      _accumulatedMs = 0;
      _running = false;
      _completed = false;
      _lastProcessedSec = -1;
      _lastStageIdx = -1;
      _lastPhase = TimerPhase.ready;
      _firedTargetDrawdownCue = false;
    });
  }

  void _fastForwardDemo(int deltaSec) {
    final hapticOn = ref.read(pocketStoreProvider).prefs.hapticCue;
    if (hapticOn) HapticFeedback.selectionClick();
    BrewAudioCue.unlock();
    _prepTimer?.cancel();
    setState(() {
      _prepCountdownSec = 0;
      _accumulatedMs += deltaSec * 1000;
      _elapsedMsNotifier.value = _accumulatedMs;
      if (!_running && !_completed) {
        _running = true;
        _lastTickMs = 0;
        if (!_ticker.isActive) _ticker.start();
      }
    });
    _evaluateLiveCues(_elapsedSec);
  }

  void _markDrawdownDone() {
    if (ref.read(pocketStoreProvider).prefs.hapticCue) {
      HapticFeedback.heavyImpact();
    }
    if (_soundActive) BrewAudioCue.playFinish();
    _ticker.stop();
    final isIced = ref.read(pocketStoreProvider).draft.mode == BrewMode.iced;
    if (isIced && !_completed) {
      setState(() {
        _running = false;
        _completed = true;
      });
    } else {
      _proceedToEvaluation();
    }
  }

  void _proceedToEvaluation() {
    final finalSec = _elapsedSec == 0
        ? ref.read(pocketStoreProvider).activeTargetDrawdownSec
        : _elapsedSec;
    ref.read(pocketStoreProvider.notifier).finishTimerForEvaluation(finalSec);
    context.pushReplacement('/evaluation');
  }

  Future<void> _handleBack() async {
    if (_isPrepping) {
      _cancelPrepCountdown();
      context.pop();
      return;
    }
    if (!_running && _elapsedSec == 0) {
      context.pop();
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return AlertDialog(
          backgroundColor: c.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              PocketIcon(
                PocketIconType.warning,
                size: 20,
                color: c.brandHoney,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keluar dari Timer?',
                  style: PocketTheme.ui(
                    size: 16.5,
                    weight: 800,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Seduhan masih berjalan di ${BrewRecipeScaler.formatDuration(_elapsedSec)}. Yakin ingin membatalkan seduhan ini?',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Batalkan',
                style: PocketTheme.ui(
                  size: 13.5,
                  weight: 700,
                  color: c.statusError,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                minimumSize: const Size(0, 42),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjut Seduh'),
            ),
          ],
        );
      },
    );
    if (confirm == true && mounted) {
      _ticker.stop();
      context.pop();
    }
  }

  String _prepReminder(ScaledBrewPlan plan, TempUnit tempUnit) {
    final tempLabel = BrewRecipeScaler.formatTemp(plan.tempC, tempUnit);
    if (plan.mode == BrewMode.iced) {
      if (plan.icedMethod == IcedMethod.iceFirst) {
        return 'Bilas filter di wastafel dulu, isi ${plan.iceG.round()}g es di server, tare 0.0g · air $tempLabel.';
      }
      return 'Bilas filter & buang air bilasan, tare 0.0g · air $tempLabel (es ${plan.iceG.round()}g dituang terakhir).';
    }
    return 'Bilas kertas filter, ratakan bubuk kopi di dripper, lalu tare timbangan ke 0.0g · air $tempLabel.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final store = ref.watch(pocketStoreProvider);
    final plan = store.currentPlan;
    final recipe = store.activeRecipe;
    final targetDrawdownSec = store.activeTargetDrawdownSec;
    final unit = store.prefs.unitMode;
    final isIced = plan.mode == BrewMode.iced;

    final snap = BrewTimerEngine.compute(
      elapsedSec: _elapsedSec,
      stages: plan.stages,
      targetDrawdownSec: targetDrawdownSec,
      isRunning: _running,
      isCompleted: _completed,
    );

    final st = snap.currentStage?.stage;
    final accentColor = isIced ? c.brandIce : c.brandTerracotta;
    final accentTint = isIced ? c.tintIce : c.tintTerracotta;

    final (
      Color ringColor,
      Color secondaryArc,
      Color haloColor,
      Color statusTextColor,
      Color subtitleColor,
      String statusBadge,
    ) = _isPrepping
        ? (
            accentColor,
            c.brandHoney,
            accentTint,
            accentColor,
            c.textPrimary,
            'Bersiap Tuang...',
          )
        : switch (snap.phase) {
      TimerPhase.ready => (
          c.borderStrong,
          c.borderStrong,
          accentTint,
          accentColor,
          c.textSecondary,
          'Siap Seduh',
        ),
      TimerPhase.pouring => (
          c.brandTerracotta,
          c.brandSage,
          c.tintTerracotta,
          c.brandTerracottaInk,
          c.brandTerracottaInk,
          'Tuang · ${snap.currentStageIndex + 1}/${plan.stages.length}',
        ),
      TimerPhase.waitingSwirl when snap.isPastTargetDrawdown => (
          c.brandHoney,
          c.brandHoney,
          c.tintHoney,
          c.brandHoney,
          c.brandHoney,
          'Menetes · +${snap.overtimeSec}d',
        ),
      TimerPhase.waitingSwirl when snap.isFinalDrawdown => (
          c.brandSage,
          c.brandSage,
          c.tintSage,
          c.brandSage,
          c.brandSage,
          'Menetes (Drawdown)',
        ),
      TimerPhase.waitingSwirl => (
          c.brandSage,
          c.brandSage,
          c.tintSage,
          snap.isPreCue ? c.brandTerracottaInk : c.brandSage,
          c.brandSage,
          snap.isPreCue
              ? 'Tuang dlm ${snap.secondsToNextTransition}d!'
              : 'Tunggu & Swirl',
        ),
      TimerPhase.finished => (
          c.brandIce,
          c.brandIce,
          c.tintIce,
          c.brandIce,
          c.brandIce,
          'Seduhan Selesai ✓',
        ),
    };

    final targetFmt =
        BrewRecipeScaler.formatShortDuration(targetDrawdownSec);

    final ringSubtitle = _isPrepping
        ? 'Pegang kettle & siap tuang'
        : switch (snap.phase) {
            TimerPhase.ready => 'Hitung mundur 3 dtk sebelum tuang',
            TimerPhase.finished =>
              'Total ${BrewRecipeScaler.formatLiquid(plan.totalLiquidG, unit)}',
            TimerPhase.waitingSwirl when snap.isPastTargetDrawdown =>
              'Target ~$targetFmt tercapai',
            TimerPhase.waitingSwirl when snap.isFinalDrawdown =>
              'Total ${BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit)} tertuang',
            TimerPhase.waitingSwirl => snap.currentStage != null
                ? 'Tahan di ${BrewRecipeScaler.formatLiquid(snap.currentStage!.cumulativeWaterG, unit)}'
                : '',
            TimerPhase.pouring => snap.currentStage != null
                ? '+${BrewRecipeScaler.formatLiquid(snap.currentStage!.deltaWaterG, unit)} → ${BrewRecipeScaler.formatLiquid(snap.currentStage!.cumulativeWaterG, unit)}'
                : '',
          };

    final ringCaption = _isPrepping
        ? 'Tuangan 1: ${plan.stages.isNotEmpty ? BrewRecipeScaler.formatLiquidCompact(plan.stages.first.deltaWaterG, unit) : ''}'
        : switch (snap.phase) {
            TimerPhase.ready => '${plan.stages.length} tahap · ~$targetFmt',
            TimerPhase.pouring => snap.currentStage != null
                ? '${snap.currentStage!.stage.pattern.label} · ${BrewRecipeScaler.formatPourPace(snap.currentStage!.deltaWaterG, BrewRecipeScaler.pourDurationSec(snap.currentStage!.stage), unit, compact: true)}'
                : 'Spiral',
            TimerPhase.waitingSwirl when snap.isPastTargetDrawdown =>
              'Angkat dripper bila habis',
            TimerPhase.waitingSwirl when snap.isFinalDrawdown =>
              'Target ~$targetFmt (-${snap.secondsToNextTransition}d)',
            TimerPhase.waitingSwirl => snap.nextStage != null
                ? 'Tuang ${snap.nextStage!.stage.order} dlm 0:${snap.secondsToNextTransition.toString().padLeft(2, '0')}'
                : 'Biarkan menetes selesai',
            TimerPhase.finished => 'Target ~$targetFmt',
          };

    return PopScope(
      canPop: !_running && !_isPrepping && _elapsedSec == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PocketTopBar(
                title: snap.phase == TimerPhase.finished && isIced
                    ? 'Japanese Iced · Penutup'
                    : (snap.phase == TimerPhase.ready
                        ? 'Timer Seduh · ${plan.mode.shortBadge}'
                        : '${plan.mode.shortBadge} · ${recipe.author.split(' ').last}'),
                onBack: _handleBack,
                trailing: PocketTapScale(
                  onTap: _toggleSound,
                  child: AnimatedContainer(
                    duration: PocketCurves.fast,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _soundActive ? c.tintSage : c.surfaceElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _soundActive
                            ? c.brandSage.withValues(alpha: 0.35)
                            : c.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _soundActive
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          size: 16,
                          color: _soundActive ? c.brandSage : c.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _soundActive ? 'Suara' : 'Bisukan',
                          style: PocketTheme.ui(
                            size: 11,
                            weight: 700,
                            color: _soundActive ? c.brandSage : c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Compact Parameter Strip only while actively running/finished
              // (Ready state displays the full scannable Setup Summary Card below the dial).
              if (snap.phase != TimerPhase.ready)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isIced ? c.tintIce : c.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isIced
                                ? '${BrewRecipeScaler.formatDose(plan.doseG)} · ${store.draft.clickSetting} klik · ${BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit)} + ${plan.iceG.round()}g Es'
                                : '${store.activeBean?.name.split(' ').take(2).join(' ') ?? 'V60'} · ${BrewRecipeScaler.formatDose(plan.doseG)} · ${store.draft.clickSetting} klik',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PocketTheme.mono(
                              size: 11,
                              weight: FontWeight.w700,
                              color: isIced ? c.brandIce : c.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isIced
                              ? plan.icedMethod.shortLabel
                              : '${BrewRecipeScaler.formatTemp(plan.tempC, store.prefs.tempUnit)} · ${BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit)}',
                          style: PocketTheme.mono(
                            size: 11,
                            weight: FontWeight.w800,
                            color: isIced ? c.brandIce : c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  children: [
                    Center(
                      child: RepaintBoundary(
                        child: ValueListenableBuilder<int>(
                          valueListenable: _elapsedMsNotifier,
                          builder: (context, ms, _) {
                            final preciseSec = ms / 1000.0;
                            final continuousOverall = _isPrepping
                                ? ((4 - _prepCountdownSec) / 3.0)
                                    .clamp(0.0, 1.0)
                                : (snap.phase == TimerPhase.finished
                                    ? 1.0
                                    : (preciseSec /
                                            targetDrawdownSec
                                                .clamp(1, 9999))
                                        .clamp(0.0, 1.0));
                            final continuousPhase = _isPrepping
                                ? ((4 - _prepCountdownSec) / 3.0)
                                    .clamp(0.0, 1.0)
                                : (snap.phase == TimerPhase.finished
                                    ? 1.0
                                    : (st == null
                                        ? 0.0
                                        : ((preciseSec - st.startSec) /
                                                (st.endSec - st.startSec)
                                                    .clamp(1, 9999))
                                            .clamp(0.0, 1.0)));

                            return DualPhaseTimerRing(
                              size: (snap.phase == TimerPhase.ready &&
                                      !_isPrepping)
                                  ? 204
                                  : 216,
                              timeText: _isPrepping
                                  ? '$_prepCountdownSec'
                                  : BrewRecipeScaler.formatDuration(ms ~/ 1000),
                              statusLabel: statusBadge,
                              subtitleText: ringSubtitle,
                              captionText: ringCaption,
                              overallProgress: continuousOverall,
                              phaseProgress: continuousPhase,
                              ringColor: ringColor,
                              secondaryArcColor: secondaryArc,
                              haloColor: haloColor,
                              statusTextColor: statusTextColor,
                              subtitleColor: subtitleColor,
                              isPreCuePulse: _isPrepping || snap.isPreCue,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: PocketCurves.smoothOut,
                      child: snap.phase == TimerPhase.ready
                          ? _buildReadyBody(
                              context,
                              c: c,
                              store: store,
                              plan: plan,
                              recipe: recipe,
                                      targetDrawdownSec: targetDrawdownSec,
                                      unit: unit,
                                      isIced: isIced,
                                    )
                                  : (snap.phase == TimerPhase.finished &&
                                          isIced)
                                      ? _buildIcedFinishBody(
                                          context,
                                          c: c,
                                          plan: plan,
                                          targetDrawdownSec: targetDrawdownSec,
                                          unit: unit,
                                        )
                                      : _buildRunningBody(
                                          context,
                                          c: c,
                                          plan: plan,
                                          targetDrawdownSec: targetDrawdownSec,
                                          unit: unit,
                                          snap: snap,
                                        ),
                    ),
                  ],
                ),
              ),

              // Wet-Hand Bottom Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                child: _isPrepping
                    ? Row(
                        children: [
                          PocketTapScale(
                            onTap: _cancelPrepCountdown,
                            child: Container(
                              height: 52,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              decoration: BoxDecoration(
                                color: c.surfaceElevated,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Batal',
                                style: PocketTheme.ui(
                                  size: 13,
                                  weight: 700,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PocketButton(
                              label: 'Lewati · Mulai Langsung',
                              pocketIcon: PocketIconType.play,
                              backgroundColor: accentColor,
                              foregroundColor: c.textOnAccent,
                              onTap: _beginLiveTimerNow,
                            ),
                          ),
                        ],
                      )
                    : snap.phase == TimerPhase.ready
                        ? PocketButton(
                            label: 'Mulai Timer Sekarang',
                            pocketIcon: PocketIconType.play,
                            backgroundColor: accentColor,
                            foregroundColor: c.textOnAccent,
                            onTap: _startOrResume,
                          )
                    : snap.phase == TimerPhase.finished
                        ? PocketButton(
                            label: 'Lanjut ke Evaluasi Rasa',
                            backgroundColor: c.brandIce,
                            foregroundColor: c.textOnAccent,
                            onTap: _proceedToEvaluation,
                          )
                        : Row(
                            children: [
                              PocketTapScale(
                                onTap: _reset,
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.surfaceElevated,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Reset',
                                    style: PocketTheme.ui(
                                      size: 12.5,
                                      weight: 700,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PocketTapScale(
                                onTap: _running ? _pause : _startOrResume,
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.surfaceCard,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: c.borderSubtle),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _running ? 'Jeda' : 'Lanjut',
                                    style: PocketTheme.ui(
                                      size: 13,
                                      weight: 800,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PocketButton(
                                  label: 'Angkat Dripper · Selesai',
                                  backgroundColor: snap.isFinalDrawdown
                                      ? c.brandSage
                                      : c.brandEspresso,
                                  foregroundColor: c.textOnAccent,
                                  height: 52,
                                  fontSize: 13,
                                  onTap: _markDrawdownDone,
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyBody(
    BuildContext context, {
    required PocketColors c,
    required PocketAppState store,
    required ScaledBrewPlan plan,
    required BrewRecipe recipe,
    required int targetDrawdownSec,
    required UnitMode unit,
    required bool isIced,
  }) {
    final bean = store.activeBean;
    final accent = isIced ? c.brandIce : c.brandTerracottaInk;
    final tint = isIced ? c.tintIce : c.tintTerracotta;
    final targetFmt =
        BrewRecipeScaler.formatShortDuration(targetDrawdownSec);

    return Column(
      key: const ValueKey('ready_setup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Clean Setup Summary Card
        PocketCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bean?.name ?? 'Biji Kopi Pilihan',
                          style: PocketTheme.ui(
                            size: 14,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${recipe.name} · ${store.activeGrinder.model}',
                          style: PocketTheme.ui(
                            size: 11.5,
                            weight: 600,
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PocketPill(
                    label: isIced ? plan.icedMethod.shortLabel : 'Hot V60',
                    backgroundColor: tint,
                    foregroundColor: accent,
                    fontSize: 10.5,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SetupMetricCell(
                    label: 'Dosis',
                    value: BrewRecipeScaler.formatDose(plan.doseG),
                    sub: '1:${plan.ratio.toStringAsFixed(plan.ratio % 1 == 0 ? 0 : 1)}',
                  ),
                  const SizedBox(width: 6),
                  _SetupMetricCell(
                    label: 'Giling',
                    value: '${store.draft.clickSetting} klik',
                    sub: store.activeGrinder.brand,
                  ),
                  const SizedBox(width: 6),
                  _SetupMetricCell(
                    label: 'Suhu',
                    value: BrewRecipeScaler.formatTemp(
                      plan.tempC,
                      store.prefs.tempUnit,
                    ),
                    sub: '~$targetFmt',
                  ),
                  const SizedBox(width: 6),
                  _SetupMetricCell(
                    label: isIced ? 'Air + Es' : 'Total Air',
                    value: BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit),
                    sub: isIced ? '+${plan.iceG.round()}g es' : 'Dituang',
                    highlight: true,
                    highlightColor: accent,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: PocketIcon(
                        isIced ? PocketIconType.snowflake : PocketIconType.flame,
                        size: 15,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _prepReminder(plan, store.prefs.tempUnit),
                        style: PocketTheme.ui(
                          size: 11.5,
                          weight: 600,
                          height: 1.4,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Vertical Pour Stages Preview Card
        PocketCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Alur Tuangan · ${plan.stages.length} Tahap',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PocketTheme.ui(
                        size: 13,
                        weight: 800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '0:00 → ~$targetFmt',
                    style: PocketTheme.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...plan.stages.map((s) {
                final pourSec = BrewRecipeScaler.pourDurationSec(s.stage);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: tint,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${s.stage.order}',
                          style: PocketTheme.mono(
                            size: 10.5,
                            weight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.stage.label,
                              style: PocketTheme.ui(
                                size: 12.5,
                                weight: 700,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              '${BrewRecipeScaler.formatShortDuration(s.stage.startSec)} · ${s.stage.pattern.label}',
                              style: PocketTheme.mono(
                                size: 10,
                                color: c.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '→ ${BrewRecipeScaler.formatLiquidCompact(s.cumulativeWaterG, unit)}',
                            style: PocketTheme.mono(
                              size: 12,
                              weight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            BrewRecipeScaler.formatPourPace(
                              s.deltaWaterG,
                              pourSec,
                              unit,
                            ),
                            style: PocketTheme.mono(
                              size: 10,
                              weight: FontWeight.w600,
                              color: c.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c.tintSage,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: PocketIcon(
                      PocketIconType.check,
                      size: 12,
                      color: c.brandSage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Angkat Dripper setelah tetesan habis (~$targetFmt)',
                      style: PocketTheme.ui(
                        size: 11.5,
                        weight: 600,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRunningBody(
    BuildContext context, {
    required PocketColors c,
    required ScaledBrewPlan plan,
    required int targetDrawdownSec,
    required UnitMode unit,
    required TimerSnapshot snap,
  }) {
    final targetFmt =
        BrewRecipeScaler.formatShortDuration(targetDrawdownSec);
    final bool isPouring = snap.phase == TimerPhase.pouring;
    final bool isOvertime = snap.isPastTargetDrawdown;
    final bool isDrawdown = snap.isFinalDrawdown;

    final Color cardBg = isPouring
        ? c.tintTerracotta
        : (isOvertime ? c.tintHoney : c.tintSage);
    final Color cardAccent = isPouring
        ? c.brandTerracottaInk
        : (isOvertime ? c.brandHoney : c.brandSage);

    final String actionHeading = isPouring
        ? '${snap.currentStage!.stage.label} · Tuang ke ${BrewRecipeScaler.formatLiquid(snap.currentStage!.cumulativeWaterG, unit)}'
        : isDrawdown
            ? 'Menetes (Drawdown) · Siap Angkat Dripper'
            : 'Tahan di ${BrewRecipeScaler.formatLiquid(snap.currentStage!.cumulativeWaterG, unit)} · Swirl / Tunggu';

    final String rightBadge = isPouring
        ? '-${snap.secondsToNextTransition}d'
        : isOvertime
            ? '+${snap.overtimeSec}d'
            : isDrawdown
                ? 'Target ~$targetFmt'
                : 'Tuang ${snap.nextStage?.stage.order ?? ''} -${snap.secondsToNextTransition}d';

    final String? pourPaceHint = (isPouring && snap.currentStage != null)
        ? 'Tuang ${BrewRecipeScaler.formatPourPace(snap.currentStage!.deltaWaterG, BrewRecipeScaler.pourDurationSec(snap.currentStage!.stage), unit)} · Pola ${snap.currentStage!.stage.pattern.label}'
        : null;

    final String guidanceBody = isPouring
        ? snap.currentStage!.stage.cue
        : isDrawdown
            ? 'Semua air sudah dituang. Timer terus berjalan sampai tetesan selesai — tekan "Angkat Dripper · Selesai" tepat saat dripper diangkat.'
            : (snap.nextStage != null
                ? 'Berikutnya: ${snap.nextStage!.stage.label} (${BrewRecipeScaler.formatPourPace(snap.nextStage!.deltaWaterG, BrewRecipeScaler.pourDurationSec(snap.nextStage!.stage), unit)} → ${BrewRecipeScaler.formatLiquidCompact(snap.nextStage!.cumulativeWaterG, unit)}).'
                : snap.currentStage!.stage.cue);

    return Column(
      key: const ValueKey('active_running'),
      children: [
        if (snap.currentStage != null)
          PocketCard(
            backgroundColor: cardBg,
            elevated: false,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        actionHeading,
                        style: PocketTheme.ui(
                          size: 13.5,
                          weight: 800,
                          color: cardAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceCard.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        rightBadge,
                        style: PocketTheme.mono(
                          size: 11,
                          weight: FontWeight.w800,
                          color: cardAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (pourPaceHint != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    pourPaceHint,
                    style: PocketTheme.mono(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: cardAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  guidanceBody,
                  style: PocketTheme.ui(
                    size: 12.5,
                    weight: 500,
                    height: 1.45,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        PocketCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              ...List.generate(plan.stages.length, (i) {
                final s = plan.stages[i];
                final done = i < snap.currentStageIndex ||
                    (isDrawdown && i == snap.currentStageIndex);
                final active = !isDrawdown && i == snap.currentStageIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: done
                            ? c.tintSage
                            : (active ? c.tintTerracotta : c.surfaceElevated),
                        child: done
                            ? PocketIcon(
                                PocketIconType.check,
                                size: 12,
                                color: c.brandSage,
                              )
                            : Text(
                                '${s.stage.order}',
                                style: PocketTheme.mono(
                                  size: 10.5,
                                  weight: FontWeight.w800,
                                  color: active
                                      ? c.brandTerracottaInk
                                      : c.textTertiary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.stage.label,
                              style: PocketTheme.ui(
                                size: 12.5,
                                weight: active ? 800 : 700,
                                color: done ? c.textTertiary : c.textPrimary,
                              ),
                            ),
                            Text(
                              '${BrewRecipeScaler.formatShortDuration(s.stage.startSec)} · ${BrewRecipeScaler.formatPourPace(s.deltaWaterG, BrewRecipeScaler.pourDurationSec(s.stage), unit, compact: true)} · ${s.stage.pattern.label}',
                              style: PocketTheme.mono(
                                size: 10,
                                color: c.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '→ ${BrewRecipeScaler.formatLiquid(s.cumulativeWaterG, unit)}',
                        style: PocketTheme.mono(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: active
                              ? c.brandTerracottaInk
                              : (done ? c.textTertiary : c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor:
                          isDrawdown ? c.brandSage : c.surfaceElevated,
                      child: PocketIcon(
                        PocketIconType.check,
                        size: 12,
                        color: isDrawdown ? c.textOnAccent : c.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Angkat Dripper (Drawdown selesai)',
                        style: PocketTheme.ui(
                          size: 12.5,
                          weight: isDrawdown ? 800 : 600,
                          color: isDrawdown ? c.brandSage : c.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '~$targetFmt',
                      style: PocketTheme.mono(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: isDrawdown ? c.brandSage : c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: PocketPill(
            label: '+15d Lompat Cepat (Preview)',
            backgroundColor: c.surfaceElevated,
            foregroundColor: c.textSecondary,
            fontSize: 10.5,
            onTap: () => _fastForwardDemo(15),
          ),
        ),
      ],
    );
  }

  Widget _buildIcedFinishBody(
    BuildContext context, {
    required PocketColors c,
    required ScaledBrewPlan plan,
    required int targetDrawdownSec,
    required UnitMode unit,
  }) {
    return Column(
      key: const ValueKey('iced_done'),
      children: [
        PocketCard(
          backgroundColor: c.tintIce,
          elevated: false,
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Langkah Akhir · ${plan.icedMethod.shortLabel}',
                      style: PocketTheme.ui(
                        size: 13.5,
                        weight: 800,
                        color: c.brandIce,
                      ),
                    ),
                  ),
                  PocketIcon(
                    PocketIconType.snowflake,
                    size: 17,
                    color: c.brandIce,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                plan.finishIceInstruction,
                style: PocketTheme.ui(
                  size: 13,
                  weight: 500,
                  height: 1.45,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PocketCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu Seduh Tercatat',
                    style: PocketTheme.ui(
                      size: 12,
                      weight: 700,
                      color: c.textSecondary,
                    ),
                  ),
                  Text(
                    'Target resep ~${BrewRecipeScaler.formatDuration(targetDrawdownSec)}',
                    style: PocketTheme.mono(
                      size: 10.5,
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
              Text(
                BrewRecipeScaler.formatDuration(_elapsedSec),
                style: PocketTheme.mono(
                  size: 18,
                  weight: FontWeight.w800,
                  color: c.brandIce,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupMetricCell extends StatelessWidget {
  const _SetupMetricCell({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final String sub;
  final bool highlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PocketTheme.ui(
                size: 10,
                weight: 600,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: PocketTheme.mono(
                  size: 13,
                  weight: FontWeight.w800,
                  color: highlight ? (highlightColor ?? c.textPrimary) : c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PocketTheme.mono(
                size: 9.5,
                weight: FontWeight.w600,
                color: c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
