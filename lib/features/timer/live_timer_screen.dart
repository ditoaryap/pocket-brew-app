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
import '../../core/widgets/canvas/spiral_pour_diagram.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../core/widgets/pour_pattern_guide_sheet.dart';
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
    final isCompactWidth = MediaQuery.sizeOf(context).width < 380;

    final ringSubtitle = _isPrepping
        ? 'Siap pegang kettle'
        : switch (snap.phase) {
            TimerPhase.ready => 'Target ~$targetFmt',
            TimerPhase.finished =>
              'Total ${BrewRecipeScaler.formatLiquid(plan.totalLiquidG, unit)}',
            TimerPhase.waitingSwirl when snap.isPastTargetDrawdown =>
              'Target ~$targetFmt',
            TimerPhase.waitingSwirl when snap.isFinalDrawdown =>
              'Total ${BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit)}',
            TimerPhase.waitingSwirl => snap.currentStage != null
                ? 'Tahan ${BrewRecipeScaler.formatLiquid(snap.currentStage!.cumulativeWaterG, unit)}'
                : '',
            TimerPhase.pouring => snap.currentStage != null
                ? '→ ${BrewRecipeScaler.formatLiquid(snap.currentStage!.cumulativeWaterG, unit)}'
                : '',
          };

    final ringCaption = _isPrepping
        ? 'Tuang 1: ${plan.stages.isNotEmpty ? BrewRecipeScaler.formatLiquidCompact(plan.stages.first.deltaWaterG, unit) : ''}'
        : switch (snap.phase) {
            TimerPhase.ready => '${plan.stages.length} tahap · 3-2-1 siap',
            TimerPhase.pouring => snap.currentStage != null
                ? 'Sisa ${snap.secondsToNextTransition} dtk · ${snap.currentStage!.stage.pattern.label}'
                : 'Spiral',
            TimerPhase.waitingSwirl when snap.isPastTargetDrawdown =>
              'Angkat bila tetes habis',
            TimerPhase.waitingSwirl when snap.isFinalDrawdown =>
              'Target ~$targetFmt (-${snap.secondsToNextTransition}d)',
            TimerPhase.waitingSwirl => snap.nextStage != null
                ? 'Tuang ${snap.nextStage!.stage.order} dlm ${snap.secondsToNextTransition} dtk'
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          size: 18,
                          color: _soundActive ? c.brandSage : c.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _soundActive ? 'Suara' : 'Bisukan',
                          style: PocketTheme.ui(
                            size: 12.5,
                            weight: 800,
                            color: _soundActive ? c.brandSage : c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Compact Parameter Strip only while actively running/finished
              // (Ready state displays the full scannable 2x2 Setup Summary Card below the dial).
              if (snap.phase != TimerPhase.ready)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isIced ? c.tintIce : c.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isIced
                              ? '${BrewRecipeScaler.formatDose(plan.doseG)} · ${store.draft.clickSetting} klik · ${BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit)} + ${plan.iceG.round()}g Es'
                              : '${store.activeBean?.name ?? 'V60'} · ${BrewRecipeScaler.formatDose(plan.doseG)} · ${store.draft.clickSetting} klik',
                          style: PocketTheme.mono(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: isIced ? c.brandIce : c.textSecondary,
                          ),
                        ),
                        Text(
                          isIced
                              ? plan.icedMethod.shortLabel
                              : '${BrewRecipeScaler.formatTemp(plan.tempC, store.prefs.tempUnit)} · ${BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit)}',
                          style: PocketTheme.mono(
                            size: 12.5,
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
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
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
                                  ? (isCompactWidth ? 216 : 228)
                                  : (isCompactWidth ? 226 : 238),
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
                    const SizedBox(height: 16),

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
                          : (snap.phase == TimerPhase.finished && isIced)
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

              // Wet-Hand Bottom Controls (larger tap targets & clearer typography)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: _isPrepping
                    ? Row(
                        children: [
                          PocketTapScale(
                            onTap: _cancelPrepCountdown,
                            child: Container(
                              height: 54,
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
                                  size: 14,
                                  weight: 800,
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
                              height: 54,
                              fontSize: 14,
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
                            height: 54,
                            fontSize: 15,
                            onTap: _startOrResume,
                          )
                        : snap.phase == TimerPhase.finished
                            ? PocketButton(
                                label: 'Lanjut ke Evaluasi Rasa',
                                backgroundColor: c.brandIce,
                                foregroundColor: c.textOnAccent,
                                height: 54,
                                fontSize: 15,
                                onTap: _proceedToEvaluation,
                              )
                            : Row(
                                children: [
                                  PocketTapScale(
                                    onTap: _reset,
                                    child: Container(
                                      height: 54,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.surfaceElevated,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Reset',
                                        style: PocketTheme.ui(
                                          size: 13.5,
                                          weight: 800,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PocketTapScale(
                                    onTap: _running ? _pause : _startOrResume,
                                    child: Container(
                                      height: 54,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.surfaceCard,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border:
                                            Border.all(color: c.borderStrong),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _running ? 'Jeda' : 'Lanjut',
                                        style: PocketTheme.ui(
                                          size: 14,
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
                                      height: 54,
                                      fontSize: 13.5,
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
        // 1. Spacious 2x2 Setup Summary Card (legible at arm's length on a brew bar)
        PocketCard(
          padding: const EdgeInsets.all(16),
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
                            size: 16,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${recipe.name} · ${store.activeGrinder.model}',
                          style: PocketTheme.ui(
                            size: 13,
                            weight: 600,
                            color: c.textSecondary,
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
                    fontSize: 12,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SetupMetricTile(
                    label: 'Dosis & Rasio',
                    value: BrewRecipeScaler.formatDose(plan.doseG),
                    sub:
                        'Rasio 1:${plan.ratio.toStringAsFixed(plan.ratio % 1 == 0 ? 0 : 1)}',
                  ),
                  const SizedBox(width: 8),
                  _SetupMetricTile(
                    label: 'Gilingan',
                    value: '${store.draft.clickSetting} klik',
                    sub: store.activeGrinder.brand,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SetupMetricTile(
                    label: 'Suhu & Target',
                    value: BrewRecipeScaler.formatTemp(
                      plan.tempC,
                      store.prefs.tempUnit,
                    ),
                    sub: 'Target ~$targetFmt',
                  ),
                  const SizedBox(width: 8),
                  _SetupMetricTile(
                    label: isIced ? 'Air Panas + Es' : 'Total Air',
                    value: BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit),
                    sub: isIced
                        ? '+${plan.iceG.round()}g es batu'
                        : 'Dituang bertahap',
                    highlight: true,
                    highlightColor: accent,
                    highlightBg: tint,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: PocketIcon(
                        isIced
                            ? PocketIconType.snowflake
                            : PocketIconType.flame,
                        size: 16,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _prepReminder(plan, store.prefs.tempUnit),
                        style: PocketTheme.ui(
                          size: 13,
                          weight: 600,
                          height: 1.45,
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
        const SizedBox(height: 12),

        // 2. Clear Vertical Pour Stages Preview Card
        PocketCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alur Tuangan · ${plan.stages.length} Tahap',
                          style: PocketTheme.ui(
                            size: 15,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Durasi 0:00 → ~$targetFmt',
                          style: PocketTheme.mono(
                            size: 12,
                            weight: FontWeight.w700,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PourInfoButton(
                    pattern: plan.stages.isNotEmpty
                        ? plan.stages.first.stage.pattern
                        : PourPattern.spiral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...plan.stages.map((s) {
                final pourSec = BrewRecipeScaler.pourDurationSec(s.stage);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tint,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${s.stage.order}',
                          style: PocketTheme.mono(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.stage.label,
                              style: PocketTheme.ui(
                                size: 14,
                                weight: 800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${BrewRecipeScaler.formatShortDuration(s.stage.startSec)} · ${s.stage.pattern.label}',
                              style: PocketTheme.mono(
                                size: 12,
                                weight: FontWeight.w600,
                                color: c.textSecondary,
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
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            BrewRecipeScaler.formatPourPace(
                              s.deltaWaterG,
                              pourSec,
                              unit,
                            ),
                            style: PocketTheme.mono(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 18),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.tintSage,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: PocketIcon(
                      PocketIconType.check,
                      size: 14,
                      color: c.brandSage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Angkat Dripper setelah tetesan habis (~$targetFmt)',
                      style: PocketTheme.ui(
                        size: 13,
                        weight: 700,
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

    final activeStage = snap.currentStage;
    final nextStage = snap.nextStage;

    final String phaseHeadline = isPouring && activeStage != null
        ? 'Tuang · ${activeStage.stage.label}'
        : isDrawdown
            ? 'Menetes (Drawdown)'
            : 'Tunggu & Swirl';

    final String countdownPill = isPouring
        ? 'Sisa ${snap.secondsToNextTransition} dtk'
        : isOvertime
            ? '+${snap.overtimeSec} dtk'
            : isDrawdown
                ? 'Target ~$targetFmt'
                : 'Tuang ${nextStage?.stage.order ?? ''} · ${snap.secondsToNextTransition} dtk';

    final String leftMetricLabel = isPouring
        ? 'TARGET TIMBANGAN'
        : isDrawdown
            ? 'TOTAL TERTUANG'
            : 'TAHAN TIMBANGAN';
    final String leftMetricValue = isDrawdown
        ? BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit)
        : (activeStage != null
            ? BrewRecipeScaler.formatLiquid(activeStage.cumulativeWaterG, unit)
            : BrewRecipeScaler.formatLiquid(plan.hotWaterG, unit));

    final String rightMetricLabel = isPouring
        ? 'TUANG TAHAP INI'
        : isDrawdown
            ? 'TARGET SELESAI'
            : 'TAHAP BERIKUTNYA';
    final String rightMetricValue = isPouring && activeStage != null
        ? '+${BrewRecipeScaler.formatLiquid(activeStage.deltaWaterG, unit)}'
        : isDrawdown
            ? '~$targetFmt'
            : (nextStage?.stage.label ?? 'Menetes');
    final String rightMetricSub = isPouring && activeStage != null
        ? 'Tuang ${BrewRecipeScaler.formatPourPace(activeStage.deltaWaterG, BrewRecipeScaler.pourDurationSec(activeStage.stage), unit)}'
        : isDrawdown
            ? 'Angkat saat tetes habis'
            : (nextStage != null
                ? '+${BrewRecipeScaler.formatLiquidCompact(nextStage.deltaWaterG, unit)} → ${BrewRecipeScaler.formatLiquidCompact(nextStage.cumulativeWaterG, unit)}'
                : 'Tunggu hingga selesai');

    final String guidanceBody = isPouring && activeStage != null
        ? activeStage.stage.cue
        : isDrawdown
            ? 'Semua air sudah dituang. Biarkan menetes selesai lalu tekan "Angkat Dripper · Selesai".'
            : (nextStage != null
                ? 'Putar dripper pelan bila perlu. Siap tuang ${nextStage.stage.label} (${BrewRecipeScaler.formatPourPace(nextStage.deltaWaterG, BrewRecipeScaler.pourDurationSec(nextStage.stage), unit)}).'
                : (activeStage?.stage.cue ?? ''));

    return Column(
      key: const ValueKey('active_running'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. High-Contrast Brew-Bar Hero Command Card
        if (activeStage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardAccent.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase headline + Countdown pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        phaseHeadline,
                        style: PocketTheme.ui(
                          size: 17,
                          weight: 800,
                          color: cardAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceCard,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cardAccent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        countdownPill,
                        style: PocketTheme.mono(
                          size: 13,
                          weight: FontWeight.w800,
                          color: cardAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Giant 2-Tile Scale & Action Telemetry
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                leftMetricLabel,
                                style: PocketTheme.ui(
                                  size: 10.5,
                                  weight: 800,
                                  letterSpacing: 0.3,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  leftMetricValue,
                                  style: PocketTheme.mono(
                                    size: 26,
                                    weight: FontWeight.w800,
                                    color: cardAccent,
                                    height: 1.08,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lihat angka timbangan',
                                style: PocketTheme.ui(
                                  size: 11,
                                  weight: 600,
                                  color: c.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                rightMetricLabel,
                                style: PocketTheme.ui(
                                  size: 10.5,
                                  weight: 800,
                                  letterSpacing: 0.3,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  rightMetricValue,
                                  style: PocketTheme.mono(
                                    size: isPouring || isDrawdown ? 22 : 16,
                                    weight: FontWeight.w800,
                                    color: c.textPrimary,
                                    height: 1.12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                rightMetricSub,
                                style: PocketTheme.mono(
                                  size: 11.5,
                                  weight: FontWeight.w700,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pattern info chip + readable action cue
                if (!isDrawdown) ...[
                  const SizedBox(height: 10),
                  PocketTapScale(
                    onTap: () => showPourPatternGuideSheet(
                      context,
                      initialPattern: activeStage.stage.pattern,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceCard,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cardAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                            color: cardAccent,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Pola: ${PourDemoType.fromPattern(activeStage.stage.pattern).shortLabel} · Lihat Teknik',
                              style: PocketTheme.ui(
                                size: 12.5,
                                weight: 800,
                                color: cardAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (guidanceBody.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    guidanceBody,
                    style: PocketTheme.ui(
                      size: 13.5,
                      weight: 600,
                      height: 1.48,
                      color: c.textPrimary,
                    ),
                  ),
                ],

                // Dedicated Next Stage Preview bar while pouring
                if (isPouring && nextStage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceCard.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Berikutnya: ${nextStage.stage.label} (${BrewRecipeScaler.formatShortDuration(nextStage.stage.startSec)}) → ${BrewRecipeScaler.formatLiquidCompact(nextStage.cumulativeWaterG, unit)}',
                            style: PocketTheme.ui(
                              size: 12.5,
                              weight: 700,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 12),

        // 2. Scannable Stage Checklist Card with Highlighted Active Row
        PocketCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Progres Tahapan',
                  style: PocketTheme.ui(
                    size: 13.5,
                    weight: 800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              ...List.generate(plan.stages.length, (i) {
                final s = plan.stages[i];
                final done = i < snap.currentStageIndex ||
                    (isDrawdown && i == snap.currentStageIndex);
                final active = !isDrawdown && i == snap.currentStageIndex;
                return AnimatedContainer(
                  duration: PocketCurves.fast,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? (isPouring ? c.tintTerracotta : c.tintSage)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: active
                        ? Border.all(
                            color: cardAccent.withValues(alpha: 0.25),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: done
                            ? c.tintSage
                            : (active ? cardAccent : c.surfaceElevated),
                        child: done
                            ? PocketIcon(
                                PocketIconType.check,
                                size: 13,
                                color: c.brandSage,
                              )
                            : Text(
                                '${s.stage.order}',
                                style: PocketTheme.mono(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: active
                                      ? c.textOnAccent
                                      : c.textSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.stage.label,
                              style: PocketTheme.ui(
                                size: 14,
                                weight: active ? 800 : 700,
                                color: done ? c.textTertiary : c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${BrewRecipeScaler.formatShortDuration(s.stage.startSec)} · ${BrewRecipeScaler.formatPourPace(s.deltaWaterG, BrewRecipeScaler.pourDurationSec(s.stage), unit, compact: true)} · ${s.stage.pattern.label}',
                              style: PocketTheme.mono(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: done
                                    ? c.textTertiary
                                    : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '→ ${BrewRecipeScaler.formatLiquid(s.cumulativeWaterG, unit)}',
                        style: PocketTheme.mono(
                          size: 14,
                          weight: FontWeight.w800,
                          color: active
                              ? cardAccent
                              : (done ? c.textTertiary : c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDrawdown ? c.tintSage : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor:
                          isDrawdown ? c.brandSage : c.surfaceElevated,
                      child: PocketIcon(
                        PocketIconType.check,
                        size: 13,
                        color: isDrawdown ? c.textOnAccent : c.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Angkat Dripper (Drawdown selesai)',
                        style: PocketTheme.ui(
                          size: 13.5,
                          weight: isDrawdown ? 800 : 700,
                          color: isDrawdown ? c.brandSage : c.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '~$targetFmt',
                      style: PocketTheme.mono(
                        size: 13,
                        weight: FontWeight.w800,
                        color: isDrawdown ? c.brandSage : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: PocketPill(
            label: '+15d Lompat Cepat (Preview)',
            backgroundColor: c.surfaceElevated,
            foregroundColor: c.textSecondary,
            fontSize: 11.5,
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
          padding: const EdgeInsets.all(16),
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
                        size: 15.5,
                        weight: 800,
                        color: c.brandIce,
                      ),
                    ),
                  ),
                  PocketIcon(
                    PocketIconType.snowflake,
                    size: 20,
                    color: c.brandIce,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.finishIceInstruction,
                style: PocketTheme.ui(
                  size: 14,
                  weight: 600,
                  height: 1.5,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PocketCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu Seduh Tercatat',
                      style: PocketTheme.ui(
                        size: 14,
                        weight: 800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target resep ~${BrewRecipeScaler.formatDuration(targetDrawdownSec)}',
                      style: PocketTheme.mono(
                        size: 12,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                BrewRecipeScaler.formatDuration(_elapsedSec),
                style: PocketTheme.mono(
                  size: 22,
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

class _SetupMetricTile extends StatelessWidget {
  const _SetupMetricTile({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight = false,
    this.highlightColor,
    this.highlightBg,
  });

  final String label;
  final String value;
  final String sub;
  final bool highlight;
  final Color? highlightColor;
  final Color? highlightBg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: highlight ? (highlightBg ?? c.surfaceElevated) : c.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: highlight && highlightColor != null
              ? Border.all(color: highlightColor!.withValues(alpha: 0.25))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: PocketTheme.ui(
                size: 11.5,
                weight: 700,
                color: highlight ? (highlightColor ?? c.textSecondary) : c.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: PocketTheme.mono(
                  size: 17,
                  weight: FontWeight.w800,
                  color: highlight
                      ? (highlightColor ?? c.textPrimary)
                      : c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: PocketTheme.ui(
                size: 12,
                weight: 600,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
