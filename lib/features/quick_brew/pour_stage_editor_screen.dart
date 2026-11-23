import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_confirm_dialog.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../core/widgets/pour_pattern_guide_sheet.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Screen 06 · Edit Tahapan (Preset Resep):
/// - Stored canonical Ratio (`_ratio`) so +0.5 / -0.5 is always 100% symmetric in Hot & Iced.
/// - Clean "Total Air" summary banner (no "Otomatis" jargon) + manual override sheet.
/// - Custom Ice Weight in grams (`− 5g / + 5g` + tap to type exact grams + % presets) in Iced mode.
/// - Per-stage independent water ml (`_stageWaterMl`): adding/deleting stages NEVER auto-redistributes
///   existing stages; new stages start at 0 ml with a live allocation guide bar + optional "Bagi Rata".
/// - No Grinder recommendation here (handled directly on the Brew screen).
class PourStageEditorScreen extends ConsumerStatefulWidget {
  const PourStageEditorScreen({
    super.key,
    this.recipeId,
    this.createNew = false,
  });

  final String? recipeId;
  final bool createNew;

  @override
  ConsumerState<PourStageEditorScreen> createState() =>
      _PourStageEditorScreenState();
}

class _PourStageEditorScreenState extends ConsumerState<PourStageEditorScreen> {
  late BrewRecipe _baseRecipe;
  late TextEditingController _nameCtrl;
  late TextEditingController _summaryCtrl;
  late BrewMode _mode;
  late double _doseG;
  late double _ratio;
  double? _manualTotalWaterG;
  late double _iceG;
  late int _tempC;
  late List<PourStage> _stages;
  late List<double> _stageWaterMl;
  late List<TextEditingController> _stageLabelCtrls;
  int _expandedIdx = 0;

  @override
  void initState() {
    super.initState();
    final store = ref.read(pocketStoreProvider);
    final recipe = widget.recipeId != null
        ? store.recipes.firstWhere(
            (r) => r.id == widget.recipeId,
            orElse: () => store.activeRecipe,
          )
        : store.activeRecipe;
    _baseRecipe = recipe;
    _initFromRecipe(recipe, isCreateNew: widget.createNew);
  }

  void _initFromRecipe(BrewRecipe recipe, {required bool isCreateNew}) {
    _mode = recipe.mode;
    _doseG = ((recipe.doseG * 10).round() / 10.0).clamp(5.0, 60.0);
    _ratio = ((recipe.ratio * 10).round() / 10.0).clamp(10.0, 22.0);
    _manualTotalWaterG = null;
    _tempC = recipe.tempC.clamp(75, 100);

    final initIceRatio = _mode == BrewMode.iced
        ? BrewRecipeScaler.clampIceRatio(
            recipe.iceRatio > 0 ? recipe.iceRatio : 0.40,
          )
        : 0.40;
    final totalWater = (_doseG * _ratio).roundToDouble();
    _iceG = (totalWater * initIceRatio).roundToDouble();

    _nameCtrl = TextEditingController(
      text: isCreateNew
          ? (_mode == BrewMode.iced
              ? 'Japanese Iced Custom'
              : 'Resep V60 Baru')
          : (recipe.isOfficial ? '${recipe.name} · Custom' : recipe.name),
    );
    _summaryCtrl = TextEditingController(
      text: isCreateNew ? '' : recipe.summary,
    );

    _stages = List<PourStage>.from(recipe.stages);
    _stageWaterMl = _computeInitialStageWater(_stages, _hotWaterG);
    _stageLabelCtrls =
        _stages.map((s) => TextEditingController(text: s.label)).toList();
    _expandedIdx = 0;
  }

