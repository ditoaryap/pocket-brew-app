import '../models/enums.dart';
import '../models/models.dart';

class ScaledStage {
  const ScaledStage({
    required this.stage,
    required this.deltaWaterG,
    required this.cumulativeWaterG,
  });

  final PourStage stage;
  final double deltaWaterG;
  final double cumulativeWaterG;
}

class ScaledBrewPlan {
  const ScaledBrewPlan({
    required this.doseG,
    required this.ratio,
    required this.gramsPerLiter,
    required this.totalLiquidG,
    required this.hotWaterG,
    required this.iceG,
    required this.iceRatio,
    required this.tempC,
    required this.mode,
    required this.icedMethod,
    required this.stages,
    required this.preBrewIceHint,
    required this.finishIceInstruction,
  });

  final double doseG;
  final double ratio;
  final double gramsPerLiter;
  final double totalLiquidG;
  final double hotWaterG;
  final double iceG;
  final double iceRatio;
  final int tempC;
  final BrewMode mode;
  final IcedMethod icedMethod;
  final List<ScaledStage> stages;
  final String preBrewIceHint;
  final String finishIceInstruction;
}

class BrewRecipeScaler {
  static const double minIceRatio = 0.15;
  static const double maxIceRatio = 0.60;

  static double clampIceRatio(double ratio) =>
      ratio.clamp(minIceRatio, maxIceRatio);

  /// Formats water/liquid volume in [g], [ml], or [oz].
  static String formatLiquid(double gramsOrMl, UnitMode unit) {
    return switch (unit) {
      UnitMode.gram => '${gramsOrMl.round()} g',
      UnitMode.ml => '${gramsOrMl.round()} ml',
      UnitMode.oz => '${(gramsOrMl / 29.5735).toStringAsFixed(1)} oz',
    };
  }

  /// Compact liquid formatting matching FigCraft (`250g`, `250 ml`, `8.5 oz`).
  static String formatLiquidCompact(double gramsOrMl, UnitMode unit) {
    return switch (unit) {
      UnitMode.gram => '${gramsOrMl.round()}g',
      UnitMode.ml => '${gramsOrMl.round()} ml',
      UnitMode.oz => '${(gramsOrMl / 29.5735).toStringAsFixed(1)} oz',
    };
  }

  /// Formats coffee dose cleanly (always in grams, optional oz note if needed).
  static String formatDose(double doseG) {
    final isWhole = (doseG - doseG.roundToDouble()).abs() < 0.05;
    return isWhole ? '${doseG.toStringAsFixed(1)}g' : '${doseG.toStringAsFixed(1)}g';
  }

  /// Formats brew temperature in °C or °F.
  static String formatTemp(int tempC, TempUnit unit) {
    if (unit == TempUnit.fahrenheit) {
      final f = ((tempC * 9 / 5) + 32).round();
      return '$f°F';
    }
    return '$tempC°C';
  }

