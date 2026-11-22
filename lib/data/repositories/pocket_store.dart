import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/engines/delta_micron_grinder_engine.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../local/catalog_loader.dart';
import '../local/pocket_storage.dart';

const _uuid = Uuid();

class ActiveBrewDraft {
  const ActiveBrewDraft({
    required this.recipeId,
    required this.beanId,
    required this.mode,
    required this.icedMethod,
    required this.doseG,
    required this.ratio,
    required this.iceRatio,
    required this.clickSetting,
    required this.tempC,
    this.sessionStages,
  });

  final String recipeId;
  final String? beanId;
  final BrewMode mode;
  final IcedMethod icedMethod;
  final double doseG;
  final double ratio;
  final double iceRatio;
  final int clickSetting;
  final int tempC;
  final List<PourStage>? sessionStages;

  ActiveBrewDraft copyWith({
    String? recipeId,
    String? beanId,
    bool clearBean = false,
    BrewMode? mode,
    IcedMethod? icedMethod,
    double? doseG,
    double? ratio,
    double? iceRatio,
    int? clickSetting,
    int? tempC,
    List<PourStage>? sessionStages,
    bool clearSessionStages = false,
  }) =>
      ActiveBrewDraft(
        recipeId: recipeId ?? this.recipeId,
        beanId: clearBean ? null : (beanId ?? this.beanId),
        mode: mode ?? this.mode,
        icedMethod: icedMethod ?? this.icedMethod,
        doseG: doseG ?? this.doseG,
        ratio: ratio ?? this.ratio,
        iceRatio: iceRatio ?? this.iceRatio,
        clickSetting: clickSetting ?? this.clickSetting,
        tempC: tempC ?? this.tempC,
        sessionStages: clearSessionStages
            ? null
            : (sessionStages ?? this.sessionStages),
      );
}

class PendingEvaluation {
  const PendingEvaluation({
    required this.beanId,
    required this.beanName,
    required this.recipeId,
    required this.recipeName,
    required this.mode,
    required this.icedMethod,
    required this.grinderId,
    required this.grinderName,
    required this.clickSetting,
    required this.tempC,
    required this.doseG,
    required this.totalLiquidG,
    required this.hotWaterG,
    required this.iceG,
    required this.targetDrawdownSec,
    required this.actualDrawdownSec,
    required this.stageSnapshots,
    this.selectedTags = const [],
  });

  final String? beanId;
  final String beanName;
  final String recipeId;
  final String recipeName;
  final BrewMode mode;
  final IcedMethod icedMethod;
  final String grinderId;
  final String grinderName;
  final int clickSetting;
  final int tempC;
  final double doseG;
  final double totalLiquidG;
  final double hotWaterG;
  final double iceG;
  final int targetDrawdownSec;
  final int actualDrawdownSec;
  final List<String> stageSnapshots;
  final List<String> selectedTags;

  PendingEvaluation copyWith({List<String>? selectedTags}) => PendingEvaluation(
        beanId: beanId,
        beanName: beanName,
        recipeId: recipeId,
        recipeName: recipeName,
        mode: mode,
        icedMethod: icedMethod,
        grinderId: grinderId,
        grinderName: grinderName,
        clickSetting: clickSetting,
        tempC: tempC,
        doseG: doseG,
        totalLiquidG: totalLiquidG,
        hotWaterG: hotWaterG,
        iceG: iceG,
        targetDrawdownSec: targetDrawdownSec,
        actualDrawdownSec: actualDrawdownSec,
        stageSnapshots: stageSnapshots,
        selectedTags: selectedTags ?? this.selectedTags,
      );
}

class PocketAppState {
  const PocketAppState({
    required this.isLoaded,
    required this.prefs,
    required this.grinders,
    required this.drippers,
    required this.filters,
    required this.profiles,
    required this.activeProfileId,
    required this.recipes,
    required this.beans,
    required this.logs,
    required this.guides,
    required this.draft,
    this.pendingEval,
    this.deletedGrinderIds = const <String>{},
    this.deletedDripperIds = const <String>{},
    this.deletedFilterIds = const <String>{},
    this.deletedRecipeIds = const <String>{},
  });

  final bool isLoaded;
  final UserPrefs prefs;
  final List<GrinderSpec> grinders;
  final List<DripperSpec> drippers;
  final List<FilterSpec> filters;
  final List<GearProfile> profiles;
  final String activeProfileId;
  final List<BrewRecipe> recipes;
  final List<CoffeeBean> beans;
  final List<BrewLog> logs;
  final List<LearnGuide> guides;
  final ActiveBrewDraft draft;
  final PendingEvaluation? pendingEval;
  final Set<String> deletedGrinderIds;
  final Set<String> deletedDripperIds;
  final Set<String> deletedFilterIds;
  final Set<String> deletedRecipeIds;

  bool get hasDeletedOfficialGear =>
      deletedGrinderIds.isNotEmpty ||
      deletedDripperIds.isNotEmpty ||
      deletedFilterIds.isNotEmpty;

  bool get hasDeletedOfficialRecipes => deletedRecipeIds.isNotEmpty;

  bool get hasAnyDeletedOfficialItems =>
      hasDeletedOfficialGear || hasDeletedOfficialRecipes;

  int get totalDeletedOfficialCount =>
      deletedGrinderIds.length +
      deletedDripperIds.length +
      deletedFilterIds.length +
      deletedRecipeIds.length;

  bool get hasSessionStageOverrides => draft.sessionStages != null;

  int get activeTargetDrawdownSec =>
      (draft.sessionStages != null && draft.sessionStages!.isNotEmpty)
          ? draft.sessionStages!.last.endSec
          : activeRecipe.targetDrawdownSec;

  GearProfile get activeProfile => profiles.firstWhere(
        (p) => p.id == activeProfileId,
        orElse: () => profiles.first,
      );

  GrinderSpec get activeGrinder => grinders.firstWhere(
        (g) => g.id == activeProfile.grinderId,
        orElse: () => grinders.first,
      );

  DripperSpec get activeDripper => drippers.firstWhere(
        (d) => d.id == activeProfile.dripperId,
        orElse: () => drippers.first,
      );

  FilterSpec get activeFilter => filters.firstWhere(
        (f) => f.id == activeProfile.filterId,
        orElse: () => filters.first,
      );

  BrewRecipe get activeRecipe => recipes.firstWhere(
        (r) => r.id == draft.recipeId,
        orElse: () => recipes.first,
      );

  CoffeeBean? get activeBean {
    if (draft.beanId == null) return null;
    for (final b in beans) {
      if (b.id == draft.beanId) return b;
    }
    return null;
  }

