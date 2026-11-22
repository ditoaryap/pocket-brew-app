import '../models/enums.dart';
import '../models/models.dart';

class DialInPrescription {
  const DialInPrescription({
    required this.variableLabel,
    required this.headline,
    required this.explanation,
    required this.recommendedClick,
    required this.recommendedTempC,
    required this.deltaClicks,
    required this.deltaTempC,
    required this.isGoldenCandidate,
  });

  final String variableLabel;
  final String headline;
  final String explanation;
  final int recommendedClick;
  final int recommendedTempC;
  final int deltaClicks;
  final int deltaTempC;
  final bool isGoldenCandidate;
}

/// 100% deterministic Coffee Extraction Formula Engine (ZERO LLM / ZERO AI).
/// Always prescribes at most ONE variable change at a time so home brewers can dial in reliably.
class CoffeeCompassEngine {
  static DialInPrescription prescribe({
    required TasteFeeling feeling,
    required int currentClick,
    required int currentTempC,
    required int actualDrawdownSec,
    required int targetDrawdownSec,
    required GrinderSpec grinder,
  }) {
    final drawdownDeltaSec = actualDrawdownSec - targetDrawdownSec;
    final stepClicks = grinder.umPerClick <= 20 ? 3 : (grinder.umPerClick <= 35 ? 2 : 1);
    final fineClicks = (currentClick - stepClicks).clamp(grinder.minClick, grinder.maxClick);
    final coarseClicks = (currentClick + stepClicks).clamp(grinder.minClick, grinder.maxClick);
    final fineMicrons = (stepClicks * grinder.umPerClick).round();

    switch (feeling) {
      case TasteFeeling.balancedSweet:
        return DialInPrescription(
          variableLabel: 'Sudah Seimbang',
          headline: '$currentClick klik · Pertahankan!',
          explanation:
              'Ekstraksi berada di sweet spot (drawdown ${_deltaText(drawdownDeltaSec)}). Tandai sebagai Favorit agar bisa diulang persis besok.',
          recommendedClick: currentClick,
          recommendedTempC: currentTempC,
          deltaClicks: 0,
          deltaTempC: 0,
          isGoldenCandidate: true,
        );

      case TasteFeeling.sourSharp:
        if (drawdownDeltaSec <= -15) {
          return DialInPrescription(
            variableLabel: 'Saran Rumus · Gilingan',
            headline: '$currentClick → $fineClicks klik',
            explanation:
                'Waktu turun lebih cepat ${drawdownDeltaSec.abs()} detik & rasa asam tajam. Turunkan $stepClicks klik (-$fineMicrons μm) agar seduhan besok lebih manis dan seimbang.',
            recommendedClick: fineClicks,
            recommendedTempC: currentTempC,
            deltaClicks: fineClicks - currentClick,
            deltaTempC: 0,
            isGoldenCandidate: false,
          );
        } else if (currentTempC < 96) {
          final nextTemp = (currentTempC + 2).clamp(85, 98);
          return DialInPrescription(
            variableLabel: 'Saran Rumus · Suhu Air',
            headline: '$currentTempC°C → $nextTemp°C',
            explanation:
                'Waktu turun sudah normal (${_deltaText(drawdownDeltaSec)}), tetapi rasa masih tajam/asam. Naikkan suhu air +2°C agar ekstraksi gula lebih optimal tanpa menyumbat filter.',
            recommendedClick: currentClick,
            recommendedTempC: nextTemp,
            deltaClicks: 0,
            deltaTempC: nextTemp - currentTempC,
            isGoldenCandidate: false,
          );
        } else {
          return DialInPrescription(
            variableLabel: 'Saran Rumus · Gilingan',
            headline: '$currentClick → $fineClicks klik',
            explanation:
                'Suhu sudah tinggi ($currentTempC°C) namun rasa masih asam tajam. Haluskan $stepClicks klik (-$fineMicrons μm) untuk memperpanjang ekstraksi.',
            recommendedClick: fineClicks,
            recommendedTempC: currentTempC,
            deltaClicks: fineClicks - currentClick,
            deltaTempC: 0,
            isGoldenCandidate: false,
          );
        }

      case TasteFeeling.bitterDry:
        if (drawdownDeltaSec >= 15) {
          return DialInPrescription(
            variableLabel: 'Saran Rumus · Gilingan',
            headline: '$currentClick → $coarseClicks klik',
            explanation:
                'Waktu turun terlalu lama (+${drawdownDeltaSec}s) & terasa pahit/sepat. Kasarkan $stepClicks klik (+$fineMicrons μm) agar aliran lebih lega dan rasa bersih.',
            recommendedClick: coarseClicks,
            recommendedTempC: currentTempC,
            deltaClicks: coarseClicks - currentClick,
            deltaTempC: 0,
            isGoldenCandidate: false,
          );
        } else if (currentTempC > 89) {
          final nextTemp = (currentTempC - 2).clamp(82, 96);
          return DialInPrescription(
            variableLabel: 'Saran Rumus · Suhu Air',
            headline: '$currentTempC°C → $nextTemp°C',
            explanation:
                'Drawdown sudah pas (${_deltaText(drawdownDeltaSec)}) tapi terasa sepat kering. Turunkan suhu air -2°C untuk meredam senyawa pahit di akhir ekstraksi.',
            recommendedClick: currentClick,
            recommendedTempC: nextTemp,
            deltaClicks: 0,
            deltaTempC: nextTemp - currentTempC,
            isGoldenCandidate: false,
          );
        } else {
          return DialInPrescription(
            variableLabel: 'Saran Rumus · Gilingan',
            headline: '$currentClick → $coarseClicks klik',
            explanation:
                'Kasarkan $stepClicks klik (+$fineMicrons μm) dan hindari swirl berlebih di akhir agar aftertaste lebih bersih.',
            recommendedClick: coarseClicks,
            recommendedTempC: currentTempC,
            deltaClicks: coarseClicks - currentClick,
            deltaTempC: 0,
            isGoldenCandidate: false,
          );
        }

      case TasteFeeling.wateryWeak:
        final gentleFine = (currentClick - 1).clamp(grinder.minClick, grinder.maxClick);
        return DialInPrescription(
          variableLabel: 'Saran Rumus · Konsentrasi',
          headline: '$currentClick → $gentleFine klik',
          explanation:
              'Seduhan terasa encer / body tipis. Haluskan 1 klik (-${grinder.umPerClick.round()} μm) atau perketat rasio (misal 1:16 → 1:15) untuk body lebih berisi.',
          recommendedClick: gentleFine,
          recommendedTempC: currentTempC,
          deltaClicks: gentleFine - currentClick,
          deltaTempC: 0,
          isGoldenCandidate: false,
        );
    }
  }

  static String _deltaText(int delta) {
    if (delta.abs() <= 8) return 'tepat target';
    return delta > 0 ? '+${delta}d lebih lambat' : '${delta.abs()}d lebih cepat';
  }
}
