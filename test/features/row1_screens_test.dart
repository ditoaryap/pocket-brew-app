import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_brew/app/app.dart';
import 'package:pocket_brew/app/router.dart';
import 'package:pocket_brew/core/widgets/canvas/dual_phase_timer_ring.dart';
import 'package:pocket_brew/core/widgets/pocket_icons.dart';
import 'package:pocket_brew/data/local/pocket_storage.dart';
import 'package:pocket_brew/data/repositories/pocket_store.dart';
import 'package:pocket_brew/domain/models/enums.dart';
import 'package:pocket_brew/domain/models/models.dart';
import 'package:pocket_brew/features/beans/add_bean_screen.dart';
import 'package:pocket_brew/features/beans/bean_library_screen.dart';
import 'package:pocket_brew/features/brew_log/brew_log_screen.dart';
import 'package:pocket_brew/features/home/home_screen.dart';
import 'package:pocket_brew/features/methods/methods_screen.dart';
import 'package:pocket_brew/features/onboarding/onboarding_screen.dart';
import 'package:pocket_brew/features/quick_brew/pour_stage_editor_screen.dart';
import 'package:pocket_brew/features/quick_brew/quick_brew_screen.dart';
import 'package:pocket_brew/features/timer/live_timer_screen.dart';

class _MemoryPocketStorage extends PocketStorage {
  Map<String, dynamic>? _data;

  @override
  Future<Map<String, dynamic>?> readState() async => _data;

  @override
  Future<void> writeState(Map<String, dynamic> data) async {
    _data = data;
  }

  @override
  Future<void> clear() async {
    _data = null;
  }
}