  /// Formats seconds as MM:SS (for live timer display).
  static String formatDuration(int totalSeconds) {
    final clamped = totalSeconds < 0 ? 0 : totalSeconds;
    final m = clamped ~/ 60;
    final s = clamped % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Active pouring duration in seconds for a stage (`pourEndSec - startSec`).
  static int pourDurationSec(PourStage stage) =>
      (stage.pourEndSec - stage.startSec).clamp(1, 999);

  /// Formats a human-friendly pour pace such as `50 ml dlm 12 dtk`
  /// (or compact `50 ml / 12 dtk`), automatically honoring the active unit (`g`/`ml`/`oz`).
  static String formatPourPace(
    double deltaWaterG,
    int pourSec,
    UnitMode unit, {
    bool compact = false,
  }) {
    final vol = formatLiquidCompact(deltaWaterG, unit);
    final sec = pourSec.clamp(1, 999);
    return compact ? '$vol / $sec dtk' : '$vol dlm $sec dtk';
  }

  /// Calculates recommended pour seconds for a given water volume and pace preset.
  static int recommendedPourSec(double deltaWaterG, PourRate rate) {
    if (deltaWaterG <= 0) return 10;
    return (deltaWaterG / rate.gramsPerSec).round().clamp(4, 90);
  }

  /// Compact M:SS duration matching FigCraft cards (`3:00`, `2:25`, `0:45`).
  static String formatShortDuration(int totalSeconds) {
    final clamped = totalSeconds < 0 ? 0 : totalSeconds;
    final m = clamped ~/ 60;
    final s = clamped % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Scales a recipe for any [doseG], [ratio], [mode], [iceRatio], and [icedMethod].
  /// Optionally accepts [overrideStages] for session-only pour improvisations outside the preset.
  static ScaledBrewPlan scale({
    required BrewRecipe recipe,
    required double doseG,
    required double ratio,
    required BrewMode mode,
    double iceRatio = 0.40,
    IcedMethod icedMethod = IcedMethod.iceFirst,
    int? overrideTempC,
    List<PourStage>? overrideStages,
  }) {
    final safeDose =
        ((doseG.clamp(1.0, 120.0) * 10).round() / 10.0).clamp(1.0, 120.0);
    final safeRatio = ratio.clamp(6.0, 25.0);
    final totalLiquid = (safeDose * safeRatio).roundToDouble();
    final gPerL = totalLiquid > 0 ? (safeDose / (totalLiquid / 1000.0)) : 60.0;

    final effectiveIceRatio =
        mode == BrewMode.iced ? clampIceRatio(iceRatio) : 0.0;
    final iceG = mode == BrewMode.iced
        ? (totalLiquid * effectiveIceRatio).roundToDouble()
        : 0.0;
    final hotWaterG = (totalLiquid - iceG).roundToDouble();

    final baseTemp = overrideTempC ??
        (mode == BrewMode.iced && recipe.mode == BrewMode.hot
            ? (recipe.tempC + 2).clamp(80, 99)
            : recipe.tempC);

    final activeStages =
        (overrideStages != null && overrideStages.isNotEmpty)
            ? overrideStages
            : recipe.stages;

    final scaledStages = <ScaledStage>[];
    double prevCum = 0;
    for (final st in activeStages) {
      final cum = (hotWaterG * st.targetCumulativePct).roundToDouble();
      final delta = (cum - prevCum).clamp(0.0, hotWaterG).toDouble();
      scaledStages.add(
        ScaledStage(stage: st, deltaWaterG: delta, cumulativeWaterG: cum),
      );
      prevCum = cum;
    }

    final preHint = icedMethod == IcedMethod.iceFirst
        ? 'Mode Es Duluan: bilas filter di wastafel agar ${iceG.round()}g es di server tidak meleleh sebelum seduh.'
        : 'Mode Seduh Dulu → Es: bilas filter di server seperti biasa, buang air bilasan, lalu seduh konsentrat panas dulu.';

    final finishInstruction = icedMethod == IcedMethod.iceFirst
        ? 'Angkat dripper, lalu putar (swirl) server 10 detik sampai es larut rata & suhu dingin stabil. Sajikan ke gelas berisi es batu baru!'
        : 'Tuang konsentrat kopi panas (${hotWaterG.round()} ml) perlahan ke gelas/server berisi ${iceG.round()}g es batu, lalu aduk ringan hingga dingin merata.';

    return ScaledBrewPlan(
      doseG: safeDose,
      ratio: safeRatio,
      gramsPerLiter: gPerL,
      totalLiquidG: totalLiquid,
      hotWaterG: hotWaterG,
      iceG: iceG,
      iceRatio: effectiveIceRatio,
      tempC: baseTemp,
      mode: mode,
      icedMethod: icedMethod,
      stages: scaledStages,
      preBrewIceHint: preHint,
      finishIceInstruction: finishInstruction,
    );
  }
}
