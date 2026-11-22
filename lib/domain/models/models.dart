import 'enums.dart';

class GrinderSpec {
  const GrinderSpec({
    required this.id,
    required this.brand,
    required this.model,
    required this.umPerClick,
    required this.clicksPerRev,
    required this.minClick,
    required this.maxClick,
    required this.v60HotMin,
    required this.v60HotMax,
    required this.v60HotDefault,
    required this.zeroPointNote,
    required this.burrSpec,
    this.isOfficial = true,
  });

  final String id;
  final String brand;
  final String model;
  final double umPerClick;
  final int clicksPerRev;
  final int minClick;
  final int maxClick;
  final int v60HotMin;
  final int v60HotMax;
  final int v60HotDefault;
  final String zeroPointNote;
  final String burrSpec;
  final bool isOfficial;

  String get fullName => '$brand $model';

  factory GrinderSpec.fromJson(Map<String, dynamic> j) => GrinderSpec(
        id: j['id'] as String,
        brand: j['brand'] as String? ?? 'Custom',
        model: j['model'] as String? ?? 'Grinder',
        umPerClick: (j['um_per_click'] as num?)?.toDouble() ?? 30.0,
        clicksPerRev: (j['clicks_per_rev'] as num?)?.toInt() ?? 12,
        minClick: (j['min_click'] as num?)?.toInt() ?? 10,
        maxClick: (j['max_click'] as num?)?.toInt() ?? 36,
        v60HotMin: (j['v60_hot_min'] as num?)?.toInt() ?? 18,
        v60HotMax: (j['v60_hot_max'] as num?)?.toInt() ?? 26,
        v60HotDefault: (j['v60_hot_default'] as num?)?.toInt() ?? 22,
        zeroPointNote: j['zero_point_note'] as String? ?? '',
        burrSpec: j['burr_spec'] as String? ?? '',
        isOfficial: j['is_official'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'um_per_click': umPerClick,
        'clicks_per_rev': clicksPerRev,
        'min_click': minClick,
        'max_click': maxClick,
        'v60_hot_min': v60HotMin,
        'v60_hot_max': v60HotMax,
        'v60_hot_default': v60HotDefault,
        'zero_point_note': zeroPointNote,
        'burr_spec': burrSpec,
        'is_official': isOfficial,
      };
}

class DripperSpec {
  const DripperSpec({
    required this.id,
    required this.name,
    required this.geometry,
    required this.material,
    required this.capacityG,
    required this.flowNote,
    this.isOfficial = true,
  });

  final String id;
  final String name;
  final String geometry;
  final String material;
  final String capacityG;
  final String flowNote;
  final bool isOfficial;

  factory DripperSpec.fromJson(Map<String, dynamic> j) => DripperSpec(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Dripper',
        geometry: j['geometry'] as String? ?? 'Cone 60°',
        material: j['material'] as String? ?? 'Resin',
        capacityG: j['capacity_g'] as String? ?? '15–30g',
        flowNote: j['flow_note'] as String? ?? '',
        isOfficial: j['is_official'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'geometry': geometry,
        'material': material,
        'capacity_g': capacityG,
        'flow_note': flowNote,
        'is_official': isOfficial,
      };
}

class FilterSpec {
  const FilterSpec({
    required this.id,
    required this.name,
    required this.speed,
    required this.grindOffsetUm,
    required this.note,
    this.isOfficial = true,
  });

  final String id;
  final String name;
  final String speed;
  final double grindOffsetUm;
  final String note;
  final bool isOfficial;

  factory FilterSpec.fromJson(Map<String, dynamic> j) => FilterSpec(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Filter',
        speed: j['speed'] as String? ?? 'Sedang',
        grindOffsetUm: (j['grind_offset_um'] as num?)?.toDouble() ?? 0.0,
        note: j['note'] as String? ?? '',
        isOfficial: j['is_official'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'speed': speed,
        'grind_offset_um': grindOffsetUm,
        'note': note,
        'is_official': isOfficial,
      };
}

class GearProfile {
  const GearProfile({
    required this.id,
    required this.name,
    required this.grinderId,
    required this.dripperId,
    required this.filterId,
    required this.kettleNote,
  });

  final String id;
  final String name;
  final String grinderId;
  final String dripperId;
  final String filterId;
  final String kettleNote;