  List<double> _computeInitialStageWater(
    List<PourStage> stages,
    double targetHotWater,
  ) {
    if (stages.isEmpty) return [];
    final result = <double>[];
    double prevCum = 0;
    for (int i = 0; i < stages.length; i++) {
      final cum = i == stages.length - 1
          ? targetHotWater.roundToDouble()
          : (targetHotWater * stages[i].targetCumulativePct).roundToDouble();
      final delta = (cum - prevCum).clamp(0.0, 1200.0);
      result.add(delta);
      prevCum = cum;
    }
    return result;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _summaryCtrl.dispose();
    for (final ctrl in _stageLabelCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  double get _totalLiquidG =>
      (_manualTotalWaterG ?? (_doseG * _ratio).roundToDouble())
          .clamp(60.0, 1500.0);

  double get _minIceG => (_totalLiquidG * BrewRecipeScaler.minIceRatio)
      .roundToDouble()
      .clamp(10.0, 800.0);

  double get _maxIceG => (_totalLiquidG * BrewRecipeScaler.maxIceRatio)
      .roundToDouble()
      .clamp(_minIceG + 5.0, 900.0);

  double get _activeIceG =>
      _mode == BrewMode.iced ? _iceG.clamp(_minIceG, _maxIceG) : 0.0;

  double get _iceRatio => _mode == BrewMode.iced && _totalLiquidG > 0
      ? BrewRecipeScaler.clampIceRatio(_activeIceG / _totalLiquidG)
      : 0.0;

  double get _hotWaterG => _mode == BrewMode.iced
      ? (_totalLiquidG - _activeIceG).clamp(40.0, 1200.0)
      : _totalLiquidG.clamp(40.0, 1200.0);

  double get _allocatedWaterG =>
      _stageWaterMl.fold<double>(0.0, (sum, ml) => sum + ml);

  String _formatRatio(double r) {
    final isWhole = (r - r.roundToDouble()).abs() < 0.05;
    return isWhole ? '1:${r.round()}' : '1:${r.toStringAsFixed(1)}';
  }

  void _stepDose(double delta) {
    HapticFeedback.selectionClick();
    final prevIceRatio = _mode == BrewMode.iced ? _iceRatio : 0.40;
    setState(() {
      _doseG = (((_doseG + delta) * 10).round() / 10.0).clamp(5.0, 60.0);
      _manualTotalWaterG = null;
      if (_mode == BrewMode.iced) {
        _iceG = (_totalLiquidG * prevIceRatio).roundToDouble();
      }
    });
  }

  void _stepRatio(double delta) {
    HapticFeedback.selectionClick();
    final prevIceRatio = _mode == BrewMode.iced ? _iceRatio : 0.40;
    setState(() {
      _ratio = (((_ratio + delta) * 10).round() / 10.0).clamp(10.0, 22.0);
      _manualTotalWaterG = null;
      if (_mode == BrewMode.iced) {
        _iceG = (_totalLiquidG * prevIceRatio).roundToDouble();
      }
    });
  }

  void _setIceGrams(double nextGrams) {
    setState(() {
      _iceG = nextGrams.roundToDouble().clamp(_minIceG, _maxIceG);
    });
  }

  void _setIcePercent(double pct) {
    HapticFeedback.selectionClick();
    final clampedPct = BrewRecipeScaler.clampIceRatio(pct);
    setState(() {
      _iceG = (_totalLiquidG * clampedPct).roundToDouble();
    });
  }

  void _resetToBase() {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = _baseRecipe.mode;
      _doseG = ((_baseRecipe.doseG * 10).round() / 10.0).clamp(5.0, 60.0);
      _ratio = ((_baseRecipe.ratio * 10).round() / 10.0).clamp(10.0, 22.0);
      _manualTotalWaterG = null;
      _tempC = _baseRecipe.tempC.clamp(75, 100);
      final baseIceRatio = _baseRecipe.iceRatio > 0
          ? BrewRecipeScaler.clampIceRatio(_baseRecipe.iceRatio)
          : 0.40;
      _iceG = (_totalLiquidG * baseIceRatio).roundToDouble();
      _summaryCtrl.text = _baseRecipe.summary;
      _stages = List<PourStage>.from(_baseRecipe.stages);
      _stageWaterMl = _computeInitialStageWater(_stages, _hotWaterG);
      for (final ctrl in _stageLabelCtrls) {
        ctrl.dispose();
      }
      _stageLabelCtrls =
          _stages.map((s) => TextEditingController(text: s.label)).toList();
      _expandedIdx = 0;
    });
  }

  /// Adds a new stage starting at 0 ml WITHOUT altering any existing stage's water!
  void _addStage() {
    HapticFeedback.lightImpact();
    final last = _stages.isNotEmpty ? _stages.last : null;
    final start = last?.endSec ?? 0;
    final nextOrder = _stages.length + 1;
    final defaultTitle = 'Tuangan $nextOrder';
    setState(() {
      _stages.add(
        PourStage(
          order: nextOrder,
          label: defaultTitle,
          startSec: start,
          pourEndSec: start + 12,
          endSec: start + 35,
          targetCumulativePct: 1.0,
          pattern: PourPattern.spiral,
          rate: PourRate.medium,
          cue: 'Tuang spiral stabil di tengah bed kopi.',
        ),
      );
      _stageWaterMl.add(0.0);
      _stageLabelCtrls.add(TextEditingController(text: defaultTitle));
      _expandedIdx = _stages.length - 1;
    });
  }

