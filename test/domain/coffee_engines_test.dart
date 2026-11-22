import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_brew/data/local/pocket_storage.dart';
import 'package:pocket_brew/domain/engines/bean_resting_calculator.dart';
import 'package:pocket_brew/domain/engines/brew_recipe_scaler.dart';
import 'package:pocket_brew/domain/engines/brew_timer_engine.dart';
import 'package:pocket_brew/domain/engines/coffee_compass_engine.dart';
import 'package:pocket_brew/domain/engines/delta_micron_grinder_engine.dart';
import 'package:pocket_brew/domain/models/enums.dart';
import 'package:pocket_brew/domain/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const c40 = GrinderSpec(
    id: 'comandante-c40-mk4',
    brand: 'Comandante',
    model: 'C40 MK4',
    umPerClick: 30,
    clicksPerRev: 12,
    minClick: 10,
    maxClick: 36,
    v60HotMin: 20,
    v60HotMax: 26,
    v60HotDefault: 23,
    zeroPointNote: '0',
    burrSpec: '38mm',
  );

  const kUltra = GrinderSpec(
    id: '1zpresso-k-ultra',
    brand: '1Zpresso',
    model: 'K-Ultra',
    umPerClick: 20,
    clicksPerRev: 100,
    minClick: 40,
    maxClick: 100,
    v60HotMin: 72,
    v60HotMax: 86,
    v60HotDefault: 78,
    zeroPointNote: '0',
    burrSpec: '48mm',
  );

  const hotRecipe = BrewRecipe(
    id: 'hoffmann-hot',
    name: 'Hoffmann 1-Cup',
    author: 'James Hoffmann',
    mode: BrewMode.hot,
    badge: 'Hot V60',
    isOfficial: true,
    summary: '',
    doseG: 15,
    ratio: 16.67,
    waterG: 250,
    iceRatio: 0,
    icedMethod: IcedMethod.iceFirst,
    tempC: 94,
    targetDrawdownSec: 180,
    grindOffsetUm: 0,
    stages: [
      PourStage(
        order: 1,
        label: 'Bloom',
        startSec: 0,
        pourEndSec: 12,
        endSec: 45,
        targetCumulativePct: 0.2,
        pattern: PourPattern.spiral,
        rate: PourRate.medium,
        cue: 'Bloom',
      ),
      PourStage(
        order: 2,
        label: 'Main',
        startSec: 45,
        pourEndSec: 90,
        endSec: 180,
        targetCumulativePct: 1.0,
        pattern: PourPattern.spiral,
        rate: PourRate.medium,
        cue: 'Main',
      ),
    ],
  );

  group('DeltaMicronGrinderEngine', () {
    test('Japanese Iced applies -90 um (-3 clicks on Comandante C40)', () {
      final rec = DeltaMicronGrinderEngine.recommend(
        grinder: c40,
        recipe: hotRecipe,
        overrideMode: BrewMode.iced,
      );
      expect(rec.click, 20);
      expect(rec.deltaClicksFromV60, -3);
      expect(rec.deltaMicronsFromV60, -90);
    });

    test('Cross-grinder conversion preserves delta-microns accurately', () {
      // C40 21 klik = -2 clicks * 30um = -60um -> K-Ultra (20um/click) = 78 - 3 = 75
      final converted = DeltaMicronGrinderEngine.convertClick(
        from: c40,
        fromClick: 21,
        to: kUltra,
      );
      expect(converted, 75);
    });
  });

  group('BrewRecipeScaler (Units + 2-Option Japanese Iced)', () {
    test('Clamps Japanese Iced ratio between 15% and 60% for flexible custom ice weights', () {
      final planHigh = BrewRecipeScaler.scale(
        recipe: hotRecipe,
        doseG: 15,
        ratio: 15.33,
        mode: BrewMode.iced,
        iceRatio: 0.75,
        icedMethod: IcedMethod.iceFirst,
      );
      expect(planHigh.iceRatio, closeTo(0.60, 0.001));
      expect(planHigh.preBrewIceHint, contains('wastafel'));
      expect(planHigh.finishIceInstruction, contains('swirl'));

      final planBrewFirst = BrewRecipeScaler.scale(
        recipe: hotRecipe,
        doseG: 15,
        ratio: 15.33,
        mode: BrewMode.iced,
        iceRatio: 0.05,
        icedMethod: IcedMethod.brewFirst,
      );
      expect(planBrewFirst.iceRatio, closeTo(0.15, 0.001));
      expect(planBrewFirst.preBrewIceHint, contains('Seduh Dulu'));
      expect(planBrewFirst.finishIceInstruction, contains('Tuang konsentrat'));
    });

    test('Formats g, ml, oz and °C/°F cleanly', () {
      expect(BrewRecipeScaler.formatLiquid(250, UnitMode.gram), '250 g');
      expect(BrewRecipeScaler.formatLiquid(250, UnitMode.ml), '250 ml');
      expect(BrewRecipeScaler.formatLiquid(250, UnitMode.oz), '8.5 oz');
      expect(BrewRecipeScaler.formatTemp(94, TempUnit.celsius), '94°C');
      expect(BrewRecipeScaler.formatTemp(94, TempUnit.fahrenheit), '201°F');
    });

    test('Supports 0.1g dose precision and flexible custom ratios', () {
      final plan = BrewRecipeScaler.scale(
        recipe: hotRecipe,
        doseG: 15.3,
        ratio: 18.0,
        mode: BrewMode.hot,
      );
      expect(plan.doseG, closeTo(15.3, 0.001));
      expect(plan.ratio, closeTo(18.0, 0.001));
      expect(plan.totalLiquidG, closeTo(275.0, 0.2));
      expect(BrewRecipeScaler.formatDose(plan.doseG), '15.3g');
    });

    test('Formats intuitive volume-per-seconds pour pace across ml/g/oz without g/s jargon', () {
      expect(
        BrewRecipeScaler.formatPourPace(50, 12, UnitMode.ml),
        '50 ml dlm 12 dtk',
      );
      expect(
        BrewRecipeScaler.formatPourPace(50, 12, UnitMode.ml, compact: true),
        '50 ml / 12 dtk',
      );
      expect(
        BrewRecipeScaler.formatPourPace(50, 12, UnitMode.gram),
        '50g dlm 12 dtk',
      );
      expect(
        BrewRecipeScaler.formatPourPace(50, 12, UnitMode.oz),
        '1.7 oz dlm 12 dtk',
      );
      expect(BrewRecipeScaler.recommendedPourSec(50, PourRate.slow), 17);
      expect(BrewRecipeScaler.recommendedPourSec(50, PourRate.medium), 8);
      expect(BrewRecipeScaler.recommendedPourSec(50, PourRate.fast), 6);
      for (final rate in PourRate.values) {
        expect(rate.label.toLowerCase(), isNot(contains('g/s')));
      }
    });
  });

  group('CoffeeCompassEngine (100% Non-AI Single-Variable Prescription)', () {
    test('Sour + fast drawdown recommends finer grind only (temp unchanged)', () {
      final rx = CoffeeCompassEngine.prescribe(
        feeling: TasteFeeling.sourSharp,
        currentClick: 23,
        currentTempC: 94,
        actualDrawdownSec: 148,
        targetDrawdownSec: 180,
        grinder: c40,
      );
      expect(rx.recommendedClick, 21);
      expect(rx.deltaTempC, 0);
      expect(rx.isGoldenCandidate, isFalse);
    });

    test('Balanced sweet suggests keeping setting as Golden Cup', () {
      final rx = CoffeeCompassEngine.prescribe(
        feeling: TasteFeeling.balancedSweet,
        currentClick: 21,
        currentTempC: 94,
        actualDrawdownSec: 178,
        targetDrawdownSec: 180,
        grinder: c40,
      );
      expect(rx.recommendedClick, 21);
      expect(rx.deltaClicks, 0);
      expect(rx.isGoldenCandidate, isTrue);
    });
  });

  group('BeanRestingCalculator', () {
    test('Respects custom resting preferences and freezer pause', () {
      final now = DateTime(2026, 11, 22);
      const prefs = UserPrefs(restLightMinD: 10, restLightMaxD: 16);
      final youngBean = CoffeeBean(
        id: 'b1',
        name: 'Ethiopia',
        roastery: 'R',
        origin: 'ET',
        process: 'Washed',
        roastLevel: RoastLevel.light,
        bagWeightG: 200,
        remainingG: 18,
        condition: BeanCondition.openedUsed,
        roastDate: now.subtract(const Duration(days: 6)),
        tastingNotes: const [],
      );

      final res = BeanRestingCalculator.evaluate(
        bean: youngBean,
        prefs: prefs,
        now: now,
      );
      expect(res.stage, BeanFreshnessStage.resting);
      expect(res.isLastCupAlert, isTrue);
      expect(res.cupsRemaining, 1);

      final storedBean = youngBean.copyWith(
        isFrozen: true,
        frozenDays: 2,
      );
      final storedRes = BeanRestingCalculator.evaluate(
        bean: storedBean,
        prefs: prefs,
        now: now,
      );
      expect(storedRes.stage, BeanFreshnessStage.peak);
      expect(storedRes.badgeText, contains('Cadangan'));
      expect(storedRes.badgeText.toLowerCase(), isNot(contains('freezer')));
      expect(storedRes.subtitle.toLowerCase(), isNot(contains('freezer')));
      expect(storedRes.subtitle.toLowerCase(), isNot(contains('jeda')));

      // Custom per-bean resting overrides global Settings default!
      final customRestBean = youngBean.copyWith(
        customRestMinD: 3,
        customRestMaxD: 12,
      );
      final customRestRes = BeanRestingCalculator.evaluate(
        bean: customRestBean,
        prefs: prefs,
        now: now,
      );
      expect(customRestRes.stage, BeanFreshnessStage.peak);
      expect(customRestRes.subtitle, contains('custom: 3–12 hari'));
    });
  });

  group('BrewTimerEngine', () {
    test('Transitions cleanly from ready -> pouring -> waiting -> drawdown -> overtime until lift dripper', () {
      final plan = BrewRecipeScaler.scale(
        recipe: hotRecipe,
        doseG: 15,
        ratio: 16.67,
        mode: BrewMode.hot,
      );

      final ready = BrewTimerEngine.compute(
        elapsedSec: 0,
        stages: plan.stages,
        targetDrawdownSec: 180,
        isRunning: false,
        isCompleted: false,
      );
      expect(ready.phase, TimerPhase.ready);
      expect(ready.isFinalDrawdown, isFalse);

      final pouring = BrewTimerEngine.compute(
        elapsedSec: 5,
        stages: plan.stages,
        targetDrawdownSec: 180,
        isRunning: true,
        isCompleted: false,
      );
      expect(pouring.phase, TimerPhase.pouring);
      expect(pouring.currentStageIndex, 0);

      final preCue = BrewTimerEngine.compute(
        elapsedSec: 43,
        stages: plan.stages,
        targetDrawdownSec: 180,
        isRunning: true,
        isCompleted: false,
      );
      expect(preCue.phase, TimerPhase.waitingSwirl);
      expect(preCue.isPreCue, isTrue);
      expect(preCue.isFinalDrawdown, isFalse);
      expect(preCue.secondsToNextTransition, 2);

      // Final drawdown before target (90..179s)
      final drawdown = BrewTimerEngine.compute(
        elapsedSec: 120,
        stages: plan.stages,
        targetDrawdownSec: 180,
        isRunning: true,
        isCompleted: false,
      );
      expect(drawdown.phase, TimerPhase.waitingSwirl);
      expect(drawdown.isFinalDrawdown, isTrue);
      expect(drawdown.overtimeSec, 0);
      expect(drawdown.secondsToNextTransition, 60);

      // Past target drawdown (195s): NEVER auto-stops; counts overtime until user lifts dripper
      final overtime = BrewTimerEngine.compute(
        elapsedSec: 195,
        stages: plan.stages,
        targetDrawdownSec: 180,
        isRunning: true,
        isCompleted: false,
      );
      expect(overtime.phase, TimerPhase.waitingSwirl);
      expect(overtime.isFinalDrawdown, isTrue);
      expect(overtime.isPastTargetDrawdown, isTrue);
      expect(overtime.overtimeSec, 15);

      // Manually lifting dripper finishes the brew with actual elapsed duration
      final done = BrewTimerEngine.compute(
        elapsedSec: 195,
        stages: plan.stages,
        targetDrawdownSec: 180,
        isRunning: false,
        isCompleted: true,
      );
      expect(done.phase, TimerPhase.finished);
      expect(done.elapsedSec, 195);
    });
  });

  group('PocketStorage Dual-Slot Auto-Backup & Schema Resilience', () {
    test('Recovers automatically from shadow backup if primary slot is corrupted', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = PocketStorage();

      await storage.writeState({
        'schema_version': 1,
        'prefs': const UserPrefs(userName: 'Dito v1').toJson(),
      });
      await storage.writeState({
        'schema_version': 1,
        'prefs': const UserPrefs(userName: 'Dito v2').toJson(),
      });

      // Simulate corrupted primary slot while shadow backup remains valid
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pocket_brew_state_v1', '{corrupted_json');

      final recovered = await storage.readState();
      expect(recovered, isNotNull);
      final recoveredPrefs =
          UserPrefs.fromJson(recovered!['prefs'] as Map<String, dynamic>);
      expect(recoveredPrefs.userName, 'Dito v1');
    });

    test('Defensive model fromJson handles legacy or minimal payloads safely', () {
      final minimalBean = CoffeeBean.fromJson({
        'id': 'bean-legacy',
        'name': 'Flores Bajawa',
      });
      expect(minimalBean.bagWeightG, 200.0);
      expect(minimalBean.remainingG, 200.0);

      final minimalLog = BrewLog.fromJson({
        'id': 'log-legacy',
      });
      expect(minimalLog.doseG, 15.0);
      expect(minimalLog.rating, 4.5);
    });
  });
}