  ScaledBrewPlan get currentPlan => BrewRecipeScaler.scale(
        recipe: activeRecipe,
        doseG: draft.doseG,
        ratio: draft.ratio,
        mode: draft.mode,
        iceRatio: draft.iceRatio,
        icedMethod: draft.icedMethod,
        overrideTempC: draft.tempC,
        overrideStages: draft.sessionStages,
      );

  PocketAppState copyWith({
    bool? isLoaded,
    UserPrefs? prefs,
    List<GrinderSpec>? grinders,
    List<DripperSpec>? drippers,
    List<FilterSpec>? filters,
    List<GearProfile>? profiles,
    String? activeProfileId,
    List<BrewRecipe>? recipes,
    List<CoffeeBean>? beans,
    List<BrewLog>? logs,
    List<LearnGuide>? guides,
    ActiveBrewDraft? draft,
    PendingEvaluation? pendingEval,
    bool clearPendingEval = false,
    Set<String>? deletedGrinderIds,
    Set<String>? deletedDripperIds,
    Set<String>? deletedFilterIds,
    Set<String>? deletedRecipeIds,
  }) =>
      PocketAppState(
        isLoaded: isLoaded ?? this.isLoaded,
        prefs: prefs ?? this.prefs,
        grinders: grinders ?? this.grinders,
        drippers: drippers ?? this.drippers,
        filters: filters ?? this.filters,
        profiles: profiles ?? this.profiles,
        activeProfileId: activeProfileId ?? this.activeProfileId,
        recipes: recipes ?? this.recipes,
        beans: beans ?? this.beans,
        logs: logs ?? this.logs,
        guides: guides ?? this.guides,
        draft: draft ?? this.draft,
        pendingEval:
            clearPendingEval ? null : (pendingEval ?? this.pendingEval),
        deletedGrinderIds: deletedGrinderIds ?? this.deletedGrinderIds,
        deletedDripperIds: deletedDripperIds ?? this.deletedDripperIds,
        deletedFilterIds: deletedFilterIds ?? this.deletedFilterIds,
        deletedRecipeIds: deletedRecipeIds ?? this.deletedRecipeIds,
      );
}

final pocketStorageProvider = Provider<PocketStorage>((_) => PocketStorage());

final pocketStoreProvider =
    NotifierProvider<PocketStoreNotifier, PocketAppState>(
  PocketStoreNotifier.new,
);

class PocketStoreNotifier extends Notifier<PocketAppState> {
  Timer? _persistDebounce;

  @override
  PocketAppState build() {
    ref.onDispose(() {
      _persistDebounce?.cancel();
    });
    Future.microtask(_init);
    return _placeholderState();
  }