  GearProfile copyWith({
    String? name,
    String? grinderId,
    String? dripperId,
    String? filterId,
    String? kettleNote,
  }) =>
      GearProfile(
        id: id,
        name: name ?? this.name,
        grinderId: grinderId ?? this.grinderId,
        dripperId: dripperId ?? this.dripperId,
        filterId: filterId ?? this.filterId,
        kettleNote: kettleNote ?? this.kettleNote,
      );

  factory GearProfile.fromJson(Map<String, dynamic> j) => GearProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        grinderId: j['grinder_id'] as String,
        dripperId: j['dripper_id'] as String,
        filterId: j['filter_id'] as String,
        kettleNote: j['kettle_note'] as String? ?? 'Gooseneck PID · Air Sedang',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grinder_id': grinderId,
        'dripper_id': dripperId,
        'filter_id': filterId,
        'kettle_note': kettleNote,
      };
}

class PourStage {
  const PourStage({
    required this.order,
    required this.label,
    required this.startSec,
    required this.pourEndSec,
    required this.endSec,
    required this.targetCumulativePct,
    required this.pattern,
    required this.rate,
    required this.cue,
  });

  final int order;
  final String label;
  final int startSec;
  final int pourEndSec;
  final int endSec;
  final double targetCumulativePct;
  final PourPattern pattern;
  final PourRate rate;
  final String cue;

  PourStage copyWith({
    int? order,
    String? label,
    int? startSec,
    int? pourEndSec,
    int? endSec,
    double? targetCumulativePct,
    PourPattern? pattern,
    PourRate? rate,
    String? cue,
  }) =>
      PourStage(
        order: order ?? this.order,
        label: label ?? this.label,
        startSec: startSec ?? this.startSec,
        pourEndSec: pourEndSec ?? this.pourEndSec,
        endSec: endSec ?? this.endSec,
        targetCumulativePct: targetCumulativePct ?? this.targetCumulativePct,
        pattern: pattern ?? this.pattern,
        rate: rate ?? this.rate,
        cue: cue ?? this.cue,
      );

  factory PourStage.fromJson(Map<String, dynamic> j) => PourStage(
        order: (j['order'] as num).toInt(),
        label: j['label'] as String,
        startSec: (j['start_sec'] as num).toInt(),
        pourEndSec: (j['pour_end_sec'] as num).toInt(),
        endSec: (j['end_sec'] as num).toInt(),
        targetCumulativePct: (j['target_cumulative_pct'] as num).toDouble(),
        pattern: PourPattern.fromString(j['pattern'] as String?),
        rate: PourRate.fromString(j['rate'] as String?),
        cue: j['cue'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'order': order,
        'label': label,
        'start_sec': startSec,
        'pour_end_sec': pourEndSec,
        'end_sec': endSec,
        'target_cumulative_pct': targetCumulativePct,
        'pattern': pattern.name,
        'rate': rate.name,
        'cue': cue,
      };
}

class BrewRecipe {
  const BrewRecipe({
    required this.id,
    required this.name,
    required this.author,
    required this.mode,
    required this.badge,
    required this.isOfficial,
    required this.summary,
    required this.doseG,
    required this.ratio,
    required this.waterG,
    required this.iceRatio,
    required this.icedMethod,
    required this.tempC,
    required this.targetDrawdownSec,
    required this.grindOffsetUm,
    required this.stages,
  });

  final String id;
  final String name;
  final String author;
  final BrewMode mode;
  final String badge; // 'Hot V60' | 'Japanese' | 'Custom'
  final bool isOfficial;
  final String summary;
  final double doseG;
  final double ratio;
  final double waterG;
  final double iceRatio;
  final IcedMethod icedMethod;
  final int tempC;
  final int targetDrawdownSec;
  final double grindOffsetUm;
  final List<PourStage> stages;

  BrewRecipe copyWith({
    String? id,
    String? name,
    String? author,
    BrewMode? mode,
    String? badge,
    bool? isOfficial,
    String? summary,
    double? doseG,
    double? ratio,
    double? waterG,
    double? iceRatio,
    IcedMethod? icedMethod,
    int? tempC,
    int? targetDrawdownSec,
    double? grindOffsetUm,
    List<PourStage>? stages,
  }) =>
      BrewRecipe(
        id: id ?? this.id,
        name: name ?? this.name,
        author: author ?? this.author,
        mode: mode ?? this.mode,
        badge: badge ?? this.badge,
        isOfficial: isOfficial ?? this.isOfficial,
        summary: summary ?? this.summary,
        doseG: doseG ?? this.doseG,
        ratio: ratio ?? this.ratio,
        waterG: waterG ?? this.waterG,
        iceRatio: iceRatio ?? this.iceRatio,
        icedMethod: icedMethod ?? this.icedMethod,
        tempC: tempC ?? this.tempC,
        targetDrawdownSec: targetDrawdownSec ?? this.targetDrawdownSec,
        grindOffsetUm: grindOffsetUm ?? this.grindOffsetUm,
        stages: stages ?? this.stages,
      );