  /// Deletes stage [index] after confirmation WITHOUT altering remaining stages' water!
  Future<void> _removeStage(int index) async {
    if (_stages.length <= 1) return;
    final stageName = _stages[index].label;
    final ok = await showPocketDeleteDialog(
      context,
      title: 'Hapus Tahap Tuangan?',
      message:
          'Hapus tahap "${stageName.isEmpty ? 'Tahap ${index + 1}' : stageName}" dari resep ini?',
      confirmLabel: 'Hapus Tahap',
    );
    if (!ok || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _stages.removeAt(index);
      _stageWaterMl.removeAt(index);
      final removedCtrl = _stageLabelCtrls.removeAt(index);
      removedCtrl.dispose();
      _stages = List.generate(
        _stages.length,
        (i) => _stages[i].copyWith(order: i + 1),
      );
      if (_expandedIdx >= _stages.length) {
        _expandedIdx = _stages.length - 1;
      }
    });
  }

  /// Optional user-triggered action to distribute target hot water evenly across all stages.
  void _distributeEvenly() {
    if (_stages.isEmpty) return;
    HapticFeedback.selectionClick();
    final target = _hotWaterG.round();
    final n = _stages.length;
    final baseShare = target ~/ n;
    final remainder = target - (baseShare * n);
    setState(() {
      _stageWaterMl = List.generate(
        n,
        (i) => (baseShare + (i == n - 1 ? remainder : 0)).toDouble(),
      );
    });
  }

  void _adjustStageWater(int index, double deltaMl) {
    HapticFeedback.selectionClick();
    setState(() {
      _stageWaterMl[index] =
          (_stageWaterMl[index] + deltaMl).roundToDouble().clamp(0.0, 1200.0);
    });
  }

  void _openTotalWaterSheet(UnitMode unit) {
    final isIced = _mode == BrewMode.iced;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditAmountSheet(
        title: isIced ? 'Atur Total Air (Panas + Es)' : 'Atur Total Air',
        subtitle:
            'Ketik jumlah total cairan untuk resep ini — rasio akan ikut menyesuaikan',
        initialValue: _totalLiquidG.round(),
        minValue: 60,
        maxValue: 1200,
        suffix: unit == UnitMode.gram ? 'g' : 'ml',
        presets: const [200, 225, 240, 250, 300],
        onApply: (ml) {
          final prevIceRatio = _mode == BrewMode.iced ? _iceRatio : 0.40;
          setState(() {
            _manualTotalWaterG = ml.toDouble();
            _ratio = (((ml / _doseG) * 10).round() / 10.0).clamp(6.0, 25.0);
            if (_mode == BrewMode.iced) {
              _iceG = (ml * prevIceRatio).roundToDouble();
            }
          });
        },
      ),
    );
  }

  void _openIceWeightSheet() {
    final minG = _minIceG.round();
    final maxG = _maxIceG.round();
    final presetCandidates = [60, 75, 85, 95, 100, 120]
        .where((g) => g >= minG && g <= maxG)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditAmountSheet(
        title: 'Atur Berat Es Batu',
        subtitle:
            'Rentang aman: $minG–$maxG g (15%–60% dari total ${_totalLiquidG.round()} ml)',
        initialValue: _activeIceG.round(),
        minValue: minG,
        maxValue: maxG,
        suffix: 'g',
        presets: presetCandidates.isEmpty
            ? [minG, ((minG + maxG) ~/ 2), maxG]
            : presetCandidates,
        onApply: (grams) => _setIceGrams(grams.toDouble()),
      ),
    );
  }

  void _openStageWaterSheet(int index, UnitMode unit) {
    final remaining = (_hotWaterG - _allocatedWaterG).round();
    final cur = _stageWaterMl[index].round();
    final fillExact = (cur + remaining).clamp(0, 1200);
    final presets = <int>{
      30,
      45,
      50,
      60,
      80,
      if (remaining > 0 && fillExact > 0) fillExact,
    }.toList()
      ..sort();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditAmountSheet(
        title: 'Volume Air · ${_stages[index].label}',
        subtitle: remaining > 0
            ? 'Sisa target air belum terisi: $remaining ${unit == UnitMode.gram ? 'g' : 'ml'}'
            : 'Atur jumlah air khusus tahap ${index + 1} tanpa mengubah tahap lain',
        initialValue: cur,
        minValue: 0,
        maxValue: 1200,
        suffix: unit == UnitMode.gram ? 'g' : 'ml',
        presets: presets.take(5).toList(),
        onApply: (ml) {
          setState(() => _stageWaterMl[index] = ml.toDouble());
        },
      ),
    );
  }

  void _save() {
    final totalAllocated = _allocatedWaterG;
    if (totalAllocated <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi volume air minimal pada 1 tahap tuangan dulu ya!'),
        ),
      );
      return;
    }

    final store = ref.read(pocketStoreProvider);
    final base = _baseRecipe;
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Resep V60 Custom'
        : _nameCtrl.text.trim();
    final targetDrawdown = _stages.isNotEmpty ? _stages.last.endSec : 180;
    final unit = store.prefs.unitMode;

    // Convert per-stage water allocations cleanly into monotonic cumulative %
    final builtStages = <PourStage>[];
    double runningCum = 0;
    for (int i = 0; i < _stages.length; i++) {
      runningCum += _stageWaterMl[i];
      final pct = i == _stages.length - 1
          ? 1.0
          : (runningCum / totalAllocated).clamp(0.0, 1.0);
                                      final resolvedLabel =
                                          _stageLabelCtrls[i].text.trim().isEmpty
                                              ? 'Tuangan ${i + 1}'
                                              : _stageLabelCtrls[i].text.trim();
                                      builtStages.add(
                                        _stages[i].copyWith(
                                          order: i + 1,
                                          label: resolvedLabel,
                                          targetCumulativePct: pct,
                                        ),
                                      );
    }

    final hotLabel = BrewRecipeScaler.formatLiquidCompact(_hotWaterG, unit);
    final autoSummary = _mode == BrewMode.iced
        ? '${builtStages.length} tahap · ${_formatRatio(_ratio)} · $hotLabel panas + ${_activeIceG.round()}g es · ~${BrewRecipeScaler.formatShortDuration(targetDrawdown)}'
        : '${builtStages.length} tahap · ${_formatRatio(_ratio)} · $hotLabel · ${BrewRecipeScaler.formatTemp(_tempC, store.prefs.tempUnit)}';
    final summary = _summaryCtrl.text.trim().isEmpty
        ? autoSummary
        : _summaryCtrl.text.trim();

    final saved = base.copyWith(
      id: (widget.createNew || base.isOfficial)
          ? 'custom-${const Uuid().v4().substring(0, 8)}'
          : base.id,
      name: name,
      author: store.prefs.userName.trim().isNotEmpty
          ? store.prefs.userName.trim()
          : 'Custom',
      mode: _mode,
      badge: _mode == BrewMode.iced ? 'Japanese' : 'Custom',
      isOfficial: false,
      summary: summary,
      doseG: _doseG,
      ratio: _ratio,
      waterG: _totalLiquidG,
      iceRatio: _mode == BrewMode.iced ? _iceRatio : 0.0,
      tempC: _tempC,
      targetDrawdownSec: targetDrawdown,
      grindOffsetUm: _baseRecipe.grindOffsetUm,
      stages: builtStages,
    );
    ref
        .read(pocketStoreProvider.notifier)
        .saveCustomRecipe(saved, activate: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resep "$name" disimpan & langsung dipakai ✓')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final store = ref.watch(pocketStoreProvider);
    final unit = store.prefs.unitMode;
    final isIced = _mode == BrewMode.iced;
    final accent = isIced ? c.brandIce : c.brandTerracotta;
    final accentInk = isIced ? c.brandIce : c.brandTerracottaInk;
    final accentTint = isIced ? c.tintIce : c.tintTerracotta;

    final targetHot = _hotWaterG;
    final allocated = _allocatedWaterG;
    final diff = (targetHot - allocated).round();
    final allocFraction =
        targetHot > 0 ? (allocated / targetHot).clamp(0.0, 1.0) : 0.0;
    final isExact = diff == 0;
    final isOver = diff < 0;
    final guideColor =
        isExact ? c.brandSage : (isOver ? c.statusError : accentInk);
    final guideBg = isExact
        ? c.tintSage
        : (isOver ? c.statusError.withValues(alpha: 0.11) : accentTint);
    final guideStatusText = isExact
        ? 'Terisi ${BrewRecipeScaler.formatLiquidCompact(allocated, unit)} / ${BrewRecipeScaler.formatLiquidCompact(targetHot, unit)} · pas!'
        : isOver
            ? 'Terisi ${BrewRecipeScaler.formatLiquidCompact(allocated, unit)} / ${BrewRecipeScaler.formatLiquidCompact(targetHot, unit)} · lebih ${BrewRecipeScaler.formatLiquidCompact(diff.abs().toDouble(), unit)}'
            : 'Terisi ${BrewRecipeScaler.formatLiquidCompact(allocated, unit)} / ${BrewRecipeScaler.formatLiquidCompact(targetHot, unit)} · sisa ${BrewRecipeScaler.formatLiquidCompact(diff.toDouble(), unit)}';

    // Precompute cumulative water per stage for clean display
    final cumulativeByStage = <double>[];
    double runSum = 0;
    for (final w in _stageWaterMl) {
      runSum += w;
      cumulativeByStage.add(runSum);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Edit Tahapan',
              onBack: () => context.pop(),
              trailing: PocketTapScale(
                onTap: _resetToBase,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    'Reset',
                    style: PocketTheme.ui(
                      size: 13,
                      weight: 700,
                      color: c.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  // 1. Editable Preset Parameters Card (Name, Desc, Mode, Dose, Ratio, Temp, Total Air, Ice)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Nama & Parameter Preset',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PocketTheme.ui(
                                  size: 12.5,
                                  weight: 700,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PocketPill(
                              label: 'Rasio ${_formatRatio(_ratio)}',
                              isMono: true,
                              backgroundColor: accentTint,
                              foregroundColor: accentInk,
                              fontSize: 10.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Disimpan sebagai preset resep. Saat Brew nanti kamu tetap bebas ubah dosis, rasio & klik grinder.',
                          style: PocketTheme.ui(
                            size: 10.8,
                            weight: 500,
                            height: 1.35,
                            color: c.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 9),
                        TextField(
                          controller: _nameCtrl,
                          style: PocketTheme.ui(
                            size: 14.5,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            hintText: 'Contoh: V60 Pagi Favorit',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _summaryCtrl,
                          minLines: 1,
                          maxLines: 2,
                          style: PocketTheme.ui(
                            size: 12.5,
                            weight: 500,
                            color: c.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            hintText:
                                'Catatan preset (opsional): mis. Cocok untuk light roast floral...',
                            hintMaxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Mode Toggle (Hot V60 / Japanese Iced)
                        Row(
                          children: [
                            Expanded(
                              child: _ModeOptionChip(
                                label: 'Hot V60',
                                icon: PocketIconType.flame,
                                active: !isIced,
                                activeBg: c.tintTerracotta,
                                activeFg: c.brandTerracottaInk,
                                onTap: () {
                                  if (!isIced) return;
                                  HapticFeedback.selectionClick();
                                  setState(() => _mode = BrewMode.hot);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModeOptionChip(
                                label: 'Japanese Iced',
                                icon: PocketIconType.snowflake,
                                active: isIced,
                                activeBg: c.tintIce,
                                activeFg: c.brandIce,
                                onTap: () {
                                  if (isIced) return;
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _mode = BrewMode.iced;
                                    _iceG = (_totalLiquidG * 0.40)
                                        .roundToDouble();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 3 Core Patokan Preset: Dosis | Rasio (stored!) | Suhu Air
                        Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: _ParamStepperTile(
                                label: 'Dosis',
                                value: BrewRecipeScaler.formatDose(_doseG),
                                onMinus: () => _stepDose(-0.5),
                                onPlus: () => _stepDose(0.5),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              flex: 11,
                              child: _ParamStepperTile(
                                label: 'Rasio (1:xx)',
                                value: _formatRatio(_ratio),
                                highlightColor: accentInk,
                                onMinus: () => _stepRatio(-0.5),
                                onPlus: () => _stepRatio(0.5),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              flex: 10,
                              child: _ParamStepperTile(
                                label: 'Suhu Air',
                                value: BrewRecipeScaler.formatTemp(
                                  _tempC,
                                  store.prefs.tempUnit,
                                ),
                                onMinus: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _tempC = (_tempC - 1).clamp(75, 100);
                                  });
                                },
                                onPlus: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _tempC = (_tempC + 1).clamp(75, 100);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Neutral Total Air Banner (NO "Air Panas Otomatis" wording!)
                        PocketTapScale(
                          onTap: () => _openTotalWaterSheet(unit),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: accentTint,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isIced
                                            ? 'Total Air: ${BrewRecipeScaler.formatLiquidCompact(_totalLiquidG, unit)} (${BrewRecipeScaler.formatLiquidCompact(_hotWaterG, unit)} panas + ${_activeIceG.round()}g es)'
                                            : 'Total Air: ${BrewRecipeScaler.formatLiquidCompact(_totalLiquidG, unit)}',
                                        style: PocketTheme.mono(
                                          size: 11.5,
                                          weight: FontWeight.w800,
                                          color: accentInk,
                                        ),
                                      ),
                                      Text(
                                        '${BrewRecipeScaler.formatDose(_doseG)} × ${_formatRatio(_ratio)} · Ketuk untuk atur manual',
                                        style: PocketTheme.ui(
                                          size: 10.2,
                                          weight: 500,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PocketIcon(
                                  PocketIconType.edit,
                                  size: 13,
                                  color: accentInk,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Ice Weight Control in grams + % presets (Japanese Iced mode)
                        AnimatedSize(
                          duration: PocketCurves.normal,
                          curve: PocketCurves.smoothOut,
                          child: isIced
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      color: c.tintIce,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: PocketTapScale(
                                                onTap: _openIceWeightSheet,
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        'Es Batu: ${_activeIceG.round()}g (${(_iceRatio * 100).round()}%)',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: PocketTheme.mono(
                                                          size: 11.5,
                                                          weight:
                                                              FontWeight.w800,
                                                          color: c.brandIce,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    PocketIcon(
                                                      PocketIconType.edit,
                                                      size: 12,
                                                      color: c.brandIce,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            _SecStepBtn(
                                              label: '−',
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                _setIceGrams(_activeIceG - 5);
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            _SecStepBtn(
                                              label: '+',
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                _setIceGrams(_activeIceG + 5);
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Ketuk angka es untuk isi berat gram custom (±5g atau pilih %)',
                                          style: PocketTheme.ui(
                                            size: 10,
                                            weight: 500,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            (0.30, '30% Es'),
                                            (0.35, '35% Es'),
                                            (0.40, '40% Es'),
                                          ].map((entry) {
                                            final (val, lbl) = entry;
                                            final act =
                                                (_iceRatio - val).abs() < 0.015;
                                            return Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  right: val < 0.40 ? 6 : 0,
                                                ),
                                                child: PocketPill(
                                                  label: lbl,
                                                  height: 26,
                                                  fontSize: 10.5,
                                                  isMono: true,
                                                  backgroundColor: act
                                                      ? c.brandIce
                                                      : c.surfaceCard,
                                                  foregroundColor: act
                                                      ? c.textOnAccent
                                                      : c.brandIce,
                                                  onTap: () =>
                                                      _setIcePercent(val),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Live Water Allocation Guide Bar + Optional "Bagi Rata"
                  Container(
                    padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
                    decoration: BoxDecoration(
                      color: guideBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: guideColor.withValues(alpha: 0.25),
                      ),
                    ),
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
                                    isIced
                                        ? 'Panduan Alokasi Air Panas'
                                        : 'Panduan Alokasi Air per Tahap',
                                    style: PocketTheme.ui(
                                      size: 11.5,
                                      weight: 700,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    guideStatusText,
                                    style: PocketTheme.mono(
                                      size: 11.2,
                                      weight: FontWeight.w800,
                                      color: guideColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PocketPill(
                              label: 'Bagi Rata',
                              height: 28,
                              fontSize: 11,
                              fontWeight: 700,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              backgroundColor: c.surfaceCard,
                              foregroundColor: c.textPrimary,
                              borderColor: c.borderSubtle,
                              onTap: _distributeEvenly,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: allocFraction,
                            minHeight: 5,
                            backgroundColor:
                                c.surfaceCard.withValues(alpha: 0.75),
                            color: guideColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  // 3. Smooth Animated Accordion Pour Stages (independent water per stage!)
                  ...List.generate(_stages.length, (i) {
                    final st = _stages[i];
                    final deltaWater = _stageWaterMl[i];
                    final cumWater = cumulativeByStage[i];
                    final pourSec = BrewRecipeScaler.pourDurationSec(st);
                    final expanded = i == _expandedIdx;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: PocketCurves.smoothOut,
                        decoration: BoxDecoration(
                          color: c.surfaceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: expanded ? accent : c.borderSubtle,
                            width: expanded ? 1.5 : 1.0,
                          ),
                          boxShadow: expanded && !c.isDark
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.09),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stage Header
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _expandedIdx = expanded ? -1 : i;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: PocketCurves.fast,
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: expanded
                                            ? accent
                                            : c.surfaceElevated,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${i + 1}',
                                        style: PocketTheme.mono(
                                          size: 12,
                                          weight: FontWeight.w800,
                                          color: expanded
                                              ? c.textOnAccent
                                              : c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            st.label.isEmpty
                                                ? 'Tuangan ${i + 1}'
                                                : st.label,
                                            style: PocketTheme.ui(
                                              size: 13.5,
                                              weight: 800,
                                              height: 1.25,
                                              color: c.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            deltaWater > 0
                                                ? '${BrewRecipeScaler.formatShortDuration(st.startSec)} · ${BrewRecipeScaler.formatPourPace(deltaWater, pourSec, unit)} · ${st.pattern.label}'
                                                : '${BrewRecipeScaler.formatShortDuration(st.startSec)} · Belum diisi air · ${st.pattern.label}',
                                            style: PocketTheme.mono(
                                              size: 10.5,
                                              color: deltaWater > 0
                                                  ? c.textTertiary
                                                  : c.brandHoney,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+${BrewRecipeScaler.formatLiquidCompact(deltaWater, unit)}',
                                      style: PocketTheme.mono(
                                        size: 12,
                                        weight: FontWeight.w800,
                                        color: deltaWater > 0
                                            ? accentInk
                                            : c.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedRotation(
                                      turns: expanded ? 0.25 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 240),
                                      curve: PocketCurves.smoothOut,
                                      child: PocketIcon(
                                        PocketIconType.chevronRight,
                                        size: 16,
                                        color: expanded
                                            ? accentInk
                                            : c.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Accordion Body
                            ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 280),
                                curve: PocketCurves.smoothOut,
                                alignment: Alignment.topCenter,
                                child: expanded
                                    ? Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          0,
                                          14,
                                          14,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),

                                            // Rename Stage Title Field (freely rename any stage!)
                                            TextField(
                                              controller: _stageLabelCtrls[i],
                                              onChanged: (val) {
                                                setState(() {
                                                  _stages[i] = st.copyWith(
                                                    label: val,
                                                  );
                                                });
                                              },
                                              style: PocketTheme.ui(
                                                size: 13,
                                                weight: 700,
                                                color: c.textPrimary,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                labelText:
                                                    'Judul Tahap ${i + 1}',
                                                hintText:
                                                    'Mis. Bloom, Tuangan 4, Rao Spin...',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // Independent Stage Water Control (editable on ALL stages!)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Air Tahap Ini',
                                                        style: PocketTheme.ui(
                                                          size: 10.5,
                                                          weight: 600,
                                                          color: c.textTertiary,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Kumulatif → ${BrewRecipeScaler.formatLiquidCompact(cumWater, unit)}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: PocketTheme.mono(
                                                          size: 11,
                                                          weight:
                                                              FontWeight.w600,
                                                          color:
                                                              c.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                _SecStepBtn(
                                                  label: '−',
                                                  onTap: () =>
                                                      _adjustStageWater(i, -5),
                                                ),
                                                const SizedBox(width: 6),
                                                PocketTapScale(
                                                  onTap: () =>
                                                      _openStageWaterSheet(
                                                    i,
                                                    unit,
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: accentTint,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      BrewRecipeScaler
                                                          .formatLiquidCompact(
                                                        deltaWater,
                                                        unit,
                                                      ),
                                                      style: PocketTheme.mono(
                                                        size: 12.5,
                                                        weight: FontWeight.w800,
                                                        color: accentInk,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                _SecStepBtn(
                                                  label: '+',
                                                  onTap: () =>
                                                      _adjustStageWater(i, 5),
                                                ),
                                                if (_stages.length > 1) ...[
                                                  const SizedBox(width: 10),
                                                  PocketTapScale(
                                                    onTap: () =>
                                                        _removeStage(i),
                                                    child: Text(
                                                      'Hapus',
                                                      style: PocketTheme.ui(
                                                        size: 12,
                                                        weight: 700,
                                                        color: c.statusError,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (diff > 0) ...[
                                              const SizedBox(height: 8),
                                              PocketPill(
                                                label:
                                                    '+ Isi sisa target (+${BrewRecipeScaler.formatLiquidCompact(diff.toDouble(), unit)})',
                                                height: 28,
                                                fontSize: 11,
                                                isMono: true,
                                                backgroundColor: c.tintSage,
                                                foregroundColor: c.brandSage,
                                                onTap: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setState(() {
                                                    _stageWaterMl[i] =
                                                        (_stageWaterMl[i] +
                                                                diff)
                                                            .clamp(0.0, 1200.0);
                                                  });
                                                },
                                              ),
                                            ],
                                            const SizedBox(height: 10),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Jenis Tuangan',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                PourInfoButton(
                                                  pattern: st.pattern,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children:
                                                  PourPattern.values.map((p) {
                                                final sel = st.pattern == p;
                                                return PocketPill(
                                                  label: p.label,
                                                  backgroundColor: sel
                                                      ? c.brandEspresso
                                                      : c.surfaceElevated,
                                                  foregroundColor: sel
                                                      ? c.textOnAccent
                                                      : c.textPrimary,
                                                  onTap: () {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    setState(() {
                                                      _stages[i] = st.copyWith(
                                                        pattern: p,
                                                      );
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                            const SizedBox(height: 10),

                                            Text(
                                              'Kecepatan & Durasi Tuangan',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children:
                                                  PourRate.values.map((r) {
                                                final sel = st.rate == r;
                                                final recSec = BrewRecipeScaler
                                                    .recommendedPourSec(
                                                  deltaWater > 0
                                                      ? deltaWater
                                                      : 40,
                                                  r,
                                                );
                                                return PocketPill(
                                                  label:
                                                      '${r.shortName} (~$recSec dtk)',
                                                  backgroundColor: sel
                                                      ? accentTint
                                                      : c.surfaceElevated,
                                                  foregroundColor: sel
                                                      ? accentInk
                                                      : c.textPrimary,
                                                  onTap: () {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    setState(() {
                                                      final maxAllowed =
                                                          (st.endSec -
                                                                  st.startSec)
                                                              .clamp(4, 90);
                                                      final appliedSec = recSec
                                                          .clamp(4, maxAllowed);
                                                      _stages[i] = st.copyWith(
                                                        rate: r,
                                                        pourEndSec:
                                                            st.startSec +
                                                                appliedSec,
                                                      );
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                            const SizedBox(height: 10),

                                            // Exact Pour Seconds Stepper
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: c.surfaceElevated,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Durasi Tuang',
                                                          style: PocketTheme.ui(
                                                            size: 10.5,
                                                            weight: 600,
                                                            color:
                                                                c.textTertiary,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Tuang ${BrewRecipeScaler.formatPourPace(deltaWater, pourSec, unit)}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              PocketTheme.mono(
                                                            size: 11.5,
                                                            weight:
                                                                FontWeight.w700,
                                                            color:
                                                                c.textPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _SecStepBtn(
                                                    label: '−',
                                                    onTap: () {
                                                      HapticFeedback
                                                          .selectionClick();
                                                      setState(() {
                                                        final nextSec =
                                                            (pourSec - 1)
                                                                .clamp(3, 90);
                                                        _stages[i] =
                                                            st.copyWith(
                                                          pourEndSec:
                                                              st.startSec +
                                                                  nextSec,
                                                        );
                                                      });
                                                    },
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                    ),
                                                    child: Text(
                                                      '$pourSec dtk',
                                                      style: PocketTheme.mono(
                                                        size: 12,
                                                        weight: FontWeight.w800,
                                                        color: accentInk,
                                                      ),
                                                    ),
                                                  ),
                                                  _SecStepBtn(
                                                    label: '+',
                                                    onTap: () {
                                                      HapticFeedback
                                                          .selectionClick();
                                                      setState(() {
                                                        final nextSec =
                                                            (pourSec + 1)
                                                                .clamp(3, 90);
                                                        final newPourEnd =
                                                            st.startSec +
                                                                nextSec;
                                                        _stages[i] =
                                                            st.copyWith(
                                                          pourEndSec:
                                                              newPourEnd,
                                                          endSec: newPourEnd >
                                                                  st.endSec
                                                              ? newPourEnd
                                                              : st.endSec,
                                                        );
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  PocketTapScale(
                    onTap: _addStage,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.borderStrong),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PocketIcon(
                            PocketIconType.plus,
                            size: 16,
                            color: c.textPrimary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Tambah Tahap Tuangan',
                            style: PocketTheme.ui(
                              size: 13.5,
                              weight: 700,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: 'Simpan & Pakai Resep',
                pocketIcon: PocketIconType.check,
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                height: 52,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOptionChip extends StatelessWidget {
  const _ModeOptionChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeBg,
    required this.activeFg,
    required this.onTap,
  });

  final String label;
  final PocketIconType icon;
  final bool active;
  final Color activeBg;
  final Color activeFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PocketCurves.fast,
        curve: PocketCurves.smoothOut,
        height: 36,
        decoration: BoxDecoration(
          color: active ? activeBg : c.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                active ? activeFg.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PocketIcon(
                icon,
                size: 14,
                color: active ? activeFg : c.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: PocketTheme.ui(
                  size: 12,
                  weight: 700,
                  color: active ? activeFg : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParamStepperTile extends StatelessWidget {
  const _ParamStepperTile({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.highlightColor,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PocketTheme.ui(
              size: 10,
              weight: 600,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniRoundBtn(label: '−', onTap: onMinus),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      value,
                      style: PocketTheme.mono(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: highlightColor ?? c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              _MiniRoundBtn(label: '+', onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniRoundBtn extends StatelessWidget {
  const _MiniRoundBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.86,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: c.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(color: c.borderSubtle),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: PocketTheme.mono(
            size: 13,
            weight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SecStepBtn extends StatelessWidget {
  const _SecStepBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.88,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: c.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(color: c.borderSubtle),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: PocketTheme.mono(
            size: 15,
            weight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _EditAmountSheet extends StatefulWidget {
  const _EditAmountSheet({
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.suffix,
    required this.presets,
    required this.onApply,
  });

  final String title;
  final String subtitle;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final String suffix;
  final List<int> presets;
  final ValueChanged<int> onApply;

  @override
  State<_EditAmountSheet> createState() => _EditAmountSheetState();
}

class _EditAmountSheetState extends State<_EditAmountSheet> {
  late int _value;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    _ctrl = TextEditingController(text: '$_value');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setVal(int next, {bool syncText = true}) {
    final safe = next.clamp(widget.minValue, widget.maxValue);
    setState(() {
      _value = safe;
      if (syncText) {
        _ctrl.text = '$safe';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: PocketTheme.ui(
                  size: 16,
                  weight: 800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: PocketTheme.ui(
                  size: 11.5,
                  weight: 500,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: PocketTheme.mono(
                  size: 26,
                  weight: FontWeight.w800,
                  color: c.brandTerracottaInk,
                ),
                decoration: InputDecoration(
                  suffixText: widget.suffix,
                  suffixStyle: PocketTheme.mono(
                    size: 14,
                    weight: FontWeight.w600,
                    color: c.textTertiary,
                  ),
                ),
                onChanged: (raw) {
                  final parsed = int.tryParse(raw);
                  if (parsed != null) {
                    _setVal(parsed, syncText: false);
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                alignment: WrapAlignment.center,
                children: widget.presets.map((preset) {
                  final active = _value == preset;
                  return PocketPill(
                    label: '$preset ${widget.suffix}',
                    isMono: true,
                    height: 32,
                    backgroundColor:
                        active ? c.brandEspresso : c.surfaceElevated,
                    foregroundColor: active ? c.textOnAccent : c.textPrimary,
                    onTap: () => _setVal(preset),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              PocketButton(
                label: 'Terapkan $_value ${widget.suffix}',
                height: 46,
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                onTap: () {
                  widget.onApply(_value);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
