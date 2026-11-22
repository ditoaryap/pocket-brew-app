import 'brew_recipe_scaler.dart';

enum TimerPhase {
  ready,
  pouring,
  waitingSwirl,
  finished,
}

class TimerSnapshot {
  const TimerSnapshot({
    required this.elapsedSec,
    required this.phase,
    required this.currentStageIndex,
    required this.currentStage,
    required this.nextStage,
    required this.secondsToNextTransition,
    required this.isPreCue,
    required this.overallProgress,
    required this.stageProgress,
    this.isFinalDrawdown = false,
    this.overtimeSec = 0,
  });

  final int elapsedSec;
  final TimerPhase phase;
  final int currentStageIndex;
  final ScaledStage? currentStage;
  final ScaledStage? nextStage;
  final int secondsToNextTransition;
  final bool isPreCue;
  final double overallProgress;
  final double stageProgress;

  /// True after the final pour finishes while coffee continues dripping
  /// until the user manually lifts the dripper and taps complete.
  final bool isFinalDrawdown;

  /// Seconds elapsed past [targetDrawdownSec] during final drawdown.
  final int overtimeSec;

  bool get isPastTargetDrawdown => isFinalDrawdown && overtimeSec > 0;
}

class BrewTimerEngine {
  static TimerSnapshot compute({
    required int elapsedSec,
    required List<ScaledStage> stages,
    required int targetDrawdownSec,
    required bool isRunning,
    required bool isCompleted,
  }) {
    if (stages.isEmpty) {
      return TimerSnapshot(
        elapsedSec: elapsedSec,
        phase: isCompleted ? TimerPhase.finished : TimerPhase.ready,
        currentStageIndex: 0,
        currentStage: null,
        nextStage: null,
        secondsToNextTransition: 0,
        isPreCue: false,
        overallProgress: 0,
        stageProgress: 0,
      );
    }

    if (isCompleted) {
      return TimerSnapshot(
        elapsedSec: elapsedSec,
        phase: TimerPhase.finished,
        currentStageIndex: stages.length - 1,
        currentStage: stages.last,
        nextStage: null,
        secondsToNextTransition: 0,
        isPreCue: false,
        overallProgress: 1.0,
        stageProgress: 1.0,
        isFinalDrawdown: false,
        overtimeSec: (elapsedSec - targetDrawdownSec).clamp(0, 9999),
      );
    }

    if (!isRunning && elapsedSec == 0) {
      return TimerSnapshot(
        elapsedSec: 0,
        phase: TimerPhase.ready,
        currentStageIndex: 0,
        currentStage: stages.first,
        nextStage: stages.length > 1 ? stages[1] : null,
        secondsToNextTransition: 0,
        isPreCue: false,
        overallProgress: 0,
        stageProgress: 0,
      );
    }

    int idx = stages.length - 1;
    for (int i = 0; i < stages.length; i++) {
      if (elapsedSec < stages[i].stage.endSec) {
        idx = i;
        break;
      }
    }

    final active = stages[idx];
    final next = idx + 1 < stages.length ? stages[idx + 1] : null;
    final isPouring = elapsedSec >= active.stage.startSec &&
        elapsedSec < active.stage.pourEndSec;
    final phase = isPouring ? TimerPhase.pouring : TimerPhase.waitingSwirl;

    final isFinalDrawdown = next == null && !isPouring;
    final effectiveDrawdownMark = targetDrawdownSec > active.stage.pourEndSec
        ? targetDrawdownSec
        : active.stage.endSec;

    final nextMark = isPouring
        ? active.stage.pourEndSec
        : (isFinalDrawdown ? effectiveDrawdownMark : active.stage.endSec);
    final secsToNext = (nextMark - elapsedSec).clamp(0, 9999);
    final isPreCue =
        !isPouring && next != null && secsToNext <= 3 && secsToNext > 0;
    final overtimeSec =
        isFinalDrawdown ? (elapsedSec - targetDrawdownSec).clamp(0, 9999) : 0;

    final stageEnd = isFinalDrawdown ? effectiveDrawdownMark : active.stage.endSec;
    final stageDur = (stageEnd - active.stage.startSec).clamp(1, 9999);
    final stProgress =
        ((elapsedSec - active.stage.startSec) / stageDur).clamp(0.0, 1.0);
    final overall =
        (elapsedSec / targetDrawdownSec.clamp(1, 9999)).clamp(0.0, 1.0);

    return TimerSnapshot(
      elapsedSec: elapsedSec,
      phase: phase,
      currentStageIndex: idx,
      currentStage: active,
      nextStage: next,
      secondsToNextTransition: secsToNext,
      isPreCue: isPreCue,
      overallProgress: overall,
      stageProgress: stProgress,
      isFinalDrawdown: isFinalDrawdown,
      overtimeSec: overtimeSec,
    );
  }
}
