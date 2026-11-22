import '../models/models.dart';

enum BeanFreshnessStage {
  resting,
  peak,
  pastPeak;

  String get label => switch (this) {
        resting => 'Masa Istirahat',
        peak => 'Paling Enak',
        pastPeak => 'Mulai Turun',
      };
}

class BeanStatusInfo {
  const BeanStatusInfo({
    required this.effectiveAgeDays,
    required this.stage,
    required this.badgeText,
    required this.subtitle,
    required this.cupsRemaining,
    required this.isLastCupAlert,
    required this.stockFraction,
  });

  final int effectiveAgeDays;
  final BeanFreshnessStage stage;
  final String badgeText;
  final String subtitle;
  final int cupsRemaining;
  final bool isLastCupAlert;
  final double stockFraction;
}

class BeanRestingCalculator {
  static BeanStatusInfo evaluate({
    required CoffeeBean bean,
    required UserPrefs prefs,
    DateTime? now,
    double typicalDoseG = 15.0,
  }) {
    final today = now ?? DateTime.now();
    final rawDays = today.difference(bean.roastDate).inDays.clamp(0, 3650);
    final effectiveAge = (rawDays - bean.frozenDays).clamp(0, 3650);
    final (minRest, maxPeakWindow) = bean.hasCustomResting
        ? (bean.customRestMinD!, bean.customRestMaxD!)
        : prefs.restingRange(bean.roastLevel);
    final pastPeakDay = maxPeakWindow + 28;

    late final BeanFreshnessStage stage;
    late final String badgeText;
    late final String subtitle;

    if (bean.isFrozen) {
      stage = BeanFreshnessStage.peak;
      badgeText = 'Cadangan · H+$effectiveAge';
      subtitle = 'Disimpan sebagai stok cadangan (belum dipakai seduh)';
    } else if (effectiveAge < minRest) {
      final waitDays = minRest - effectiveAge;
      stage = BeanFreshnessStage.resting;
      badgeText = 'Istirahat · H+$effectiveAge';
      subtitle =
          'Paling enak diseduh $waitDays hari lagi (target $minRest–$maxPeakWindow hari)';
    } else if (effectiveAge <= pastPeakDay) {
      stage = BeanFreshnessStage.peak;
      badgeText = 'Paling Enak · H+$effectiveAge';
      subtitle = bean.hasCustomResting
          ? 'Sedang paling enak diseduh (custom: $minRest–$maxPeakWindow hari)'
          : 'Sedang paling enak diseduh (${bean.roastLevel.shortLabel}: $minRest–$maxPeakWindow hari)';
    } else {
      stage = BeanFreshnessStage.pastPeak;
      badgeText = 'H+$effectiveAge';
      subtitle = 'Aroma mulai turun — naikkan dosis sedikit atau buat Japanese Iced';
    }

    final cups = (bean.remainingG / typicalDoseG).floor();
    final isLastCup = bean.remainingG > 0 && bean.remainingG <= 24.0;
    final frac = bean.bagWeightG <= 0
        ? 0.0
        : (bean.remainingG / bean.bagWeightG).clamp(0.0, 1.0);

    return BeanStatusInfo(
      effectiveAgeDays: effectiveAge,
      stage: stage,
      badgeText: badgeText,
      subtitle: subtitle,
      cupsRemaining: cups,
      isLastCupAlert: isLastCup,
      stockFraction: frac,
    );
  }
}