  PocketAppState _placeholderState() {
    const defaultGrinder = GrinderSpec(
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
      zeroPointNote: 'Burr rapat ringan',
      burrSpec: '38mm High-Nitrogen Steel',
    );
    const defaultDripper = DripperSpec(
      id: 'hario-v60-02-plastic',
      name: 'Hario V60-02 Plastik',
      geometry: 'Cone 60°',
      material: 'AS Resin',
      capacityG: '15–30g',
      flowNote: 'Panas stabil',
    );
    const defaultFilter = FilterSpec(
      id: 'hario-vcf-02w-japan',
      name: 'Hario VCF-02W Japan Tabbed',
      speed: 'Sedang',
      grindOffsetUm: 0,
      note: 'Standar V60 harian',
    );
    const defaultRecipe = BrewRecipe(
      id: 'hoffmann-1cup-hot',
      name: 'James Hoffmann · Better 1-Cup',
      author: 'James Hoffmann',
      mode: BrewMode.hot,
      badge: 'Hot V60',
      isOfficial: true,
      summary: '5 tuangan merata, bersih & manis.',
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
          label: 'Bloom + Swirl',
          startSec: 0,
          pourEndSec: 12,
          endSec: 45,
          targetCumulativePct: 0.2,
          pattern: PourPattern.spiral,
          rate: PourRate.medium,
          cue: 'Basahi bubuk rata lalu swirl lembut.',
        ),
        PourStage(
          order: 2,
          label: 'Tuangan Utama',
          startSec: 45,
          pourEndSec: 90,
          endSec: 180,
          targetCumulativePct: 1.0,
          pattern: PourPattern.spiral,
          rate: PourRate.medium,
          cue: 'Tuang spiral stabil hingga selesai.',
        ),
      ],
    );
    return const PocketAppState(
      isLoaded: false,
      prefs: UserPrefs(),
      grinders: [defaultGrinder],
      drippers: [defaultDripper],
      filters: [defaultFilter],
      profiles: [
        GearProfile(
          id: 'home-bar',
          name: 'Meja Rumah',
          grinderId: 'comandante-c40-mk4',
          dripperId: 'hario-v60-02-plastic',
          filterId: 'hario-vcf-02w-japan',
          kettleNote: 'Gooseneck PID · Air Sedang',
        ),
      ],
      activeProfileId: 'home-bar',
      recipes: [defaultRecipe],
      beans: [],
      logs: [],
      guides: [],
      draft: ActiveBrewDraft(
        recipeId: 'hoffmann-1cup-hot',
        beanId: null,
        mode: BrewMode.hot,
        icedMethod: IcedMethod.iceFirst,
        doseG: 15.0,
        ratio: 16.67,
        iceRatio: 0.40,
        clickSetting: 21,
        tempC: 94,
      ),
    );
  }

  List<T> _parseListSafe<T>(
    dynamic rawList,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (rawList is! List) return const [];
    final out = <T>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        try {
          out.add(fromJson(item));
        } catch (_) {
          // Skip only the single malformed item; preserve all other user records.
        }
      }
    }
    return out;
  }

  Future<void> _init() async {
    final catalog = await CatalogLoader.loadBundled();
    final storage = ref.read(pocketStorageProvider);
    final saved = await storage.readState();

    if (saved != null) {
      UserPrefs prefs = const UserPrefs(onboarded: true);
      try {
        if (saved['prefs'] is Map<String, dynamic>) {
          prefs = UserPrefs.fromJson(saved['prefs'] as Map<String, dynamic>);
        }
      } catch (_) {}

      final deletedGrinderIds =
          (saved['deleted_grinder_ids'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toSet();
      final deletedDripperIds =
          (saved['deleted_dripper_ids'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toSet();
      final deletedFilterIds =
          (saved['deleted_filter_ids'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toSet();
      final deletedRecipeIds =
          (saved['deleted_recipe_ids'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toSet();

      final customGrinders =
          _parseListSafe(saved['custom_grinders'], GrinderSpec.fromJson);
      final customDrippers =
          _parseListSafe(saved['custom_drippers'], DripperSpec.fromJson);
      final customFilters =
          _parseListSafe(saved['custom_filters'], FilterSpec.fromJson);
      final customRecipes =
          _parseListSafe(saved['custom_recipes'], BrewRecipe.fromJson);
      final profiles = _parseListSafe(saved['profiles'], GearProfile.fromJson);
      final beans = _parseListSafe(saved['beans'], CoffeeBean.fromJson);
      final logs = _parseListSafe(saved['logs'], BrewLog.fromJson);
      final activeProfileId =
          saved['active_profile_id'] as String? ?? 'home-bar';
      final mergedRecipes = [
        ...catalog.recipes.where((r) => !deletedRecipeIds.contains(r.id)),
        ...customRecipes,
      ];
      final allRecipes =
          mergedRecipes.isEmpty ? [catalog.recipes.first] : mergedRecipes;
      final activeBean = beans.where((b) => !b.isFrozen).firstOrNull ??
          beans.firstOrNull;

      final mergedGrinders = [
        ...catalog.grinders.where((g) => !deletedGrinderIds.contains(g.id)),
        ...customGrinders,
      ];
      final mergedDrippers = [
        ...catalog.drippers.where((d) => !deletedDripperIds.contains(d.id)),
        ...customDrippers,
      ];
      final mergedFilters = [
        ...catalog.filters.where((f) => !deletedFilterIds.contains(f.id)),
        ...customFilters,
      ];

      state = PocketAppState(
        isLoaded: true,
        prefs: prefs,
        grinders:
            mergedGrinders.isEmpty ? [catalog.grinders.first] : mergedGrinders,
        drippers:
            mergedDrippers.isEmpty ? [catalog.drippers.first] : mergedDrippers,
        filters:
            mergedFilters.isEmpty ? [catalog.filters.first] : mergedFilters,
        profiles: profiles.isEmpty ? _defaultProfiles() : profiles,
        activeProfileId: activeProfileId,
        recipes: allRecipes,
        beans: beans,
        logs: logs,
        guides: catalog.guides,
        deletedGrinderIds: deletedGrinderIds,
        deletedDripperIds: deletedDripperIds,
        deletedFilterIds: deletedFilterIds,
        deletedRecipeIds: deletedRecipeIds,
        draft: ActiveBrewDraft(
          recipeId: allRecipes.first.id,
          beanId: activeBean?.id,
          mode: allRecipes.first.mode,
          icedMethod: IcedMethod.iceFirst,
          doseG: allRecipes.first.doseG,
          ratio: allRecipes.first.ratio,
          iceRatio: 0.40,
          clickSetting: activeBean?.preferredHotClick ?? 21,
          tempC: allRecipes.first.tempC,
        ),
      );
      return;
    }

    final seededBeans = _seedDemoBeans();
    final seededLogs = _seedDemoLogs();
    final seededProfiles = _defaultProfiles();

    state = PocketAppState(
      isLoaded: true,
      prefs: const UserPrefs(onboarded: false),
      grinders: catalog.grinders,
      drippers: catalog.drippers,
      filters: catalog.filters,
      profiles: seededProfiles,
      activeProfileId: seededProfiles.first.id,
      recipes: catalog.recipes,
      beans: seededBeans,
      logs: seededLogs,
      guides: catalog.guides,
      draft: ActiveBrewDraft(
        recipeId: catalog.recipes.first.id,
        beanId: seededBeans.first.id,
        mode: BrewMode.hot,
        icedMethod: IcedMethod.iceFirst,
        doseG: 15.0,
        ratio: 16.67,
        iceRatio: 0.40,
        clickSetting: 21,
        tempC: 94,
      ),
    );
    await _persist();
  }

  List<GearProfile> _defaultProfiles() => const [
        GearProfile(
          id: 'home-bar',
          name: 'Meja Rumah',
          grinderId: 'comandante-c40-mk4',
          dripperId: 'hario-v60-02-plastic',
          filterId: 'hario-vcf-02w-japan',
          kettleNote: 'Gooseneck PID · Air Sedang (65 ppm)',
        ),
        GearProfile(
          id: 'office-bar',
          name: 'Kantor',
          grinderId: '1zpresso-k-ultra',
          dripperId: 'kalita-wave-185',
          filterId: 'cafec-abaca-02',
          kettleNote: 'Kettle Listrik · Air Kemasan',
        ),
        GearProfile(
          id: 'travel-bar',
          name: 'Travel',
          grinderId: 'timemore-chestnut-s3',
          dripperId: 'origami-m',
          filterId: 'cafec-t90',
          kettleNote: 'Pouring Spout Portable',
        ),
      ];

  List<CoffeeBean> _seedDemoBeans() {
    final now = DateTime.now();
    return [
      CoffeeBean(
        id: 'bean-ethiopia-guji',
        name: 'Ethiopia Guji Uraga',
        roastery: 'Fuglen Roasters',
        origin: 'Guji, Ethiopia',
        process: 'Washed',
        roastLevel: RoastLevel.light,
        bagWeightG: 250,
        remainingG: 165,
        condition: BeanCondition.openedUsed,
        roastDate: now.subtract(const Duration(days: 14)),
        tastingNotes: const ['White Peach', 'Jasmine', 'Bergamot'],
        preferredHotClick: 21,
        preferredIcedClick: 18,
      ),
      CoffeeBean(
        id: 'bean-kenya-nyeri',
        name: 'Kenya Nyeri AA',
        roastery: 'Common Grounds',
        origin: 'Nyeri, Kenya',
        process: 'Washed',
        roastLevel: RoastLevel.light,
        bagWeightG: 200,
        remainingG: 21,
        condition: BeanCondition.openedUsed,
        roastDate: now.subtract(const Duration(days: 16)),
        tastingNotes: const ['Blackcurrant', 'Hibiscus', 'Sweet Citrus'],
        preferredHotClick: 22,
        preferredIcedClick: 19,
      ),
      CoffeeBean(
        id: 'bean-colombia-pink',
        name: 'Colombia Pink Bourbon',
        roastery: 'Space Roastery',
        origin: 'Huila, Colombia',
        process: 'Honey',
        roastLevel: RoastLevel.medium,
        bagWeightG: 200,
        remainingG: 200,
        condition: BeanCondition.sealedNew,
        roastDate: now.subtract(const Duration(days: 2)),
        tastingNotes: const ['Caramel', 'Red Apple', 'Honey'],
        preferredHotClick: 23,
        preferredIcedClick: 20,
      ),
    ];
  }

  List<BrewLog> _seedDemoLogs() {
    final now = DateTime.now();
    return [
      BrewLog(
        id: 'log-1',
        brewedAt: now.subtract(const Duration(hours: 3)),
        beanId: 'bean-ethiopia-guji',
        beanName: 'Ethiopia Guji Uraga',
        recipeId: 'hoffmann-1cup-hot',
        recipeName: 'James Hoffmann · Better 1-Cup',
        mode: BrewMode.hot,
        icedMethod: IcedMethod.iceFirst,
        grinderId: 'comandante-c40-mk4',
        grinderName: 'Comandante C40 MK4',
        clickSetting: 21,
        tempC: 94,
        doseG: 15,
        totalLiquidG: 250,
        hotWaterG: 250,
        iceG: 0,
        targetDrawdownSec: 180,
        actualDrawdownSec: 178,
        rating: 5.0,
        tasteFeeling: TasteFeeling.balancedSweet,
        flavorBars: const FlavorBars(
          acidity: 3.5,
          sweetness: 5.0,
          bitterness: 1.5,
          body: 3.5,
        ),
        tastingTags: const ['White Peach', 'Jasmine', 'Pas & Manis'],
        notes:
            'Turun 2 klik langsung bikin manis persiknya keluar di suhu ~60°C. Simpan jadi resep andalan!',
        stageSnapshots: const [
          '1. 0:00 Bloom 50 ml (Spiral)',
          '2. 0:45 → 100 ml (Spiral)',
          '3. 1:10 → 150 ml (Spiral)',
          '4. 1:30 → 200 ml (Spiral)',
          '5. 1:50 → 250 ml + Rao Spin',
        ],
        isGolden: true,
      ),
      BrewLog(
        id: 'log-2',
        brewedAt: now.subtract(const Duration(days: 1, hours: 2)),
        beanId: 'bean-ethiopia-guji',
        beanName: 'Ethiopia Guji Uraga',
        recipeId: 'hoffmann-japanese-iced',
        recipeName: 'James Hoffmann · Japanese Iced',
        mode: BrewMode.iced,
        icedMethod: IcedMethod.iceFirst,
        grinderId: 'comandante-c40-mk4',
        grinderName: 'Comandante C40 MK4',
        clickSetting: 18,
        tempC: 96,
        doseG: 15,
        totalLiquidG: 230,
        hotWaterG: 138,
        iceG: 92,
        targetDrawdownSec: 145,
        actualDrawdownSec: 144,
        rating: 4.9,
        tasteFeeling: TasteFeeling.balancedSweet,
        flavorBars: const FlavorBars(
          acidity: 4.0,
          sweetness: 4.5,
          bitterness: 1.5,
          body: 3.0,
        ),
        tastingTags: const ['Bergamot', 'Honey', 'Crisp'],
        notes:
            'Es duluan di server + swirl 10 detik setelah selesai. Segar banget buat siang!',
        stageSnapshots: const [
          '1. 0:00 Bloom 45 ml (Spiral)',
          '2. 0:45 → 94 ml (Spiral)',
          '3. 1:25 → 138 ml + Swirl Es 92g',
        ],
        isGolden: true,
      ),
      BrewLog(
        id: 'log-3',
        brewedAt: now.subtract(const Duration(days: 2)),
        beanId: 'bean-ethiopia-guji',
        beanName: 'Ethiopia Guji Uraga',
        recipeId: 'hoffmann-1cup-hot',
        recipeName: 'James Hoffmann · Better 1-Cup',
        mode: BrewMode.hot,
        icedMethod: IcedMethod.iceFirst,
        grinderId: 'comandante-c40-mk4',
        grinderName: 'Comandante C40 MK4',
        clickSetting: 23,
        tempC: 94,
        doseG: 15,
        totalLiquidG: 250,
        hotWaterG: 250,
        iceG: 0,
        targetDrawdownSec: 180,
        actualDrawdownSec: 148,
        rating: 4.0,
        tasteFeeling: TasteFeeling.sourSharp,
        flavorBars: const FlavorBars(
          acidity: 4.5,
          sweetness: 2.5,
          bitterness: 1.5,
          body: 2.5,
        ),
        tastingTags: const ['Lemon', 'Asam Tajam'],
        notes: 'Drawdown terlalu cepat (2:28) — saran rumus turunkan ke 21 klik.',
        stageSnapshots: const [
          '1. 0:00 Bloom 50 ml',
          '2. 0:45 → 150 ml',
          '3. 1:30 → 250 ml',
        ],
      ),
      BrewLog(
        id: 'log-4',
        brewedAt: now.subtract(const Duration(days: 3)),
        beanId: 'bean-kenya-nyeri',
        beanName: 'Kenya Nyeri AA',
        recipeId: 'kasuya-46-hot',
        recipeName: 'Tetsu Kasuya · 4:6 Method',
        mode: BrewMode.hot,
        icedMethod: IcedMethod.iceFirst,
        grinderId: 'comandante-c40-mk4',
        grinderName: 'Comandante C40 MK4',
        clickSetting: 28,
        tempC: 92,
        doseG: 16,
        totalLiquidG: 240,
        hotWaterG: 240,
        iceG: 0,
        targetDrawdownSec: 215,
        actualDrawdownSec: 208,
        rating: 4.7,
        tasteFeeling: TasteFeeling.balancedSweet,
        flavorBars: const FlavorBars(
          acidity: 4.5,
          sweetness: 4.5,
          bitterness: 2.0,
          body: 3.5,
        ),
        tastingTags: const ['Blackcurrant', 'Hibiscus'],
        notes: 'Cerah dan juicy sekali dengan 4:6 gilingan kasar.',
        stageSnapshots: const [
          '1. 0:00 → 40 ml',
          '2. 0:45 → 96 ml',
          '3. 1:30 → 144 ml',
          '4. 2:15 → 192 ml',
          '5. 2:55 → 240 ml',
        ],
      ),
    ];
  }

  Future<void> _persist({bool immediate = true}) async {
    if (!immediate) {
      _persistDebounce?.cancel();
      _persistDebounce = Timer(const Duration(milliseconds: 220), () {
        _persistNow();
      });
      return;
    }
    _persistDebounce?.cancel();
    await _persistNow();
  }

  Future<void> _persistNow() async {
    final storage = ref.read(pocketStorageProvider);
    await storage.writeState(exportBackupMap());
  }

  Map<String, dynamic> exportBackupMap() {
    return {
      'schema_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'prefs': state.prefs.toJson(),
      'active_profile_id': state.activeProfileId,
      'profiles': state.profiles.map((p) => p.toJson()).toList(),
      'custom_grinders':
          state.grinders.where((g) => !g.isOfficial).map((g) => g.toJson()).toList(),
      'custom_drippers':
          state.drippers.where((d) => !d.isOfficial).map((d) => d.toJson()).toList(),
      'custom_filters':
          state.filters.where((f) => !f.isOfficial).map((f) => f.toJson()).toList(),
      'deleted_grinder_ids': state.deletedGrinderIds.toList(),
      'deleted_dripper_ids': state.deletedDripperIds.toList(),
      'deleted_filter_ids': state.deletedFilterIds.toList(),
      'deleted_recipe_ids': state.deletedRecipeIds.toList(),
      'custom_recipes':
          state.recipes.where((r) => !r.isOfficial).map((r) => r.toJson()).toList(),
      'beans': state.beans.map((b) => b.toJson()).toList(),
      'logs': state.logs.map((l) => l.toJson()).toList(),
    };
  }

  String exportBackupJson() =>
      const JsonEncoder.withIndent('  ').convert(exportBackupMap());

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded['prefs'] is! Map<String, dynamic>) return false;
      // Validate prefs deserialization before touching storage
      UserPrefs.fromJson(decoded['prefs'] as Map<String, dynamic>);
      final storage = ref.read(pocketStorageProvider);
      await storage.writeState(decoded);
      await _init();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clears ALL user data (beans, brew logs, custom gear, custom recipes, deleted flags)
  /// and writes a clean empty local state so reopening the app stays completely fresh.
  Future<void> clearAllLocalData() async {
    final catalog = await CatalogLoader.loadBundled();
    final storage = ref.read(pocketStorageProvider);
    final currentTheme = state.prefs.themePref;
    final currentUnit = state.prefs.unitMode;
    final currentTemp = state.prefs.tempUnit;
    await storage.clear();

    final freshProfiles = _defaultProfiles();
    final firstRecipe = catalog.recipes.first;
    state = PocketAppState(
      isLoaded: true,
      prefs: UserPrefs(
        onboarded: false,
        themePref: currentTheme,
        unitMode: currentUnit,
        tempUnit: currentTemp,
      ),
      grinders: catalog.grinders,
      drippers: catalog.drippers,
      filters: catalog.filters,
      profiles: freshProfiles,
      activeProfileId: freshProfiles.first.id,
      recipes: catalog.recipes,
      beans: const [],
      logs: const [],
      guides: catalog.guides,
      deletedGrinderIds: const <String>{},
      deletedDripperIds: const <String>{},
      deletedFilterIds: const <String>{},
      deletedRecipeIds: const <String>{},
      draft: ActiveBrewDraft(
        recipeId: firstRecipe.id,
        beanId: null,
        mode: firstRecipe.mode,
        icedMethod: IcedMethod.iceFirst,
        doseG: firstRecipe.doseG,
        ratio: firstRecipe.ratio,
        iceRatio: 0.40,
        clickSetting: 21,
        tempC: firstRecipe.tempC,
      ),
      pendingEval: null,
    );
    await _persist();
  }

  // ---- PREFERENCES ----
  void updatePrefs(UserPrefs next) {
    state = state.copyWith(prefs: next);
    _persist(immediate: false);
  }

  void setUnitMode(UnitMode unit) =>
      updatePrefs(state.prefs.copyWith(unitMode: unit));

  void setTempUnit(TempUnit unit) =>
      updatePrefs(state.prefs.copyWith(tempUnit: unit));

  void setThemePref(AppThemePref theme) =>
      updatePrefs(state.prefs.copyWith(themePref: theme));

  void completeOnboarding({
    required UnitMode unit,
    required TempUnit tempUnit,
    required String grinderId,
    required String dripperId,
    String? userName,
  }) {
    final grinderChanged = state.activeProfile.grinderId != grinderId;
    final updatedProfiles = state.profiles.map((p) {
      if (p.id == state.activeProfileId) {
        return p.copyWith(grinderId: grinderId, dripperId: dripperId);
      }
      return p;
    }).toList();
    final trimmedName = userName?.trim();
    state = state.copyWith(
      prefs: state.prefs.copyWith(
        userName: (trimmedName != null && trimmedName.isNotEmpty)
            ? trimmedName
            : state.prefs.userName,
        unitMode: unit,
        tempUnit: tempUnit,
        onboarded: true,
      ),
      profiles: updatedProfiles,
    );
    if (grinderChanged) {
      _recomputeRecommendedClick();
    }
    _persist();
  }

  void skipOnboarding() {
    state = state.copyWith(
      prefs: state.prefs.copyWith(onboarded: true),
    );
    _persist();
  }

  /// Restores ALL deleted built-in grinders, drippers, filters, and official recipes
  /// without affecting any user custom gear, custom recipes, beans, or brew logs.
  Future<void> restoreAllDeletedOfficialCatalog() async {
    final catalog = await CatalogLoader.loadBundled();
    final customGrinders = state.grinders.where((g) => !g.isOfficial).toList();
    final customDrippers = state.drippers.where((d) => !d.isOfficial).toList();
    final customFilters = state.filters.where((f) => !f.isOfficial).toList();
    final customRecipes = state.recipes.where((r) => !r.isOfficial).toList();
    state = state.copyWith(
      grinders: [...catalog.grinders, ...customGrinders],
      drippers: [...catalog.drippers, ...customDrippers],
      filters: [...catalog.filters, ...customFilters],
      recipes: [...catalog.recipes, ...customRecipes],
      deletedGrinderIds: const <String>{},
      deletedDripperIds: const <String>{},
      deletedFilterIds: const <String>{},
      deletedRecipeIds: const <String>{},
    );
    await _persist();
  }

  // ---- GEAR & PROFILES ----
  void selectProfile(String profileId) {
    final prevGrinder = state.activeGrinder;
    state = state.copyWith(activeProfileId: profileId);
    final nextGrinder = state.activeGrinder;
    final converted = DeltaMicronGrinderEngine.convertClick(
      from: prevGrinder,
      fromClick: state.draft.clickSetting,
      to: nextGrinder,
    );
    state = state.copyWith(
      draft: state.draft.copyWith(clickSetting: converted),
    );
    _persist();
  }

  void setActiveGrinder(String grinderId) {
    final prevGrinder = state.activeGrinder;
    final updatedProfiles = state.profiles.map((p) {
      if (p.id == state.activeProfileId) {
        return p.copyWith(grinderId: grinderId);
      }
      return p;
    }).toList();
    state = state.copyWith(profiles: updatedProfiles);
    final nextGrinder = state.activeGrinder;
    final converted = DeltaMicronGrinderEngine.convertClick(
      from: prevGrinder,
      fromClick: state.draft.clickSetting,
      to: nextGrinder,
    );
    state = state.copyWith(
      draft: state.draft.copyWith(clickSetting: converted),
    );
    _persist();
  }

  void setActiveDripper(String dripperId) {
    final updatedProfiles = state.profiles.map((p) {
      if (p.id == state.activeProfileId) {
        return p.copyWith(dripperId: dripperId);
      }
      return p;
    }).toList();
    state = state.copyWith(profiles: updatedProfiles);
    _persist();
  }

  void setActiveFilter(String filterId) {
    final updatedProfiles = state.profiles.map((p) {
      if (p.id == state.activeProfileId) {
        return p.copyWith(filterId: filterId);
      }
      return p;
    }).toList();
    state = state.copyWith(profiles: updatedProfiles);
    _recomputeRecommendedClick();
    _persist();
  }

  void addCustomGrinder(GrinderSpec grinder, {bool activate = true}) {
    state = state.copyWith(grinders: [...state.grinders, grinder]);
    if (activate) {
      setActiveGrinder(grinder.id);
    } else {
      _persist();
    }
  }

  void updateCustomGrinder(GrinderSpec updated, {bool activate = false}) {
    state = state.copyWith(
      grinders: state.grinders
          .map((g) => g.id == updated.id ? updated : g)
          .toList(),
    );
    if (activate) {
      setActiveGrinder(updated.id);
    } else {
      _persist();
    }
  }

  void deleteCustomGrinder(String grinderId) {
    final target = state.grinders.where((g) => g.id == grinderId).firstOrNull;
    if (target == null) return;
    final remaining = state.grinders.where((g) => g.id != grinderId).toList();
    if (remaining.isEmpty) return;
    final fallbackId = remaining.first.id;
    final fixedProfiles = state.profiles
        .map((p) =>
            p.grinderId == grinderId ? p.copyWith(grinderId: fallbackId) : p)
        .toList();
    final nextDeleted = target.isOfficial
        ? {...state.deletedGrinderIds, grinderId}
        : state.deletedGrinderIds;
    state = state.copyWith(
      grinders: remaining,
      profiles: fixedProfiles,
      deletedGrinderIds: nextDeleted,
    );
    _recomputeRecommendedClick();
    _persist();
  }

  void addCustomDripper(DripperSpec dripper, {bool activate = true}) {
    state = state.copyWith(drippers: [...state.drippers, dripper]);
    if (activate) {
      setActiveDripper(dripper.id);
    } else {
      _persist();
    }
  }

  void updateCustomDripper(DripperSpec updated, {bool activate = false}) {
    state = state.copyWith(
      drippers: state.drippers
          .map((d) => d.id == updated.id ? updated : d)
          .toList(),
    );
    if (activate) {
      setActiveDripper(updated.id);
    } else {
      _persist();
    }
  }

  void deleteCustomDripper(String dripperId) {
    final target = state.drippers.where((d) => d.id == dripperId).firstOrNull;
    if (target == null) return;
    final remaining = state.drippers.where((d) => d.id != dripperId).toList();
    if (remaining.isEmpty) return;
    final fallbackId = remaining.first.id;
    final fixedProfiles = state.profiles
        .map((p) =>
            p.dripperId == dripperId ? p.copyWith(dripperId: fallbackId) : p)
        .toList();
    final nextDeleted = target.isOfficial
        ? {...state.deletedDripperIds, dripperId}
        : state.deletedDripperIds;
    state = state.copyWith(
      drippers: remaining,
      profiles: fixedProfiles,
      deletedDripperIds: nextDeleted,
    );
    _persist();
  }

  void addCustomFilter(FilterSpec filter, {bool activate = true}) {
    state = state.copyWith(filters: [...state.filters, filter]);
    if (activate) {
      setActiveFilter(filter.id);
    } else {
      _persist();
    }
  }

  void updateCustomFilter(FilterSpec updated, {bool activate = false}) {
    state = state.copyWith(
      filters: state.filters
          .map((f) => f.id == updated.id ? updated : f)
          .toList(),
    );
    if (activate) {
      setActiveFilter(updated.id);
    } else {
      _persist();
    }
  }

  void deleteCustomFilter(String filterId) {
    final target = state.filters.where((f) => f.id == filterId).firstOrNull;
    if (target == null) return;
    final remaining = state.filters.where((f) => f.id != filterId).toList();
    if (remaining.isEmpty) return;
    final fallbackId = remaining.first.id;
    final fixedProfiles = state.profiles
        .map((p) =>
            p.filterId == filterId ? p.copyWith(filterId: fallbackId) : p)
        .toList();
    final nextDeleted = target.isOfficial
        ? {...state.deletedFilterIds, filterId}
        : state.deletedFilterIds;
    state = state.copyWith(
      filters: remaining,
      profiles: fixedProfiles,
      deletedFilterIds: nextDeleted,
    );
    _recomputeRecommendedClick();
    _persist();
  }

  Future<void> restoreDeletedOfficialGear() async {
    final catalog = await CatalogLoader.loadBundled();
    final customGrinders = state.grinders.where((g) => !g.isOfficial).toList();
    final customDrippers = state.drippers.where((d) => !d.isOfficial).toList();
    final customFilters = state.filters.where((f) => !f.isOfficial).toList();
    state = state.copyWith(
      grinders: [...catalog.grinders, ...customGrinders],
      drippers: [...catalog.drippers, ...customDrippers],
      filters: [...catalog.filters, ...customFilters],
      deletedGrinderIds: const <String>{},
      deletedDripperIds: const <String>{},
      deletedFilterIds: const <String>{},
    );
    await _persist();
  }

  // ---- QUICK BREW & RECIPES ----
  void selectBrewMode(BrewMode mode) {
    final targetRecipe = mode == BrewMode.iced
        ? state.recipes.firstWhere(
            (r) => r.mode == BrewMode.iced,
            orElse: () => state.activeRecipe,
          )
        : state.recipes.firstWhere(
            (r) => r.mode == BrewMode.hot,
            orElse: () => state.activeRecipe,
          );
    selectRecipe(targetRecipe.id, forceMode: mode);
  }

  void selectRecipe(String recipeId, {BrewMode? forceMode}) {
    final recipe = state.recipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => state.recipes.first,
    );
    final mode = forceMode ?? recipe.mode;
    final rec = DeltaMicronGrinderEngine.recommend(
      grinder: state.activeGrinder,
      recipe: recipe,
      filter: state.activeFilter,
      overrideMode: mode,
    );
    final bean = state.activeBean;
    int click = rec.click;
    if (bean != null) {
      if (mode == BrewMode.hot &&
          recipe.grindOffsetUm == 0 &&
          bean.preferredHotClick != null) {
        click = bean.preferredHotClick!.clamp(
            state.activeGrinder.minClick, state.activeGrinder.maxClick);
      } else if (mode == BrewMode.iced &&
          (recipe.grindOffsetUm == -90 || recipe.grindOffsetUm == 0) &&
          bean.preferredIcedClick != null) {
        click = bean.preferredIcedClick!.clamp(
            state.activeGrinder.minClick, state.activeGrinder.maxClick);
      }
    }
    state = state.copyWith(
      draft: state.draft.copyWith(
        recipeId: recipe.id,
        mode: mode,
        doseG: recipe.doseG,
        ratio: recipe.ratio,
        iceRatio: mode == BrewMode.iced
            ? (recipe.iceRatio > 0 ? recipe.iceRatio : 0.40)
            : 0.40,
        icedMethod: recipe.icedMethod,
        tempC: recipe.tempC,
        clickSetting: click,
        clearSessionStages: true,
      ),
    );
  }

  /// Session-only pour stage override (outside the saved preset recipe).
  void setSessionStages(List<PourStage> stages) {
    if (stages.isEmpty) return;
    final normalized = List.generate(
      stages.length,
      (i) => stages[i].copyWith(order: i + 1),
    );
    state = state.copyWith(
      draft: state.draft.copyWith(sessionStages: normalized),
    );
  }

  /// Resets session-only pour stage overrides back to the active preset recipe stages.
  void resetSessionStages() {
    state = state.copyWith(
      draft: state.draft.copyWith(clearSessionStages: true),
    );
  }

  /// Selects an active coffee bean (or null for free brew) and applies its saved dial-in click.
  void selectBean(String? beanId) {
    if (beanId == null) {
      state = state.copyWith(draft: state.draft.copyWith(clearBean: true));
      return;
    }
    final bean = state.beans.where((b) => b.id == beanId).firstOrNull;
    if (bean == null) return;
    final preferred = state.draft.mode == BrewMode.iced
        ? bean.preferredIcedClick
        : bean.preferredHotClick;
    state = state.copyWith(
      draft: state.draft.copyWith(
        beanId: bean.id,
        clickSetting: preferred?.clamp(
              state.activeGrinder.minClick,
              state.activeGrinder.maxClick,
            ) ??
            state.draft.clickSetting,
      ),
    );
  }

  void updateDraft({
    BrewMode? mode,
    IcedMethod? icedMethod,
    String? beanId,
    double? doseG,
    double? ratio,
    double? iceRatio,
    int? clickSetting,
    int? tempC,
  }) {
    final normalizedDose = doseG != null
        ? ((doseG * 10).round() / 10.0).clamp(1.0, 120.0)
        : null;
    state = state.copyWith(
      draft: state.draft.copyWith(
        mode: mode,
        icedMethod: icedMethod,
        beanId: beanId,
        doseG: normalizedDose,
        ratio: ratio?.clamp(6.0, 25.0),
        iceRatio: iceRatio != null
            ? BrewRecipeScaler.clampIceRatio(iceRatio)
            : null,
        clickSetting: clickSetting?.clamp(0, 250),
        tempC: tempC?.clamp(75, 100),
      ),
    );
  }

  void _recomputeRecommendedClick() {
    final rec = DeltaMicronGrinderEngine.recommend(
      grinder: state.activeGrinder,
      recipe: state.activeRecipe,
      filter: state.activeFilter,
      overrideMode: state.draft.mode,
    );
    state = state.copyWith(
      draft: state.draft.copyWith(clickSetting: rec.click),
    );
  }

  void saveCustomRecipe(BrewRecipe recipe, {bool activate = true}) {
    final exists = state.recipes.any((r) => r.id == recipe.id);
    final updated = exists
        ? state.recipes.map((r) => r.id == recipe.id ? recipe : r).toList()
        : [...state.recipes, recipe];
    state = state.copyWith(recipes: updated);
    if (activate) {
      selectRecipe(recipe.id);
    }
    _persist();
  }

  void deleteRecipe(String recipeId) {
    final target = state.recipes.where((r) => r.id == recipeId).firstOrNull;
    if (target == null) return;
    final remaining = state.recipes.where((r) => r.id != recipeId).toList();
    if (remaining.isEmpty) return;
    final needsFallback = state.draft.recipeId == recipeId;
    final nextDeleted = target.isOfficial
        ? {...state.deletedRecipeIds, recipeId}
        : state.deletedRecipeIds;
    state = state.copyWith(
      recipes: remaining,
      deletedRecipeIds: nextDeleted,
    );
    if (needsFallback) {
      selectRecipe(remaining.first.id);
    }
    _persist();
  }

  void deleteCustomRecipe(String recipeId) => deleteRecipe(recipeId);

  Future<void> restoreDeletedOfficialRecipes() async {
    final catalog = await CatalogLoader.loadBundled();
    final customRecipes = state.recipes.where((r) => !r.isOfficial).toList();
    state = state.copyWith(
      recipes: [...catalog.recipes, ...customRecipes],
      deletedRecipeIds: const <String>{},
    );
    await _persist();
  }

  void startLastCupBrew(CoffeeBean bean) {
    final dose = bean.remainingG.clamp(8.0, 40.0);
    state = state.copyWith(
      draft: state.draft.copyWith(
        beanId: bean.id,
        mode: BrewMode.hot,
        doseG: dose,
        clickSetting: bean.preferredHotClick ?? state.draft.clickSetting,
      ),
    );
  }

  void rebrewFromLog(BrewLog log) {
    final hasRecipe = state.recipes.any((r) => r.id == log.recipeId);
    state = state.copyWith(
      draft: state.draft.copyWith(
        recipeId: hasRecipe ? log.recipeId : state.recipes.first.id,
        beanId: log.beanId,
        mode: log.mode,
        icedMethod: log.icedMethod,
        doseG: log.doseG,
        ratio: log.doseG > 0 ? (log.totalLiquidG / log.doseG) : 16.0,
        iceRatio: log.totalLiquidG > 0 && log.iceG > 0
            ? BrewRecipeScaler.clampIceRatio(log.iceG / log.totalLiquidG)
            : 0.40,
        clickSetting: log.clickSetting,
        tempC: log.tempC,
      ),
    );
  }

  // ---- TIMER -> EVALUATION -> BREW LOG ----
  void finishTimerForEvaluation(int actualDrawdownSec) {
    final plan = state.currentPlan;
    final snaps = plan.stages
        .map(
          (s) =>
              '${s.stage.order}. ${BrewRecipeScaler.formatDuration(s.stage.startSec)} ${s.stage.label} → ${BrewRecipeScaler.formatLiquid(s.cumulativeWaterG, state.prefs.unitMode)}',
        )
        .toList();

    state = state.copyWith(
      pendingEval: PendingEvaluation(
        beanId: state.activeBean?.id,
        beanName: state.activeBean?.name ?? 'Biji Kopi Pilihan',
        recipeId: state.activeRecipe.id,
        recipeName: state.activeRecipe.name,
        mode: plan.mode,
        icedMethod: plan.icedMethod,
        grinderId: state.activeGrinder.id,
        grinderName: state.activeGrinder.fullName,
        clickSetting: state.draft.clickSetting,
        tempC: plan.tempC,
        doseG: plan.doseG,
        totalLiquidG: plan.totalLiquidG,
        hotWaterG: plan.hotWaterG,
        iceG: plan.iceG,
        targetDrawdownSec: state.activeTargetDrawdownSec,
        actualDrawdownSec: actualDrawdownSec,
        stageSnapshots: snaps,
      ),
    );
  }

  void setPendingEvaluationTags(List<String> tags) {
    final pending = state.pendingEval;
    if (pending == null) return;
    state = state.copyWith(pendingEval: pending.copyWith(selectedTags: tags));
  }

  BrewLog saveEvaluatedBrew({
    required TasteFeeling feeling,
    required double rating,
    required FlavorBars bars,
    required List<String> tags,
    required String notes,
    required bool isGolden,
    required bool applyRecommendedClickForTomorrow,
    required int recommendedClick,
    required int recommendedTempC,
    bool deductBeanStock = true,
  }) {
    final p = state.pendingEval;
    final plan = state.currentPlan;
    final log = BrewLog(
      id: _uuid.v4(),
      brewedAt: DateTime.now(),
      beanId: p?.beanId ?? state.activeBean?.id,
      beanName: p?.beanName ?? (state.activeBean?.name ?? 'Biji Kopi Pilihan'),
      recipeId: p?.recipeId ?? state.activeRecipe.id,
      recipeName: p?.recipeName ?? state.activeRecipe.name,
      mode: p?.mode ?? plan.mode,
      icedMethod: p?.icedMethod ?? plan.icedMethod,
      grinderId: p?.grinderId ?? state.activeGrinder.id,
      grinderName: p?.grinderName ?? state.activeGrinder.fullName,
      clickSetting: p?.clickSetting ?? state.draft.clickSetting,
      tempC: p?.tempC ?? plan.tempC,
      doseG: p?.doseG ?? plan.doseG,
      totalLiquidG: p?.totalLiquidG ?? plan.totalLiquidG,
      hotWaterG: p?.hotWaterG ?? plan.hotWaterG,
      iceG: p?.iceG ?? plan.iceG,
      targetDrawdownSec:
          p?.targetDrawdownSec ?? state.activeRecipe.targetDrawdownSec,
      actualDrawdownSec:
          p?.actualDrawdownSec ?? state.activeRecipe.targetDrawdownSec,
      rating: rating,
      tasteFeeling: feeling,
      flavorBars: bars,
      tastingTags: tags,
      notes: notes.trim(),
      stageSnapshots: p?.stageSnapshots ?? const [],
      isGolden: isGolden,
    );

    // Optionally deduct bean stock & save dial-in click for tomorrow
    final updatedBeans = state.beans.map((b) {
      if (b.id == log.beanId) {
        final nextRem = deductBeanStock
            ? (b.remainingG - log.doseG).clamp(0.0, b.bagWeightG)
            : b.remainingG;
        final nextClick = applyRecommendedClickForTomorrow
            ? recommendedClick
            : (isGolden ? log.clickSetting : null);
        return b.copyWith(
          remainingG: nextRem,
          preferredHotClick:
              log.mode == BrewMode.hot && nextClick != null
                  ? nextClick
                  : b.preferredHotClick,
          preferredIcedClick:
              log.mode == BrewMode.iced && nextClick != null
                  ? nextClick
                  : b.preferredIcedClick,
        );
      }
      return b;
    }).toList();

    final nextDraft = applyRecommendedClickForTomorrow
        ? state.draft.copyWith(
            clickSetting: recommendedClick,
            tempC: recommendedTempC,
          )
        : state.draft;

    state = state.copyWith(
      logs: [log, ...state.logs],
      beans: updatedBeans,
      draft: nextDraft,
      clearPendingEval: true,
    );
    _persist();
    return log;
  }

  void toggleLogGolden(String logId) {
    state = state.copyWith(
      logs: state.logs
          .map((l) => l.id == logId ? l.copyWith(isGolden: !l.isGolden) : l)
          .toList(),
    );
    _persist();
  }

  void deleteLog(String logId) {
    state = state.copyWith(
      logs: state.logs.where((l) => l.id != logId).toList(),
    );
    _persist();
  }

  // ---- BEANS & STOCK OPNAME ----
  void addBean(CoffeeBean bean) {
    state = state.copyWith(
      beans: [bean, ...state.beans],
      draft: state.draft.copyWith(beanId: bean.id),
    );
    _persist();
  }

  void updateBean(CoffeeBean updated) {
    state = state.copyWith(
      beans: state.beans.map((b) => b.id == updated.id ? updated : b).toList(),
    );
    _persist();
  }

  void correctBeanStock(String beanId, double actualRemainingG) {
    final safeG = actualRemainingG.clamp(0.0, 5000.0);
    state = state.copyWith(
      beans: state.beans.map((b) {
        if (b.id == beanId) {
          final nextBag = safeG > b.bagWeightG ? safeG : b.bagWeightG;
          return b.copyWith(
            bagWeightG: nextBag,
            remainingG: safeG,
          );
        }
        return b;
      }).toList(),
    );
    _persist();
  }

  void toggleBeanFreeze(String beanId) {
    state = state.copyWith(
      beans: state.beans
          .map((b) => b.id == beanId ? b.copyWith(isFrozen: !b.isFrozen) : b)
          .toList(),
    );
    _persist();
  }

  void deleteBean(String beanId) {
    final remaining = state.beans.where((b) => b.id != beanId).toList();
    final wasActive = state.draft.beanId == beanId;
    final nextActive =
        remaining.where((b) => !b.isFrozen).firstOrNull ?? remaining.firstOrNull;
    state = state.copyWith(
      beans: remaining,
      draft: wasActive
          ? (nextActive != null
              ? state.draft.copyWith(beanId: nextActive.id)
              : state.draft.copyWith(clearBean: true))
          : state.draft,
    );
    _persist();
  }
}