  factory BrewRecipe.fromJson(Map<String, dynamic> j) => BrewRecipe(
        id: j['id'] as String,
        name: j['name'] as String,
        author: j['author'] as String? ?? 'Custom',
        mode: (j['mode'] as String?) == 'iced' ? BrewMode.iced : BrewMode.hot,
        badge: j['badge'] as String? ??
            ((j['mode'] as String?) == 'iced' ? 'Japanese' : 'Hot V60'),
        isOfficial: j['is_official'] as bool? ?? false,
        summary: j['summary'] as String? ?? '',
        doseG: (j['dose_g'] as num).toDouble(),
        ratio: (j['ratio'] as num).toDouble(),
        waterG: (j['water_g'] as num).toDouble(),
        iceRatio: (j['ice_ratio'] as num?)?.toDouble() ?? 0.0,
        icedMethod: IcedMethod.fromId(j['iced_method'] as String?),
        tempC: (j['temp_c'] as num).toInt(),
        targetDrawdownSec: (j['target_drawdown_sec'] as num).toInt(),
        grindOffsetUm: (j['grind_offset_um'] as num?)?.toDouble() ?? 0.0,
        stages: (j['stages'] as List<dynamic>)
            .map((e) => PourStage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'author': author,
        'mode': mode == BrewMode.iced ? 'iced' : 'hot',
        'badge': badge,
        'is_official': isOfficial,
        'summary': summary,
        'dose_g': doseG,
        'ratio': ratio,
        'water_g': waterG,
        'ice_ratio': iceRatio,
        'iced_method': icedMethod.id,
        'temp_c': tempC,
        'target_drawdown_sec': targetDrawdownSec,
        'grind_offset_um': grindOffsetUm,
        'stages': stages.map((s) => s.toJson()).toList(),
      };
}

class CoffeeBean {
  const CoffeeBean({
    required this.id,
    required this.name,
    required this.roastery,
    required this.origin,
    required this.process,
    required this.roastLevel,
    required this.bagWeightG,
    required this.remainingG,
    required this.condition,
    required this.roastDate,
    required this.tastingNotes,
    this.variety = '',
    this.customRestMinD,
    this.customRestMaxD,
    this.isFrozen = false,
    this.frozenDays = 0,
    this.preferredHotClick,
    this.preferredIcedClick,
  });

  final String id;
  final String name;
  final String roastery;
  final String origin;
  final String process;
  final RoastLevel roastLevel;
  final double bagWeightG;
  final double remainingG;
  final BeanCondition condition;
  final DateTime roastDate;
  final List<String> tastingNotes;
  final String variety;
  final int? customRestMinD;
  final int? customRestMaxD;
  final bool isFrozen;
  final int frozenDays;
  final int? preferredHotClick;
  final int? preferredIcedClick;

  bool get hasCustomResting =>
      customRestMinD != null && customRestMaxD != null;

  CoffeeBean copyWith({
    String? name,
    String? roastery,
    String? origin,
    String? process,
    RoastLevel? roastLevel,
    double? bagWeightG,
    double? remainingG,
    BeanCondition? condition,
    DateTime? roastDate,
    List<String>? tastingNotes,
    String? variety,
    int? customRestMinD,
    int? customRestMaxD,
    bool clearCustomRest = false,
    bool? isFrozen,
    int? frozenDays,
    int? preferredHotClick,
    int? preferredIcedClick,
  }) =>
      CoffeeBean(
        id: id,
        name: name ?? this.name,
        roastery: roastery ?? this.roastery,
        origin: origin ?? this.origin,
        process: process ?? this.process,
        roastLevel: roastLevel ?? this.roastLevel,
        bagWeightG: bagWeightG ?? this.bagWeightG,
        remainingG: remainingG ?? this.remainingG,
        condition: condition ?? this.condition,
        roastDate: roastDate ?? this.roastDate,
        tastingNotes: tastingNotes ?? this.tastingNotes,
        variety: variety ?? this.variety,
        customRestMinD:
            clearCustomRest ? null : (customRestMinD ?? this.customRestMinD),
        customRestMaxD:
            clearCustomRest ? null : (customRestMaxD ?? this.customRestMaxD),
        isFrozen: isFrozen ?? this.isFrozen,
        frozenDays: frozenDays ?? this.frozenDays,
        preferredHotClick: preferredHotClick ?? this.preferredHotClick,
        preferredIcedClick: preferredIcedClick ?? this.preferredIcedClick,
      );