void main() {
  setUp(() {
    rootBundle.clear();
  });

  Future<({ProviderContainer container, GoRouter router})> pumpApp(
    WidgetTester tester, {
    Size size = const Size(412, 917),
    String initialLocation = '/home',
    bool enableOnboardingGate = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = createPocketRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        pocketStorageProvider.overrideWithValue(_MemoryPocketStorage()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: PocketBrewApp(
          router: router,
          enableOnboardingGate: enableOnboardingGate,
        ),
      ),
    );
    for (int i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (container.read(pocketStoreProvider).isLoaded) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();
    return (container: container, router: router);
  }

  testWidgets(
    'v1.0.3 First-Time Launch · Minimalist Welcome Curtain routes fresh user to Setup Awal',
    (tester) async {
      final env = await pumpApp(tester, enableOnboardingGate: true);
      final container = env.container;

      // Fresh install automatically routes to Onboarding (Setup Awal)!
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Siapkan meja seduhmu'), findsOneWidget);
      expect(container.read(pocketStoreProvider).prefs.onboarded, isFalse);

      // Tapping "Lewati dulu" persists onboarded=true and opens Beranda
      await tester.tap(find.text('Lewati dulu'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(container.read(pocketStoreProvider).prefs.onboarded, isTrue);
    },
  );

  testWidgets('Screen 01 · Onboarding Setup Awal & per-tab Custom Gear notes', (
    tester,
  ) async {
    final env = await pumpApp(tester, initialLocation: '/onboarding');
    final container = env.container;

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Siapkan meja seduhmu'), findsOneWidget);
    expect(find.text('Lewati dulu'), findsOneWidget);
    expect(find.text('1. Satuan Air & Suhu'), findsOneWidget);
    expect(find.text('2. Grinder yang Kamu Pakai'), findsOneWidget);
    expect(find.text('Preset Resmi ✓'), findsOneWidget);
    expect(find.text('3. Dripper Favorit'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Aman dipakai tanpa internet & tanpa perlu akun'),
      150,
    );
    expect(
      find.text('Aman dipakai tanpa internet & tanpa perlu akun'),
      findsOneWidget,
    );

    // Scroll back up to toggle unit & temp
    await tester.scrollUntilVisible(find.text('1. Satuan Air & Suhu'), -150);
    await tester.tap(find.text('g'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('°F'));
    await tester.pumpAndSettle();

    // Select grinder & dripper presets
    await tester.ensureVisible(find.text('1Zpresso K-Ultra'));
    await tester.tap(find.text('1Zpresso K-Ultra'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kalita 185'));
    await tester.tap(find.text('Kalita 185'));
    await tester.pumpAndSettle();

    // Verify + Grinder Custom opens Grinder tab with beginner-friendly form (advanced collapsed by default)
    await tester.ensureVisible(find.text('+ Grinder Custom'));
    await tester.tap(find.text('+ Grinder Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Alat Sendiri'), findsOneWidget);
    expect(find.text('Klik Harian untuk V60 (Perkiraan)'), findsOneWidget);
    expect(find.text('Detail Teknis (Opsional)'), findsOneWidget);

    // Switch to Dripper tab via smooth PageView -> shows clean geometry cards!
    await tester.tap(find.text('Dripper'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pilih Bentuk Dripper'),
      findsOneWidget,
    );
    expect(find.text('Kerucut 60° (Conical)'), findsOneWidget);
    expect(find.text('Dasar Datar (Flat-Bottom)'), findsOneWidget);
    expect(find.text('Katup / Rendam (Hybrid)'), findsOneWidget);

    // Switch to Filter tab -> beginner-friendly flow guide cards with "Tidak Yakin"!
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Seberapa Cepat Air Turun di Kertas Ini?'), findsOneWidget);
    expect(find.text('Tidak Yakin (Pakai Normal)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Catatan Kertas Filter (Opsional)'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Catatan Kertas Filter (Opsional)'), findsOneWidget);

    await tester.tap(find.byWidgetPredicate(
      (w) => w is PocketIcon && w.type == PocketIconType.backArrow,
    ));
    await tester.pumpAndSettle();

    // Complete onboarding -> persists settings & navigates to /home
    await tester.tap(find.text('Selesai & Masuk Beranda'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final st = container.read(pocketStoreProvider);
    expect(st.prefs.unitMode, UnitMode.gram);
    expect(st.prefs.tempUnit, TempUnit.fahrenheit);
    expect(st.activeGrinder.id, '1zpresso-k-ultra');
    expect(st.activeDripper.id, 'kalita-wave-185');
  });

  testWidgets('Screen 02 · Redesigned Beranda with Quick Method Picker, Mode Switch & Bean Picker', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    final container = env.container;
    final router = env.router;

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Mau seduh apa, Dito?'), findsOneWidget);
    expect(find.textContaining('Meja Rumah'), findsNothing);
    expect(find.text('Ethiopia Guji Uraga'), findsWidgets);
    expect(find.text('Hot V60'), findsOneWidget);
    expect(find.text('Japanese Iced'), findsOneWidget);
    expect(find.text('Pilih Metode'), findsOneWidget);
    expect(find.text('Hoffmann 1-Cup'), findsOneWidget);
    expect(find.text('Tetsu 4:6'), findsOneWidget);
    expect(find.text('Edit Tahapan Seduh'), findsOneWidget);
    expect(find.text('21 klik'), findsOneWidget);
    expect(find.text('94°C'), findsOneWidget);
    expect(find.text('250 ml'), findsOneWidget);
    expect(find.text('Stok Kopi di Rumah'), findsOneWidget);
    expect(find.text('6 resep pro · 0 buatanmu'), findsOneWidget);
    expect(find.text('Belajar Seduh'), findsOneWidget);

    // Quick Method switch directly inside Beranda!
    await tester.tap(find.text('Tetsu 4:6'));
    await tester.pumpAndSettle();
    expect(
      container.read(pocketStoreProvider).activeRecipe.name,
      contains('4:6'),
    );
    await tester.tap(find.text('Hoffmann 1-Cup'));
    await tester.pumpAndSettle();

    // 1. Ganti kopi -> Bean Picker MUST NOT have "Tanpa Biji" option
    await tester.tap(find.text('Ganti kopi'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Biji Kopi'), findsOneWidget);
    expect(find.textContaining('Tanpa Biji'), findsNothing);
    await tester.tap(find.text('Kenya Nyeri AA').last);
    await tester.pumpAndSettle();
    expect(
      container.read(pocketStoreProvider).activeBean?.id,
      'bean-kenya-nyeri',
    );
    expect(find.text('Kenya Nyeri AA'), findsWidgets);

    // Switch back to Ethiopia Guji Uraga
    await tester.tap(find.text('Ganti kopi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ethiopia Guji Uraga').last);
    await tester.pumpAndSettle();

    // 2. Settings button -> /settings
    await tester.tap(find.byWidgetPredicate(
      (w) => w is PocketIcon && w.type == PocketIconType.sliders,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    // 3. Edit Tahapan Seduh -> /brew/stages
    await tester.tap(find.descendant(
      of: find.byType(HomeScreen),
      matching: find.text('Edit Tahapan Seduh'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Simpan & Pakai Resep'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    // 4. Metode & Resep card -> /methods
    final homeScroll = find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.drag(homeScroll, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metode & Resep'));
    await tester.pumpAndSettle();
    expect(find.byType(MethodsScreen), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    // 5. Belajar Seduh card -> /learn
    await tester.ensureVisible(find.text('Belajar Seduh'));
    await tester.tap(find.text('Belajar Seduh'));
    await tester.pumpAndSettle();
    expect(find.text('Belajar Seduh'), findsWidgets);
    router.pop();
    await tester.pumpAndSettle();

    // 6. Launch Hot V60 directly from Home -> /brew in Hot mode
    await tester.ensureVisible(find.text('Seduh Hot V60 Sekarang'));
    await tester.tap(find.text('Seduh Hot V60 Sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickBrewScreen), findsOneWidget);
    expect(container.read(pocketStoreProvider).draft.mode, BrewMode.hot);

    // Return to Beranda tab -> toggle Japanese Iced on Beranda -> launch -> /brew in Iced mode
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await tester.drag(
      find
          .descendant(
            of: find.byType(HomeScreen),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(HomeScreen),
      matching: find.text('Japanese Iced'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seduh Japanese Iced Sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickBrewScreen), findsOneWidget);
    expect(container.read(pocketStoreProvider).draft.mode, BrewMode.iced);
    expect(find.text('Es Duluan (Server)'), findsOneWidget);
  });

  testWidgets('Screen 03 · Metode & Resep tabs, zero demo custom recipes, select & create', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    final container = env.container;
    final router = env.router;

    router.push('/methods');
    await tester.pumpAndSettle();

    expect(find.byType(MethodsScreen), findsOneWidget);
    expect(find.text('Resep Profesional (6)'), findsOneWidget);
    expect(find.text('Resep Custom (0)'), findsOneWidget);
    expect(find.text('James Hoffmann · Better 1-Cup ✓'), findsOneWidget);
    expect(find.text('Tetsu Kasuya · 4:6 Method'), findsOneWidget);
    expect(find.text('James Hoffmann · Japanese Iced'), findsOneWidget);
    // V60 Pagi Custom & bottom custom strip MUST NOT exist!
    expect(find.text('V60 Pagi Custom · Custom'), findsNothing);
    expect(find.text('V60 Pagi Custom'), findsNothing);
    expect(find.text('Pulihkan Resep Bawaan yang Dihapus'), findsNothing);

    // Switch to Resep Custom (0) tab -> shows clean empty state with CTA
    await tester.tap(find.text('Resep Custom (0)'));
    await tester.pumpAndSettle();
    expect(find.text('V60 Pagi Custom'), findsNothing);
    expect(find.text('Japanese Iced Sore'), findsNothing);

    // Tap Buat Resep Custom -> opens PourStageEditorScreen cleanly
    await tester.tap(find.text('Buat Resep Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan & Pakai Resep'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    // Switch back to Pro tab & select Japanese Iced recipe -> navigates to /brew in iced mode
    await tester.tap(find.text('Resep Profesional (6)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('James Hoffmann · Japanese Iced'));
    await tester.tap(find.text('James Hoffmann · Japanese Iced'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickBrewScreen), findsOneWidget);
    expect(
      container.read(pocketStoreProvider).draft.recipeId,
      'hoffmann-japanese-iced',
    );
    expect(container.read(pocketStoreProvider).draft.mode, BrewMode.iced);
  });

  testWidgets(
    'Screens 04 & 05 · Brew tab, top Dose & Ratio, interactive Ice split, custom click, vertical stages & Bean Bar',
    (tester) async {
      final env = await pumpApp(tester);
      final container = env.container;

      // Navigate via Floating Dock Brew tab -> Screen 04 (Hot V60)
      await tester.tap(find.text('Brew'));
      await tester.pumpAndSettle();

      final inQuickBrew = find.byType(QuickBrewScreen);
      final qbScrollable = find.descendant(
        of: inQuickBrew,
        matching: find.byType(Scrollable),
      );
      expect(inQuickBrew, findsOneWidget);
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('Brew')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: inQuickBrew,
          matching: find.text('Ethiopia Guji Uraga'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: inQuickBrew,
          matching: find.text('Resep · Dosis, Rasio & Suhu'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('Suhu Air Seduh')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('Ganti →')),
        findsOneWidget,
      );
      expect(find.textContaining('g/s'), findsNothing);

      // Dose stepper (0.1g) is right near the top!
      final doseReadout = find.descendant(
        of: inQuickBrew,
        matching: find.text('15.0g'),
      );
      await tester.ensureVisible(doseReadout);
      await tester.tap(doseReadout);
      await tester.pumpAndSettle();
      expect(find.text('Atur Dosis Kopi (Custom)'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '15.3');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan 15.3g'));
      await tester.pumpAndSettle();
      expect(
        container.read(pocketStoreProvider).draft.doseG,
        closeTo(15.3, 0.001),
      );

      // Tap Custom ratio chip right at top -> opens synced Ratio/Water sheet
      final customRatioBtn = find.descendant(
        of: inQuickBrew,
        matching: find.text('Custom'),
      );
      await tester.tap(customRatioBtn);
      await tester.pumpAndSettle();
      expect(find.text('Atur Rasio & Total Air'), findsOneWidget);
      await tester.tap(find.text('1:18'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Pakai 1:18'));
      await tester.pumpAndSettle();
      expect(
        container.read(pocketStoreProvider).draft.ratio,
        closeTo(18.0, 0.05),
      );

      // Scroll to Grinder click hero & verify custom click sheet (e.g. 42 clicks)
      final click21 = find.descendant(
        of: inQuickBrew,
        matching: find.text('21 klik'),
      );
      await tester.scrollUntilVisible(click21, 180, scrollable: qbScrollable);
      await tester.tap(click21);
      await tester.pumpAndSettle();
      expect(find.text('Atur Klik Grinder (Custom)'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '42');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan 42 klik'));
      await tester.pumpAndSettle();
      expect(container.read(pocketStoreProvider).draft.clickSetting, 42);
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('42 klik')),
        findsOneWidget,
      );

      // Scroll to Pour Stages & verify preset hint + Edit Preset + Mulai Brew CTA
      await tester.scrollUntilVisible(
        find.descendant(of: inQuickBrew, matching: find.text('Mulai Brew')),
        220,
        scrollable: qbScrollable,
      );
      expect(
        find.descendant(
          of: inQuickBrew,
          matching: find.text('Hoffmann 1-Cup · 5 Tahap'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('Edit Preset')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('Mulai Brew')),
        findsOneWidget,
      );

      // Scroll back to top and switch to Screen 05 · Japanese Iced
      final icedTab = find.descendant(
        of: inQuickBrew,
        matching: find.text('Japanese Iced'),
      );
      await tester.drag(qbScrollable, const Offset(0, 900));
      await tester.pumpAndSettle();
      await tester.ensureVisible(icedTab);
      await tester.tap(icedTab);
      await tester.pumpAndSettle();

      // Bean Bar & unified 1:14/1:15/1:16 chips visible near top + interactive ice split presets!
      expect(
        find.descendant(
          of: inQuickBrew,
          matching: find.text('Ethiopia Guji Uraga'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('g/L'), findsNothing);
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('1:14')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('1:15')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inQuickBrew, matching: find.text('1:16')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Proporsi Air Panas vs Es Batu'),
        180,
        scrollable: qbScrollable,
      );
      expect(find.text('Es Duluan (Server)'), findsOneWidget);
      expect(find.text('Seduh Dulu → Es'), findsOneWidget);
      expect(find.text('70/30 · Bold'), findsOneWidget);
      expect(find.text('65/35 · Pas'), findsOneWidget);
      expect(find.text('60/40 · Dingin'), findsOneWidget);
      // Tapping 70/30 updates iceRatio to 0.30!
      await tester.tap(find.text('70/30 · Bold'));
      await tester.pumpAndSettle();
      expect(
        container.read(pocketStoreProvider).draft.iceRatio,
        closeTo(0.30, 0.01),
      );
    },
  );

  testWidgets(
    'Live Timer · clean Ready setup, sound pill, Drawdown overtime & Angkat Dripper flow',
    (tester) async {
      final env = await pumpApp(tester);
      final container = env.container;

      // Open Brew -> Launch Live Timer
      await tester.tap(find.text('Brew'));
      await tester.pumpAndSettle();
      final qbScrollable = find.descendant(
        of: find.byType(QuickBrewScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Mulai Brew'),
        220,
        scrollable: qbScrollable,
      );
      await tester.drag(qbScrollable, const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai Brew'));
      await tester.pumpAndSettle();

      // Pre-Brew Barista Checklist sheet ("Siap-siap Seduh") appears first!
      expect(find.text('Siap-siap Seduh'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
      expect(find.textContaining('Panaskan air ke'), findsOneWidget);
      expect(find.textContaining('Timbang kopi'), findsOneWidget);
      expect(find.textContaining('Giling di 21 klik'), findsOneWidget);
      // Check off step 1 -> button reflects progress
      await tester.tap(find.textContaining('Panaskan air ke'));
      await tester.pumpAndSettle();
      expect(find.text('Mulai Timer (1/5 siap)'), findsOneWidget);
      await tester.tap(find.text('Mulai Timer (1/5 siap)'));
      await tester.pumpAndSettle();

      final inTimer = find.byType(LiveTimerScreen);
      expect(inTimer, findsOneWidget);
      // Old 3-checkbox block MUST be gone!
      expect(find.text('Persiapan Cepat (Opsional)'), findsNothing);
      // Clean Setup Summary & vertical stages preview visible before start
      expect(find.text('Siap Seduh'), findsOneWidget);
      expect(
        find.descendant(
          of: inTimer,
          matching: find.text('Ethiopia Guji Uraga'),
        ),
        findsOneWidget,
      );
      expect(find.text('Alur Tuangan · 5 Tahap'), findsOneWidget);
      expect(find.text('50 ml dlm 12 dtk'), findsWidgets);
      expect(find.textContaining('g/s'), findsNothing);
      expect(find.text('Suara'), findsOneWidget);

      // Toggle sound pill off & on without errors
      await tester.tap(find.text('Suara'));
      await tester.pumpAndSettle();
      expect(find.text('Bisukan'), findsOneWidget);
      await tester.tap(find.text('Bisukan'));
      await tester.pumpAndSettle();
      expect(find.text('Suara'), findsOneWidget);

      // Start Timer -> launches 3-2-1 prep countdown first!
      await tester.tap(find.text('Mulai Timer Sekarang'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Bersiap Tuang...'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DualPhaseTimerRing),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(find.text('Lewati · Mulai Langsung'), findsOneWidget);

      // Tick 1 second -> 2, then tap Lewati to enter pouring stage 1 immediately
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.descendant(
          of: find.byType(DualPhaseTimerRing),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Lewati · Mulai Langsung'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Tuang · 1/5'), findsOneWidget);
      expect(find.text('TARGET TIMBANGAN'), findsOneWidget);
      expect(find.text('TUANG TAHAP INI'), findsOneWidget);
      expect(find.text('Pola: Spiral · Lihat Teknik'), findsOneWidget);
      expect(find.textContaining('50 ml / 12 dtk'), findsWidgets);
      expect(find.textContaining('Tuang 50 ml dlm 12 dtk'), findsOneWidget);
      expect(find.textContaining('g/s'), findsNothing);
      expect(find.text('Angkat Dripper · Selesai'), findsOneWidget);

      // Fast-forward past target drawdown (13 * 15s = 195s > 180s) ->
      // Timer MUST NOT auto-stop; must display drawdown overtime indicator!
      final timerScrollable = find.descendant(
        of: inTimer,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('+15d Lompat Cepat (Preview)'),
        260,
        scrollable: timerScrollable,
      );
      await tester.drag(timerScrollable, const Offset(0, -140));
      await tester.pump(const Duration(milliseconds: 50));
      for (int i = 0; i < 13; i++) {
        await tester.tap(find.text('+15d Lompat Cepat (Preview)'));
        await tester.pump(const Duration(milliseconds: 20));
      }
      // Scroll back to top to inspect the Dial overtime badge cleanly
      await tester.drag(timerScrollable, const Offset(0, 800));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Menetes · +'), findsOneWidget);

      // Press "Angkat Dripper · Selesai" -> navigates to EvaluationScreen with 0.5 rating & real Sliders!
      await tester.tap(find.text('Angkat Dripper · Selesai'));
      await tester.pumpAndSettle();
      expect(
        container.read(pocketStoreProvider).pendingEval?.actualDrawdownSec,
        greaterThanOrEqualTo(195),
      );
      expect(find.text('Seberapa enak cangkir ini?'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      await tester.tap(find.text('4.5'));
      await tester.pumpAndSettle();
      expect(find.text('★ 4.5 / 5.0'), findsOneWidget);
      expect(find.text('Karakter Rasa'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(4));
      expect(find.text('Simpan Log'), findsOneWidget);
      expect(find.textContaining('Golden'), findsNothing);
      expect(find.textContaining('-15g Stok'), findsNothing);

      // Open Roda Rasa SCA -> verify all 9 official SCA categories + search -> pick a note & apply
      await tester.tap(find.text('Roda Rasa'));
      await tester.pumpAndSettle();
      expect(find.text('Roda Rasa SCA'), findsOneWidget);
      expect(find.text('9 Kategori SCA'), findsOneWidget);
      expect(find.text('Fruity'), findsWidgets);
      expect(find.text('Sour/Ferm'), findsOneWidget);
      expect(find.text('Green/Herb'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      await tester.tap(find.textContaining('Terapkan'));
      await tester.pumpAndSettle();

      // CRITICAL BUG FIX CHECK: After returning from Roda Rasa, tapping a bean note MUST still toggle ON/OFF!
      final evalScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('White Peach ✓'),
        180,
        scrollable: evalScroll,
      );
      await tester.drag(evalScroll, const Offset(0, -160));
      await tester.pumpAndSettle();
      await tester.tap(find.text('White Peach ✓'));
      await tester.pumpAndSettle();
      expect(find.text('White Peach'), findsOneWidget);
      expect(find.text('White Peach ✓'), findsNothing);
      // Tap again to re-select it
      await tester.tap(find.text('White Peach'));
      await tester.pumpAndSettle();
      expect(find.text('White Peach ✓'), findsOneWidget);

      // Save Log -> navigates to BrewLogDetail with 4.5 rating & Brew Ulang Resep Ini CTA
      await tester.tap(find.text('Simpan Log'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Seduhan'), findsOneWidget);
      expect(find.text('★ 4.5'), findsOneWidget);
      expect(find.text('Brew Ulang Resep Ini'), findsOneWidget);
      expect(find.textContaining('Golden'), findsNothing);
    },
  );

  testWidgets(
    'Settings Save CTA, Add/Detail Kopi overhaul, BrewLog Hot/Iced split, Gear sticky setup & Belajar Seduh 9 topics',
    (tester) async {
      final env = await pumpApp(tester);
      final router = env.router;

      // 1. Settings screen has explicit Simpan CTA, Tes Suara, Hapus Data & Default Masa Paling Enak Kopi
      router.push('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Default Masa Paling Enak Kopi'), findsOneWidget);
      expect(find.text('Tes Suara'), findsOneWidget);
      expect(find.text('Simpan & Kembali'), findsOneWidget);
      final settingsScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Hapus Data'),
        200,
        scrollable: settingsScroll,
      );
      expect(find.text('Hapus Data'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('°F'),
        -240,
        scrollable: settingsScroll,
      );
      await tester.tap(find.text('°F'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan Pengaturan'), findsOneWidget);
      await tester.tap(find.text('Simpan Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // 2. Add Bean screen: structured Notes 1 / Notes 2 inputs (no comma separation!), single Berat Biji Saat Ini
      router.push('/beans/add');
      await tester.pumpAndSettle();
      expect(find.text('Metode Pasca Panen (Proses)'), findsOneWidget);
      expect(find.text('Anaerobic Natural'), findsOneWidget);
      expect(find.text('Wet-Hulled (Giling Basah)'), findsOneWidget);
      expect(find.text('Tingkat Sangrai (Roast)'), findsOneWidget);
      expect(find.text('g / oz'), findsNothing);
      expect(find.textContaining('Jeda'), findsNothing);
      expect(find.textContaining('Baru (Utuh)'), findsNothing);
      expect(find.textContaining('Sudah Terpakai'), findsNothing);
      expect(find.textContaining('seduhan lagi'), findsNothing);
      final addBeanScroll = find
          .descendant(
            of: find.byType(AddBeanScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Berat Kopi Saat Ini'),
        220,
        scrollable: addBeanScroll,
      );
      expect(find.text('Berat Kopi Saat Ini'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Atur Sendiri'),
        220,
        scrollable: addBeanScroll,
      );
      await tester.drag(addBeanScroll, const Offset(0, -140));
      await tester.pumpAndSettle();
      expect(find.text('Tanggal Sangrai & Masa Paling Enak'), findsOneWidget);
      expect(find.textContaining('Peak'), findsNothing);
      expect(find.text('Stok Cadangan'), findsOneWidget);
      await tester.tap(find.text('Atur Sendiri'));
      await tester.pumpAndSettle();
      expect(find.text('Mulai Enak'), findsOneWidget);
      expect(find.text('Sampai Hari'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Notes Rasa Kemasan'),
        220,
        scrollable: addBeanScroll,
      );
      expect(find.text('Notes Rasa Kemasan'), findsOneWidget);
      expect(find.text('Notes 1'), findsOneWidget);
      expect(find.text('Notes 2'), findsOneWidget);
      expect(find.text('+ Tambah Note'), findsOneWidget);
      expect(find.textContaining('pisahkan koma'), findsNothing);
      router.pop();
      await tester.pumpAndSettle();

      // 3. Detail Kopi: flexible stock input, Umur Sangrai (NO Klik Andalan!), Seduh Kopi Ini, Hapus Kopi & NO Archive!
      router.push('/beans/bean-ethiopia-guji');
      await tester.pumpAndSettle();
      expect(find.text('Detail Kopi'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Umur Sangrai'), findsOneWidget);
      expect(find.text('Klik Andalan'), findsNothing);
      expect(find.text('Koreksi Sisa Stok Aktual'), findsOneWidget);
      expect(find.text('Arsipkan Biji'), findsNothing);
      expect(find.textContaining('Arsip'), findsNothing);
      // Enter custom flexible decimal stock value (e.g. 142.5)
      await tester.enterText(find.byType(TextField).first, '142.5');
      await tester.pumpAndSettle();
      expect(find.text('Simpan Koreksi Stok (142.5g)'), findsOneWidget);
      final beanDetailScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Hapus Kopi'),
        220,
        scrollable: beanDetailScroll,
      );
      await tester.drag(beanDetailScroll, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('Seduh Kopi Ini'), findsOneWidget);
      expect(find.text('Simpan Cadangan'), findsOneWidget);
      expect(find.text('Hapus Kopi'), findsOneWidget);
      // Tapping Hapus Kopi opens confirmation dialog!
      await tester.tap(find.text('Hapus Kopi'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Biji Kopi?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // 4. Belajar Seduh has all 9 pro-standard topics (including Ensiklopedia Biji Kopi, Japanese Iced, Grinder & Roda Rasa!)
      router.push('/learn');
      await tester.pumpAndSettle();
      expect(find.text('9 Materi'), findsOneWidget);
      expect(find.text('Ensiklopedia Biji Kopi (Wajib Baca)'), findsOneWidget);
      expect(find.text('Ilmu Ekstraksi & Rasio Emas (SCA)'), findsOneWidget);
      // Open Ensiklopedia Biji Kopi (/learn/beans) & verify interactive Roast tabs + 5 Processes!
      router.push('/learn/beans');
      await tester.pumpAndSettle();
      expect(find.text('Ensiklopedia Biji Kopi'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(find.text('84°C – 89°C'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      // Open Japanese Iced Pro (/learn/iced) & verify interactive 70/30 vs 60/40 simulator
      router.push('/learn/iced');
      await tester.pumpAndSettle();
      expect(find.text('Japanese Iced Pro'), findsOneWidget);
      await tester.tap(find.text('60/40 Segar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Air Panas 150 ml (60%)'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      // Open Roda Rasa Kopi (/learn/wheel) & verify 9 SCA categories + search
      router.push('/learn/wheel');
      await tester.pumpAndSettle();
      expect(find.text('Roda Rasa Kopi'), findsOneWidget);
      expect(find.textContaining('9 Kategori ·'), findsOneWidget);
      expect(find.text('Fruity'), findsWidgets);
      expect(find.text('Floral'), findsWidgets);
      expect(find.text('Sweet'), findsWidgets);
      await tester.enterText(find.byType(TextField).first, 'Peach');
      await tester.pumpAndSettle();
      expect(find.textContaining('Hasil Pencarian'), findsOneWidget);
      expect(find.text('Peach'), findsWidgets);
      router.pop();
      await tester.pumpAndSettle();
      // Open Teknik Tuang (/learn/pour) & verify all 5 pour techniques
      router.push('/learn/pour');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Teknik Penuangan'), findsOneWidget);
      expect(find.text('Spiral'), findsWidgets);
      expect(find.text('Center'), findsWidgets);
      expect(find.text('Pulse'), findsWidgets);
      expect(find.text('Osmotic'), findsWidgets);
      expect(find.text('Swirl'), findsWidgets);
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // 5. Brew Log differentiates Hot V60 vs Japanese Iced (with Air Panas + Es Split Bar!) & has Filter sheet
      router.go('/log');
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Seduhan'), findsOneWidget);
      expect(find.text('Favorit Hot V60'), findsNothing);
      expect(find.text('Favorit Japanese'), findsNothing);
      expect(find.text('Filter'), findsOneWidget);
      // Seeded Japanese Iced log displays clear Hot Water vs Ice Split Bar!
      expect(find.textContaining('Air Panas'), findsWidgets);
      expect(find.textContaining('Teknik:'), findsWidgets);
      // Open Bottom Sheet Filter -> pick Japanese Iced -> apply -> verify active count & Reset
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      expect(find.text('Filter Riwayat Seduhan'), findsOneWidget);
      await tester.tap(find.text('Japanese Iced').last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Terapkan · Lihat'));
      await tester.pumpAndSettle();
      expect(find.text('Filter (1)'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Filter'), findsOneWidget);

      // 6. Alat Seduh: Pinned 3-slot Setup Aktif Saya, Otomatis tersimpan, ZERO Simpan Setup Aktif button!
      router.go('/gear');
      await tester.pumpAndSettle();
      expect(find.text('Alat Seduh'), findsOneWidget);
      expect(find.text('Setup Aktif Saya'), findsOneWidget);
      expect(find.text('Otomatis tersimpan'), findsOneWidget);
      expect(find.text('Koleksi Alat Seduh'), findsOneWidget);
      expect(find.text('Dipakai'), findsWidgets);
      expect(find.textContaining('Simpan Setup Aktif'), findsNothing);
      expect(find.text('Meja Rumah'), findsNothing);
      expect(find.text('Kantor'), findsNothing);
      expect(find.text('Travel'), findsNothing);
      await tester.tap(find.text('Tambah').first);
      await tester.pumpAndSettle();
      expect(find.text('Tambah Alat Sendiri'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Mavo Phantox');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan & Aktifkan Alat'));
      await tester.pumpAndSettle();
      expect(find.text('Mavo Phantox'), findsWidgets);
      expect(find.text('Alat Saya'), findsWidgets);

      // 7. Edit Tahapan: symmetric ratio, NO "Otomatis", NO "Saran Gilingan", custom Ice grams, non-auto-redistributing stages!
      router.push('/brew/stages');
      await tester.pumpAndSettle();
      expect(find.text('Nama & Parameter Preset'), findsOneWidget);
      expect(find.text('Rasio (1:xx)'), findsOneWidget);
      expect(find.text('Suhu Air'), findsOneWidget);
      expect(find.textContaining('Total Air:'), findsOneWidget);
      expect(find.textContaining('Otomatis'), findsNothing);
      expect(find.textContaining('Saran Gilingan'), findsNothing);
      expect(find.text('Bagi Rata'), findsOneWidget);

      // Test symmetric ratio stepping: start 1:16.7 -> minus -> 1:16.2 -> plus -> 1:16.7!
      expect(find.text('1:16.7'), findsOneWidget);
      final ratioMinus = find.text('−').at(1);
      final ratioPlus = find.text('+').at(1);
      await tester.tap(ratioMinus);
      await tester.pumpAndSettle();
      expect(find.text('1:16.2'), findsOneWidget);
      await tester.tap(ratioPlus);
      await tester.pumpAndSettle();
      expect(find.text('1:16.7'), findsOneWidget);

      // Test adding a stage starts at 0 ml WITHOUT redistributing existing stage 1 (still +50 ml)
      // AND exposes Judul Tahap rename field!
      final stagesScroll = find
          .descendant(
            of: find.byType(PourStageEditorScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Tambah Tahap Tuangan'),
        240,
        scrollable: stagesScroll,
      );
      await tester.drag(stagesScroll, const Offset(0, -140));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Tahap Tuangan'));
      await tester.pumpAndSettle();
      expect(find.text('+0 ml'), findsOneWidget);
      expect(find.text('+50 ml'), findsWidgets);
      expect(find.text('Judul Tahap 6'), findsOneWidget);

      // Test Info Pola modal inside Pour Stage Editor!
      await tester.scrollUntilVisible(
        find.text('Info Pola').first,
        240,
        scrollable: stagesScroll,
      );
      await tester.tap(find.text('Info Pola').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Panduan Teknik Tuangan'), findsOneWidget);
      expect(find.text('Cara Melakukan Teknik Ini'), findsOneWidget);
      await tester.tap(find.text('Paham · Tutup Panduan'));
      await tester.pumpAndSettle();

      // Switch to Japanese Iced -> custom Es Batu grams visible!
      await tester.drag(stagesScroll, const Offset(0, 900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japanese Iced'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Es Batu:'), findsOneWidget);
    },
  );

  testWidgets('BrewLog lazy pagination shows Muat Lebih Banyak when > 15 logs', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    final notifier = env.container.read(pocketStoreProvider.notifier);

    // Seed 16 additional logs (total 20 > pageSize 15)
    for (int i = 0; i < 16; i++) {
      notifier.saveEvaluatedBrew(
        feeling: TasteFeeling.balancedSweet,
        rating: 4.5,
        bars: const FlavorBars(),
        tags: const ['Sweet'],
        notes: 'Batch test $i',
        isGolden: false,
        applyRecommendedClickForTomorrow: false,
        recommendedClick: 21,
        recommendedTempC: 94,
        deductBeanStock: false,
      );
    }

    env.router.go('/log');
    await tester.pumpAndSettle();
    final logScrollable = find.descendant(
      of: find.byType(BrewLogScreen),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      find.text('Muat Lebih Banyak (+15)'),
      260,
      scrollable: logScrollable,
    );
    await tester.drag(logScrollable, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 15 dari 20 seduhan'), findsOneWidget);
    await tester.tap(find.text('Muat Lebih Banyak (+15)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Menampilkan 20 dari 20 seduhan'),
      260,
      scrollable: logScrollable,
    );
    expect(find.text('Menampilkan 20 dari 20 seduhan'), findsOneWidget);
    expect(find.text('Muat Lebih Banyak (+15)'), findsNothing);
  });

  testWidgets(
    'Row 1 & Live Timer responsive (360dp narrow) & Espresso Dusk Dark Mode render with zero overflow',
    (tester) async {
      final env = await pumpApp(tester, size: const Size(360, 800));
      final container = env.container;
      final router = env.router;

      container.read(pocketStoreProvider.notifier).setThemePref(AppThemePref.dark);
      await tester.pumpAndSettle();

      // 02 Home Dark @ 360dp
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 04 Brew Hot Dark @ 360dp
      await tester.tap(find.text('Brew'));
      await tester.pumpAndSettle();
      expect(find.byType(QuickBrewScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 05 Brew Iced Dark @ 360dp
      await tester.tap(find.descendant(
        of: find.byType(QuickBrewScreen),
        matching: find.text('Japanese Iced'),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Add Bean + Bean Detail + Add Custom Gear (all 3 tabs) + Brew Log Dark @ 360dp
      router.push('/beans/add');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      router.push('/beans/bean-ethiopia-guji');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      router.push('/gear/add-custom');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Dripper'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      router.go('/log');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      router.go('/gear');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // SCA Wheel Dark @ 360dp
      router.push('/evaluation/wheel');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      // Live Timer Dark @ 360dp (Ready AND Running states!)
      router.push('/timer');
      await tester.pumpAndSettle();
      expect(find.byType(LiveTimerScreen), findsOneWidget);
      final timerErr = tester.takeException();
      expect(timerErr, isNull, reason: 'LiveTimer Ready 360dp error: $timerErr');
      await tester.tap(find.text('Mulai Timer Sekarang'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Lewati · Mulai Langsung'));
      await tester.pump(const Duration(milliseconds: 80));
      final timerRunErr = tester.takeException();
      expect(
        timerRunErr,
        isNull,
        reason: 'LiveTimer Running 360dp error: $timerRunErr',
      );
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // Pour Stage Editor Dark @ 360dp
      router.push('/brew/stages');
      await tester.pumpAndSettle();
      final stageDarkScroll = find
          .descendant(
            of: find.byType(PourStageEditorScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Kecepatan & Durasi Tuangan'),
        220,
        scrollable: stageDarkScroll,
      );
      expect(find.text('Kecepatan & Durasi Tuangan'), findsOneWidget);
      expect(find.textContaining('g/s'), findsNothing);
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      // Evaluation Dark @ 360dp
      router.push('/evaluation');
      await tester.pumpAndSettle();
      expect(find.text('Simpan Log'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      // Settings Dark @ 360dp
      router.push('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Simpan & Kembali'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      // Learn Hub + ALL 9 topics Dark @ 360dp
      router.push('/learn');
      await tester.pumpAndSettle();
      expect(find.text('9 Materi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final route in [
        '/learn/beans',
        '/learn/basics',
        '/learn/troubleshoot',
        '/learn/iced',
        '/learn/water',
        '/learn/dripper',
        '/learn/grinder',
        '/learn/wheel',
      ]) {
        router.push(route);
        await tester.pumpAndSettle();
        final err = tester.takeException();
        expect(err, isNull, reason: 'Dark 360dp error on $route: $err');
        router.pop();
        await tester.pumpAndSettle();
      }
      router.push('/learn/pour');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Teknik Penuangan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // BrewLogDetail for Japanese Iced Dark @ 360dp
      final icedLog = container
          .read(pocketStoreProvider)
          .logs
          .where((l) => l.mode == BrewMode.iced)
          .firstOrNull;
      if (icedLog != null) {
        router.push('/log/${icedLog.id}');
        await tester.pumpAndSettle();
        expect(find.textContaining('Air Panas'), findsOneWidget);
        expect(find.textContaining('Teknik:'), findsOneWidget);
        expect(tester.takeException(), isNull);
        router.pop();
        await tester.pumpAndSettle();
      }

      // 03 Methods Dark @ 360dp
      router.push('/methods');
      await tester.pumpAndSettle();
      expect(find.byType(MethodsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 01 Onboarding Dark @ 360dp
      router.go('/onboarding');
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'v1.0.2 features: Brew session stage add/reset, Methods delete+restore, Settings clear data & Light 360dp zero overflow',
    (tester) async {
      final env = await pumpApp(tester, size: const Size(360, 800));
      final container = env.container;
      final router = env.router;

      // Verify Light Mode @ 360dp zero overflow on Home, Brew, Beans, Log, Gear
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 1. Brew Screen: inline session stage add & reset (outside preset!)
      router.go('/brew');
      await tester.pumpAndSettle();
      final qbScrollable = find.descendant(
        of: find.byType(QuickBrewScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Tambah Tahap (Sesi Ini)'),
        220,
        scrollable: qbScrollable,
      );
      await tester.drag(qbScrollable, const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Tahap (Sesi Ini)'));
      await tester.pumpAndSettle();
      expect(find.text('Tambah Tahap 6 (Sesi Ini)'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Tuangan Bonus');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambahkan Tahap'));
      await tester.pumpAndSettle();

      expect(find.text('Tuangan Bonus'), findsOneWidget);
      expect(find.text('Tahap diubah sesi ini'), findsOneWidget);
      expect(container.read(pocketStoreProvider).currentPlan.stages.length, 6);
      // Original saved preset recipe must remain untouched at 5 stages!
      expect(container.read(pocketStoreProvider).activeRecipe.stages.length, 5);
      // Reset preset restores back to 5 stages
      await tester.drag(qbScrollable, const Offset(0, 320));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reset preset'));
      await tester.tap(find.text('Reset preset'));
      await tester.pumpAndSettle();
      expect(container.read(pocketStoreProvider).currentPlan.stages.length, 5);
      expect(find.text('Tahap diubah sesi ini'), findsNothing);

      // 2. Koleksi Kopi has 2 tabs (Aktif & Cadangan), ZERO Arsip & ZERO grinder "klik" text!
      router.go('/beans');
      await tester.pumpAndSettle();
      expect(find.text('Koleksi Kopi'), findsOneWidget);
      expect(find.textContaining('Aktif ('), findsOneWidget);
      expect(find.textContaining('Cadangan ('), findsOneWidget);
      expect(find.textContaining('Arsip'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BeanLibraryScreen),
          matching: find.textContaining('klik'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      // 3. Methods screen: delete an official recipe with confirmation modal
      //    and verify NO inline restore button in Methods/Gear — restore is centralized in Settings!
      router.push('/methods');
      await tester.pumpAndSettle();
      final beforeCount = container.read(pocketStoreProvider).recipes.length;
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Hapus Metode Resep?'), findsOneWidget);
      await tester.tap(find.text('Hapus Resep'));
      await tester.pumpAndSettle();
      expect(
        container.read(pocketStoreProvider).recipes.length,
        beforeCount - 1,
      );
      expect(find.text('Pulihkan Resep Bawaan yang Dihapus'), findsNothing);
      router.pop();
      await tester.pumpAndSettle();

      // Verify GearScreen also has NO inline restore button
      router.go('/gear');
      await tester.pumpAndSettle();
      expect(find.text('Pulihkan Alat Bawaan yang Dihapus'), findsNothing);
      expect(tester.takeException(), isNull);

      // 4. Settings: Centralized "Pulihkan Preset Bawaan Aplikasi" shows exact count & restores cleanly
      router.push('/settings');
      await tester.pumpAndSettle();
      final settingsScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Pulihkan Preset Bawaan Aplikasi'),
        220,
        scrollable: settingsScroll,
      );
      await tester.drag(settingsScroll, const Offset(0, -140));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Pulihkan (1)'), findsOneWidget);
      await tester.tap(find.text('Pulihkan (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Pulihkan Preset Bawaan?'), findsOneWidget);
      expect(
        find.textContaining('1 Resep Profesional bawaan'),
        findsOneWidget,
      );
      await tester.tap(find.text('Pulihkan').last);
      await tester.pumpAndSettle();
      expect(container.read(pocketStoreProvider).recipes.length, beforeCount);
      expect(find.text('Lengkap ✓'), findsOneWidget);
      // Let restore SnackBar auto-dismiss so bottom buttons aren't occluded
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // 5. Light Mode @ 360dp zero overflow on /learn/wheel & Running LiveTimerScreen
      router.push('/learn/wheel');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();

      router.push('/timer');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai Timer Sekarang'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Lewati · Mulai Langsung'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // 6. Settings: Hapus Data wipes beans & logs cleanly after confirmation & returns to Setup Awal
      await tester.scrollUntilVisible(
        find.text('Hapus Data'),
        220,
        scrollable: settingsScroll,
      );
      await tester.drag(settingsScroll, const Offset(0, -240));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Data'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Semua Data Lokal?'), findsOneWidget);
      await tester.tap(find.text('Ya, Hapus Semua'));
      await tester.pumpAndSettle();
      expect(container.read(pocketStoreProvider).beans, isEmpty);
      expect(container.read(pocketStoreProvider).logs, isEmpty);
      expect(container.read(pocketStoreProvider).prefs.onboarded, isFalse);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
