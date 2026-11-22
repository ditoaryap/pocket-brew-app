import '../models/enums.dart';
import '../models/models.dart';

class GrindRecommendation {
  const GrindRecommendation({
    required this.click,
    required this.approxMicrons,
    required this.deltaClicksFromV60,
    required this.deltaMicronsFromV60,
    required this.badgeLabel,
  });

  final int click;
  final int approxMicrons;
  final int deltaClicksFromV60;
  final int deltaMicronsFromV60;
  final String badgeLabel;
}

class DeltaMicronGrinderEngine {
  /// Computes recommended clicks for [grinder], [recipe], and optional [filter]
  /// using physical delta-micron offsets (deterministic, zero AI).
  static GrindRecommendation recommend({
    required GrinderSpec grinder,
    required BrewRecipe recipe,
    FilterSpec? filter,
    BrewMode? overrideMode,
    double extraUmOffset = 0,
  }) {
    final effectiveMode = overrideMode ?? recipe.mode;
    double recipeUm = recipe.grindOffsetUm;
    // If user switches a hot recipe into Japanese Iced mode dynamically, apply -90 um.
    if (effectiveMode == BrewMode.iced && recipe.mode == BrewMode.hot) {
      recipeUm -= 90;
    } else if (effectiveMode == BrewMode.hot && recipe.mode == BrewMode.iced) {
      recipeUm += 90;
    }
    final filterUm = filter?.grindOffsetUm ?? 0;
    final totalDeltaUm = recipeUm + filterUm + extraUmOffset;

    final deltaClicks = (totalDeltaUm / grinder.umPerClick).round();
    final targetClick = (grinder.v60HotDefault + deltaClicks)
        .clamp(grinder.minClick, grinder.maxClick);
    final actualDeltaClicks = targetClick - grinder.v60HotDefault;
    final actualDeltaUm = (actualDeltaClicks * grinder.umPerClick).round();
    final approxUm = (targetClick * grinder.umPerClick).round();

    final sign = actualDeltaClicks > 0 ? '+' : '';
    final umSign = actualDeltaUm > 0 ? '+' : '';
    final modeTag = effectiveMode == BrewMode.iced ? 'Japanese' : 'Hot V60';
    final badge = actualDeltaClicks == 0
        ? 'Standar · $modeTag'
        : '$sign$actualDeltaClicks klik ($umSign$actualDeltaUm μm) · $modeTag';

    return GrindRecommendation(
      click: targetClick,
      approxMicrons: approxUm,
      deltaClicksFromV60: actualDeltaClicks,
      deltaMicronsFromV60: actualDeltaUm,
      badgeLabel: badge,
    );
  }

  /// Translates a click setting from [from] grinder to [to] grinder
  /// by preserving Δμm distance from each grinder's official V60 baseline.
  static int convertClick({
    required GrinderSpec from,
    required int fromClick,
    required GrinderSpec to,
  }) {
    if (from.id == to.id) return fromClick;
    final deltaUm = (fromClick - from.v60HotDefault) * from.umPerClick;
    final converted = to.v60HotDefault + (deltaUm / to.umPerClick).round();
    return converted.clamp(to.minClick, to.maxClick);
  }

  /// Calculates nominal burr distance in microns for UI metadata.
  static int estimateMicrons(GrinderSpec grinder, int click) =>
      (click * grinder.umPerClick).round();
}