  factory CoffeeBean.fromJson(Map<String, dynamic> j) {
    final bagW = (j['bag_weight_g'] as num?)?.toDouble() ?? 200.0;
    final remW = (j['remaining_g'] as num?)?.toDouble() ?? bagW;
    return CoffeeBean(
      id: j['id'] as String,
      name: j['name'] as String? ?? 'Biji Kopi',
      roastery: j['roastery'] as String? ?? 'Home Roaster',
      origin: j['origin'] as String? ?? '',
      process: j['process'] as String? ?? 'Washed',
      roastLevel: RoastLevel.fromString(j['roast_level'] as String?),
      bagWeightG: bagW,
      remainingG: remW.clamp(0.0, bagW > remW ? bagW : remW),
      condition: BeanCondition.fromString(j['condition'] as String?),
      roastDate: DateTime.tryParse(j['roast_date'] as String? ?? '') ??
          DateTime.now(),
      tastingNotes: (j['tasting_notes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      variety: j['variety'] as String? ?? '',
      customRestMinD: (j['custom_rest_min_d'] as num?)?.toInt(),
      customRestMaxD: (j['custom_rest_max_d'] as num?)?.toInt(),
      isFrozen: j['is_frozen'] as bool? ?? false,
      frozenDays: (j['frozen_days'] as num?)?.toInt() ?? 0,
      preferredHotClick: (j['preferred_hot_click'] as num?)?.toInt(),
      preferredIcedClick: (j['preferred_iced_click'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roastery': roastery,
        'origin': origin,
        'process': process,
        'roast_level': roastLevel.name,
        'bag_weight_g': bagWeightG,
        'remaining_g': remainingG,
        'condition': condition.name,
        'roast_date': roastDate.toIso8601String(),
        'tasting_notes': tastingNotes,
        'variety': variety,
        'custom_rest_min_d': customRestMinD,
        'custom_rest_max_d': customRestMaxD,
        'is_frozen': isFrozen,
        'frozen_days': frozenDays,
        'preferred_hot_click': preferredHotClick,
        'preferred_iced_click': preferredIcedClick,
      };
}

class FlavorBars {
  const FlavorBars({
    this.acidity = 3.5,
    this.sweetness = 4.0,
    this.bitterness = 2.0,
    this.body = 3.5,
  });

  final double acidity;
  final double sweetness;
  final double bitterness;
  final double body;

  FlavorBars copyWith({
    double? acidity,
    double? sweetness,
    double? bitterness,
    double? body,
  }) =>
      FlavorBars(
        acidity: acidity ?? this.acidity,
        sweetness: sweetness ?? this.sweetness,
        bitterness: bitterness ?? this.bitterness,
        body: body ?? this.body,
      );

  factory FlavorBars.fromJson(Map<String, dynamic> j) => FlavorBars(
        acidity: (j['acidity'] as num?)?.toDouble() ?? 3.5,
        sweetness: (j['sweetness'] as num?)?.toDouble() ?? 4.0,
        bitterness: (j['bitterness'] as num?)?.toDouble() ?? 2.0,
        body: (j['body'] as num?)?.toDouble() ?? 3.5,
      );

  Map<String, dynamic> toJson() => {
        'acidity': acidity,
        'sweetness': sweetness,
        'bitterness': bitterness,
        'body': body,
      };
}

class BrewLog {
  const BrewLog({
    required this.id,
    required this.brewedAt,
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
    required this.rating,
    required this.tasteFeeling,
    required this.flavorBars,
    required this.tastingTags,
    required this.notes,
    required this.stageSnapshots,
    this.isGolden = false,
  });

  final String id;
  final DateTime brewedAt;
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
  final double rating;
  final TasteFeeling tasteFeeling;
  final FlavorBars flavorBars;
  final List<String> tastingTags;
  final String notes;
  final List<String> stageSnapshots;
  final bool isGolden;

  BrewLog copyWith({
    bool? isGolden,
    double? rating,
    String? notes,
    List<String>? tastingTags,
    FlavorBars? flavorBars,
    TasteFeeling? tasteFeeling,
  }) =>
      BrewLog(
        id: id,
        brewedAt: brewedAt,
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
        rating: rating ?? this.rating,
        tasteFeeling: tasteFeeling ?? this.tasteFeeling,
        flavorBars: flavorBars ?? this.flavorBars,
        tastingTags: tastingTags ?? this.tastingTags,
        notes: notes ?? this.notes,
        stageSnapshots: stageSnapshots,
        isGolden: isGolden ?? this.isGolden,
      );

  factory BrewLog.fromJson(Map<String, dynamic> j) => BrewLog(
        id: j['id'] as String,
        brewedAt: DateTime.tryParse(j['brewed_at'] as String? ?? '') ??
            DateTime.now(),
        beanId: j['bean_id'] as String?,
        beanName: j['bean_name'] as String? ?? 'Biji Kopi',
        recipeId: j['recipe_id'] as String? ?? 'hoffmann-1cup-hot',
        recipeName: j['recipe_name'] as String? ?? 'V60 Manual',
        mode: (j['mode'] as String?) == 'iced' ? BrewMode.iced : BrewMode.hot,
        icedMethod: IcedMethod.fromId(j['iced_method'] as String?),
        grinderId: j['grinder_id'] as String? ?? 'comandante-c40-mk4',
        grinderName: j['grinder_name'] as String? ?? 'Grinder',
        clickSetting: (j['click_setting'] as num?)?.toInt() ?? 21,
        tempC: (j['temp_c'] as num?)?.toInt() ?? 94,
        doseG: (j['dose_g'] as num?)?.toDouble() ?? 15.0,
        totalLiquidG: (j['total_liquid_g'] as num?)?.toDouble() ?? 250.0,
        hotWaterG: (j['hot_water_g'] as num?)?.toDouble() ?? 250.0,
        iceG: (j['ice_g'] as num?)?.toDouble() ?? 0.0,
        targetDrawdownSec: (j['target_drawdown_sec'] as num?)?.toInt() ?? 180,
        actualDrawdownSec: (j['actual_drawdown_sec'] as num?)?.toInt() ?? 180,
        rating: (j['rating'] as num?)?.toDouble() ?? 4.5,
        tasteFeeling: TasteFeeling.fromString(j['taste_feeling'] as String?),
        flavorBars:
            FlavorBars.fromJson(j['flavor_bars'] as Map<String, dynamic>? ?? {}),
        tastingTags: (j['tasting_tags'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        notes: j['notes'] as String? ?? '',
        stageSnapshots: (j['stage_snapshots'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        isGolden: j['is_golden'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'brewed_at': brewedAt.toIso8601String(),
        'bean_id': beanId,
        'bean_name': beanName,
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'mode': mode == BrewMode.iced ? 'iced' : 'hot',
        'iced_method': icedMethod.id,
        'grinder_id': grinderId,
        'grinder_name': grinderName,
        'click_setting': clickSetting,
        'temp_c': tempC,
        'dose_g': doseG,
        'total_liquid_g': totalLiquidG,
        'hot_water_g': hotWaterG,
        'ice_g': iceG,
        'target_drawdown_sec': targetDrawdownSec,
        'actual_drawdown_sec': actualDrawdownSec,
        'rating': rating,
        'taste_feeling': tasteFeeling.name,
        'flavor_bars': flavorBars.toJson(),
        'tasting_tags': tastingTags,
        'notes': notes,
        'stage_snapshots': stageSnapshots,
        'is_golden': isGolden,
      };
}

class LearnGuide {
  const LearnGuide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.readMinutes,
    required this.tags,
    required this.category,
  });

  final String id;
  final String title;
  final String subtitle;
  final int readMinutes;
  final List<String> tags;
  final String category;

  factory LearnGuide.fromJson(Map<String, dynamic> j) => LearnGuide(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        readMinutes: (j['read_minutes'] as num).toInt(),
        tags: (j['tags'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        category: j['category'] as String,
      );
}

class UserPrefs {
  const UserPrefs({
    this.userName = 'Dito',
    this.unitMode = UnitMode.ml,
    this.tempUnit = TempUnit.celsius,
    this.themePref = AppThemePref.light,
    this.restLightMinD = 7,
    this.restLightMaxD = 14,
    this.restMedMinD = 5,
    this.restMedMaxD = 10,
    this.restDarkMinD = 3,
    this.restDarkMaxD = 7,
    this.keepScreenOn = true,
    this.soundCue = true,
    this.hapticCue = true,
    this.onboarded = true,
  });

  final String userName;
  final UnitMode unitMode;
  final TempUnit tempUnit;
  final AppThemePref themePref;
  final int restLightMinD;
  final int restLightMaxD;
  final int restMedMinD;
  final int restMedMaxD;
  final int restDarkMinD;
  final int restDarkMaxD;
  final bool keepScreenOn;
  final bool soundCue;
  final bool hapticCue;
  final bool onboarded;

  (int min, int max) restingRange(RoastLevel roast) => switch (roast) {
        RoastLevel.light => (restLightMinD, restLightMaxD),
        RoastLevel.lightMedium => (
          ((restLightMinD + restMedMinD) / 2).round(),
          ((restLightMaxD + restMedMaxD) / 2).round(),
        ),
        RoastLevel.medium => (restMedMinD, restMedMaxD),
        RoastLevel.mediumDark => (
          ((restMedMinD + restDarkMinD) / 2).round(),
          ((restMedMaxD + restDarkMaxD) / 2).round(),
        ),
        RoastLevel.dark => (restDarkMinD, restDarkMaxD),
      };

  UserPrefs copyWith({
    String? userName,
    UnitMode? unitMode,
    TempUnit? tempUnit,
    AppThemePref? themePref,
    int? restLightMinD,
    int? restLightMaxD,
    int? restMedMinD,
    int? restMedMaxD,
    int? restDarkMinD,
    int? restDarkMaxD,
    bool? keepScreenOn,
    bool? soundCue,
    bool? hapticCue,
    bool? onboarded,
  }) =>
      UserPrefs(
        userName: userName ?? this.userName,
        unitMode: unitMode ?? this.unitMode,
        tempUnit: tempUnit ?? this.tempUnit,
        themePref: themePref ?? this.themePref,
        restLightMinD: restLightMinD ?? this.restLightMinD,
        restLightMaxD: restLightMaxD ?? this.restLightMaxD,
        restMedMinD: restMedMinD ?? this.restMedMinD,
        restMedMaxD: restMedMaxD ?? this.restMedMaxD,
        restDarkMinD: restDarkMinD ?? this.restDarkMinD,
        restDarkMaxD: restDarkMaxD ?? this.restDarkMaxD,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        soundCue: soundCue ?? this.soundCue,
        hapticCue: hapticCue ?? this.hapticCue,
        onboarded: onboarded ?? this.onboarded,
      );

  factory UserPrefs.fromJson(Map<String, dynamic> j) => UserPrefs(
        userName: j['user_name'] as String? ?? 'Dito',
        unitMode: UnitMode.fromString(j['unit_mode'] as String?),
        tempUnit: TempUnit.fromString(j['temp_unit'] as String?),
        themePref: AppThemePref.fromString(j['theme_pref'] as String?),
        restLightMinD: (j['rest_light_min_d'] as num?)?.toInt() ?? 7,
        restLightMaxD: (j['rest_light_max_d'] as num?)?.toInt() ?? 14,
        restMedMinD: (j['rest_med_min_d'] as num?)?.toInt() ?? 5,
        restMedMaxD: (j['rest_med_max_d'] as num?)?.toInt() ?? 10,
        restDarkMinD: (j['rest_dark_min_d'] as num?)?.toInt() ?? 3,
        restDarkMaxD: (j['rest_dark_max_d'] as num?)?.toInt() ?? 7,
        keepScreenOn: j['keep_screen_on'] as bool? ?? true,
        soundCue: j['sound_cue'] as bool? ?? true,
        hapticCue: j['haptic_cue'] as bool? ?? true,
        onboarded: j['onboarded'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'user_name': userName,
        'unit_mode': unitMode.name,
        'temp_unit': tempUnit.name,
        'theme_pref': themePref.name,
        'rest_light_min_d': restLightMinD,
        'rest_light_max_d': restLightMaxD,
        'rest_med_min_d': restMedMinD,
        'rest_med_max_d': restMedMaxD,
        'rest_dark_min_d': restDarkMinD,
        'rest_dark_max_d': restDarkMaxD,
        'keep_screen_on': keepScreenOn,
        'sound_cue': soundCue,
        'haptic_cue': hapticCue,
        'onboarded': onboarded,
      };
}
