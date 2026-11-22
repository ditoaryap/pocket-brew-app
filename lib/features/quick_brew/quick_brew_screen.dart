import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/bean_picker_sheet.dart';
import '../../core/widgets/canvas/click_ruler_widget.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_confirm_dialog.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../core/widgets/pour_pattern_guide_sheet.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/engines/delta_micron_grinder_engine.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Screens 04 (Hot V60) & 05 (Japanese Iced 2-Opsi):
/// - Bean selector bar always available in BOTH Hot V60 & Japanese Iced
/// - Sliding capsule mode switch & 2-option Ice Order toggle
/// - Flexible grinder clicks (0–250, tappable for custom input + smooth ruler)
/// - Vertical pour stage schedule list for effortless scanning while pouring
/// - 0.1g Dose stepper + tappable custom input & Custom Ratio / Target Water sheet.
class QuickBrewScreen extends ConsumerStatefulWidget {
  const QuickBrewScreen({super.key});

  @override
  ConsumerState<QuickBrewScreen> createState() => _QuickBrewScreenState();
}

class _QuickBrewScreenState extends ConsumerState<QuickBrewScreen> {
  int _lastIcePctHaptic = -1;

  String _shortRecipeTitle(String name) {
    if (name.contains('Better 1-Cup')) return 'Hoffmann 1-Cup';
    if (name.contains('·')) return name.split('·').last.trim();
    return name;
  }

  String _formatRatioChip(double ratio) {
    final isWhole = (ratio - ratio.roundToDouble()).abs() < 0.05;
    return isWhole ? '1:${ratio.round()}' : '1:${ratio.toStringAsFixed(1)}';
  }

  void _showTempPickerSheet(BuildContext context, int currentTempC) {
    final c = context.colors;
    final notifier = ref.read(pocketStoreProvider.notifier);
    final tempUnit = ref.read(pocketStoreProvider).prefs.tempUnit;
    int temp = currentTempC;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return _QuickInputSheetContainer(
            title: 'Atur Suhu Air Seduh',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundStepButton(
                      icon: PocketIconType.minus,
                      size: 42,
                      iconSize: 17,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setSheet(() => temp = (temp - 1).clamp(75, 100));
                        notifier.updateDraft(tempC: temp);
                      },
                    ),
                    const SizedBox(width: 24),
                    Text(
                      BrewRecipeScaler.formatTemp(temp, tempUnit),
                      style: PocketTheme.mono(
                        size: 32,
                        weight: FontWeight.w700,
                        color: c.brandTerracottaInk,
                      ),
                    ),
                    const SizedBox(width: 24),
                    _RoundStepButton(
                      icon: PocketIconType.plus,
                      size: 42,
                      iconSize: 17,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setSheet(() => temp = (temp + 1).clamp(75, 100));
                        notifier.updateDraft(tempC: temp);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  alignment: WrapAlignment.center,
                  children: [85, 88, 92, 94, 96, 98].map((preset) {
                    final active = temp == preset;
                    return PocketPill(
                      label: BrewRecipeScaler.formatTemp(preset, tempUnit),
                      isMono: true,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      backgroundColor:
                          active ? c.brandEspresso : c.surfaceElevated,
                      foregroundColor:
                          active ? c.textOnAccent : c.textPrimary,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setSheet(() => temp = preset);
                        notifier.updateDraft(tempC: temp);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCustomClickSheet(
    BuildContext context, {
    required GrinderSpec grinder,
    required int currentClick,
    required int recommendedClick,
    required Color accentColor,
  }) {
    final notifier = ref.read(pocketStoreProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomClickSheetBody(
        grinder: grinder,
        initialClick: currentClick,
        recommendedClick: recommendedClick,
        accentColor: accentColor,
        onChanged: (clicks) => notifier.updateDraft(clickSetting: clicks),
      ),
    );
  }

  void _showCustomDoseSheet(BuildContext context, double currentDoseG) {
    final notifier = ref.read(pocketStoreProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomDoseSheetBody(
        initialDoseG: currentDoseG,
        onChanged: (dose) => notifier.updateDraft(doseG: dose),
      ),
    );
  }

  void _showCustomRatioSheet(
    BuildContext context, {
    required bool isIced,
    required double doseG,
    required double currentRatio,
    required UnitMode unitMode,
  }) {
    final notifier = ref.read(pocketStoreProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomRatioSheetBody(
        isIced: isIced,
        doseG: doseG,
        initialRatio: currentRatio,
        unitMode: unitMode,
        formatRatioChip: _formatRatioChip,
        onChanged: (ratio) => notifier.updateDraft(ratio: ratio),
      ),
    );
  }

  /// Recomputes normalized cumulative % across stages from per-stage water volumes.
  List<PourStage> _rebuildSessionStages(
    List<PourStage> stages,
    List<double> stageWaters,
  ) {
    final total = stageWaters.fold<double>(0.0, (s, w) => s + w);
    double running = 0.0;
    return List.generate(stages.length, (i) {
      running += stageWaters[i];
      final pct = (i == stages.length - 1 || total <= 0)
          ? 1.0
          : (running / total).clamp(0.05, 0.99);
      return stages[i].copyWith(order: i + 1, targetCumulativePct: pct);
    });
  }

  void _openSessionStageSheet(
    BuildContext context, {
    required ScaledBrewPlan plan,
    required UnitMode unitMode,
    required Color accentColor,
    int? editIndex,
  }) {
    final notifier = ref.read(pocketStoreProvider.notifier);
    final existingStages = plan.stages.map((s) => s.stage).toList();
    final existingWaters = plan.stages.map((s) => s.deltaWaterG).toList();
    final isEdit = editIndex != null && editIndex < existingStages.length;

    final PourStage initialStage;
    final double initialWater;
    if (isEdit) {
      initialStage = existingStages[editIndex];
      initialWater = existingWaters[editIndex];
    } else {
      final last = existingStages.isNotEmpty ? existingStages.last : null;
      final start = last?.endSec ?? 0;
      final nextOrder = existingStages.length + 1;
      initialStage = PourStage(
        order: nextOrder,
        label: 'Tuangan $nextOrder',
        startSec: start,
        pourEndSec: start + 12,
        endSec: start + 35,
        targetCumulativePct: 1.0,
        pattern: PourPattern.spiral,
        rate: PourRate.medium,
        cue: 'Tuang spiral stabil di tengah bed kopi.',
      );
      initialWater = 40.0;
    }

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SessionStageSheet(
        isEdit: isEdit,
        stageNumber: isEdit ? editIndex + 1 : existingStages.length + 1,
        initialStage: initialStage,
        initialWaterMl: initialWater,
        unitMode: unitMode,
        accentColor: accentColor,
        onSave: (updatedStage, waterMl) {
          final nextStages = List<PourStage>.from(existingStages);
          final nextWaters = List<double>.from(existingWaters);
          if (isEdit) {
            nextStages[editIndex] = updatedStage;
            nextWaters[editIndex] = waterMl;
          } else {
            nextStages.add(updatedStage);
            nextWaters.add(waterMl);
          }
          notifier.setSessionStages(
            _rebuildSessionStages(nextStages, nextWaters),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteSessionStage(
    BuildContext context, {
    required ScaledBrewPlan plan,
    required int index,
  }) async {
    if (plan.stages.length <= 1) return;
    final st = plan.stages[index].stage;
    final ok = await showPocketDeleteDialog(
      context,
      title: 'Hapus Tahap Sesi Ini?',
      message:
          'Hapus "${st.label}" hanya untuk sesi seduh kali ini? Preset resep aslinya tidak akan berubah.',
      confirmLabel: 'Hapus Tahap',
    );
    if (!ok) return;
    final nextStages = plan.stages.map((s) => s.stage).toList()
      ..removeAt(index);
    final nextWaters = plan.stages.map((s) => s.deltaWaterG).toList()
      ..removeAt(index);
    ref.read(pocketStoreProvider.notifier).setSessionStages(
          _rebuildSessionStages(nextStages, nextWaters),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);

    final draft = state.draft;
    final plan = state.currentPlan;
    final grinder = state.activeGrinder;
    final recipe = state.activeRecipe;
    final isIced = draft.mode == BrewMode.iced;

    final accent = isIced ? c.brandIce : c.brandTerracotta;
    final accentInk = isIced ? c.brandIce : c.brandTerracottaInk;
    final tint = isIced ? c.tintIce : c.tintTerracotta;

    final rec = DeltaMicronGrinderEngine.recommend(
      grinder: grinder,
      recipe: recipe,
      filter: state.activeFilter,
      overrideMode: draft.mode,
    );
    final approxUm =
        DeltaMicronGrinderEngine.estimateMicrons(grinder, draft.clickSetting);
    final activeBean = state.activeBean ??
        state.beans.where((b) => !b.isFrozen).firstOrNull ??
        state.beans.firstOrNull;
    final beanInfo = activeBean != null
        ? BeanRestingCalculator.evaluate(
            bean: activeBean,
            prefs: state.prefs,
          )
        : null;

    final hotPct = ((1 - plan.iceRatio) * 100).round();
    final icePct = (plan.iceRatio * 100).round();

    // Detect if user dialed a custom non-preset ratio (unified 1:xx format for Hot & Iced!)
    final isHotPreset = (draft.ratio - 15.0).abs() < 0.25 ||
        (draft.ratio - 16.67).abs() < 0.25 ||
        (draft.ratio - 17.0).abs() < 0.2;
    final isIcedPreset = (draft.ratio - 14.0).abs() < 0.25 ||
        (draft.ratio - 15.0).abs() < 0.35 ||
        (draft.ratio - 16.0).abs() < 0.25;
    final isCustomRatio = isIced ? !isIcedPreset : !isHotPreset;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 98),
          children: [
            // Top bar: Brew + g/ml/oz sliding pill + Metode pill
            SizedBox(
              height: isIced ? 42 : 44,
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Brew',
                        maxLines: 1,
                        style: PocketTheme.ui(
                          size: isIced ? 22 : 23,
                          weight: 700,
                          letterSpacing: -0.27,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  UnitPillSelector(
                    value: state.prefs.unitMode,
                    onChanged: notifier.setUnitMode,
                  ),
                  const SizedBox(width: 7),
                  PocketPill(
                    label: 'Metode',
                    pocketIcon: PocketIconType.recipe,
                    iconSize: 14,
                    height: 34,
                    backgroundColor: isIced ? c.tintIce : c.surfaceCard,
                    foregroundColor: isIced ? c.brandIce : c.textPrimary,
                    borderColor: !isIced && c.isDark ? c.borderSubtle : null,
                    elevated: !isIced,
                    fontSize: 12,
                    fontWeight: 600,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    onTap: () => context.push('/methods'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Smooth Sliding Capsule Mode Switch: Hot V60 <-> Japanese Iced (`h=48`)
            _SlidingCapsuleSwitch(
              isRightSelected: isIced,
              leftLabel: 'Hot V60',
              leftIcon: PocketIconType.flame,
              leftActiveColor: c.brandTerracottaInk,
              rightLabel: 'Japanese Iced',
              rightIcon: PocketIconType.snowflake,
              rightActiveColor: c.brandIce,
              onSelectLeft: () => notifier.selectBrewMode(BrewMode.hot),
              onSelectRight: () => notifier.selectBrewMode(BrewMode.iced),
            ),
            const SizedBox(height: 10),

            // ACTIVE BEAN BAR — ALWAYS VISIBLE in BOTH Hot V60 AND Japanese Iced!
            PocketCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: 18,
              elevated: false,
              onTap: () => showBeanPickerSheet(context, ref),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isIced ? c.tintIce : c.tintSage,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: PocketIcon(
                      PocketIconType.bean,
                      size: 17,
                      color: isIced ? c.brandIce : c.brandSage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeBean?.name ?? 'Pilih Biji Kopi',
                          style: PocketTheme.ui(
                            size: 13.5,
                            weight: 700,
                            height: 1.25,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeBean != null && beanInfo != null
                              ? '${activeBean.remainingG.round()}g stok · ${beanInfo.badgeText} · ${activeBean.process}'
                              : 'Ketuk untuk pilih atau tambah biji kopi',
                          style: PocketTheme.mono(
                            size: 11,
                            weight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ganti →',
                    style: PocketTheme.ui(
                      size: 12.5,
                      weight: 600,
                      color: accentInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // RESEP CARD: Dosis · Rasio · Suhu (Unified barista planning flow!)
            PocketCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              radius: 20,
              elevated: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Resep · Dosis, Rasio & Suhu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PocketTheme.ui(
                            size: 13,
                            weight: 700,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: PocketPill(
                            label: isIced
                                ? '${BrewRecipeScaler.formatLiquidCompact(plan.hotWaterG, state.prefs.unitMode)} panas + ${plan.iceG.round()}g es'
                                : 'Total ${BrewRecipeScaler.formatLiquidCompact(plan.totalLiquidG, state.prefs.unitMode)}',
                            isMono: true,
                            height: 24,
                            fontSize: 10.5,
                            fontWeight: 700,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            backgroundColor: tint,
                            foregroundColor: accentInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Dose Stepper (`0.1g` step + TAPPABLE custom input!) + Ratio Custom Pill
                  Row(
                    children: [
                      Container(
                        height: 46,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MiniStepCircle(
                              icon: PocketIconType.minus,
                              size: 38,
                              bg: c.surfaceCard,
                              fg: c.textPrimary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                notifier.updateDraft(doseG: draft.doseG - 0.1);
                              },
                            ),
                            PocketTapScale(
                              onTap: () =>
                                  _showCustomDoseSheet(context, draft.doseG),
                              pressedScale: 0.94,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 120),
                                      child: Text(
                                        BrewRecipeScaler.formatDose(
                                            draft.doseG),
                                        key: ValueKey(draft.doseG),
                                        style: PocketTheme.mono(
                                          size: 14.5,
                                          weight: FontWeight.w700,
                                          height: 1.1,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'ketuk · 0.1g',
                                      style: PocketTheme.ui(
                                        size: 8.5,
                                        weight: 600,
                                        height: 1.1,
                                        color: c.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _MiniStepCircle(
                              icon: PocketIconType.plus,
                              size: 38,
                              bg: c.brandEspresso,
                              fg: c.textOnAccent,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                notifier.updateDraft(doseG: draft.doseG + 0.1);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PocketTapScale(
                          onTap: () => _showCustomRatioSheet(
                            context,
                            isIced: isIced,
                            doseG: draft.doseG,
                            currentRatio: draft.ratio,
                            unitMode: state.prefs.unitMode,
                          ),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            decoration: BoxDecoration(
                              color: isCustomRatio
                                  ? (isIced ? c.brandIce : c.brandEspresso)
                                  : c.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCustomRatio
                                    ? Colors.transparent
                                    : c.borderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isCustomRatio
                                            ? 'Rasio Custom'
                                            : 'Rasio Air',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: PocketTheme.ui(
                                          size: 9.5,
                                          weight: 600,
                                          color: isCustomRatio
                                              ? c.textOnAccent
                                                  .withValues(alpha: 0.78)
                                              : c.textTertiary,
                                        ),
                                      ),
                                      Text(
                                        _formatRatioChip(draft.ratio),
                                        maxLines: 1,
                                        style: PocketTheme.mono(
                                          size: 13.5,
                                          weight: FontWeight.w700,
                                          color: isCustomRatio
                                              ? c.textOnAccent
                                              : c.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PocketIcon(
                                  PocketIconType.edit,
                                  size: 14,
                                  color: isCustomRatio
                                      ? c.textOnAccent
                                      : accentInk,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 4 Ratio Preset + Custom Chips Row (unified 1:xx for BOTH Hot V60 & Japanese Iced)
                  Row(
                    children: isIced
                        ? [
                            _RatioChip(
                              label: '1:14',
                              active: (draft.ratio - 14.0).abs() < 0.25,
                              activeColor: c.brandIce,
                              compact: true,
                              onTap: () => notifier.updateDraft(ratio: 14.0),
                            ),
                            const SizedBox(width: 6),
                            _RatioChip(
                              label: '1:15',
                              active: (draft.ratio - 15.0).abs() < 0.35,
                              activeColor: c.brandIce,
                              compact: true,
                              onTap: () => notifier.updateDraft(ratio: 15.0),
                            ),
                            const SizedBox(width: 6),
                            _RatioChip(
                              label: '1:16',
                              active: (draft.ratio - 16.0).abs() < 0.25,
                              activeColor: c.brandIce,
                              compact: true,
                              onTap: () => notifier.updateDraft(ratio: 16.0),
                            ),
                            const SizedBox(width: 6),
                            _RatioChip(
                              label: 'Custom',
                              active: isCustomRatio,
                              activeColor: c.brandIce,
                              compact: true,
                              onTap: () => _showCustomRatioSheet(
                                context,
                                isIced: true,
                                doseG: draft.doseG,
                                currentRatio: draft.ratio,
                                unitMode: state.prefs.unitMode,
                              ),
                            ),
                          ]
                        : [
                            _RatioChip(
                              label: '1:15',
                              active: (draft.ratio - 15.0).abs() < 0.25,
                              activeColor: c.brandEspresso,
                              onTap: () => notifier.updateDraft(ratio: 15.0),
                            ),
                            const SizedBox(width: 6),
                            _RatioChip(
                              label: '1:16.7',
                              flex: 12,
                              active: (draft.ratio - 16.67).abs() < 0.25,
                              activeColor: c.brandEspresso,
                              onTap: () => notifier.updateDraft(ratio: 16.67),
                            ),
                            const SizedBox(width: 6),
                            _RatioChip(
                              label: '1:17',
                              active: (draft.ratio - 17.0).abs() < 0.2,
                              activeColor: c.brandEspresso,
                              onTap: () => notifier.updateDraft(ratio: 17.0),
                            ),
                            const SizedBox(width: 6),
                            _RatioChip(
                              label: 'Custom',
                              flex: 11,
                              active: isCustomRatio,
                              activeColor: c.brandEspresso,
                              onTap: () => _showCustomRatioSheet(
                                context,
                                isIced: false,
                                doseG: draft.doseG,
                                currentRatio: draft.ratio,
                                unitMode: state.prefs.unitMode,
                              ),
                            ),
                          ],
                  ),
                  const SizedBox(height: 10),
                  // Suhu Air Row right inside the Recipe Card (tap temp for picker or step ±1°C)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        PocketIcon(
                          PocketIconType.flame,
                          size: 15,
                          color: accentInk,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: PocketTapScale(
                            onTap: () => _showTempPickerSheet(
                              context,
                              plan.tempC,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isIced ? 'Suhu Air Seduh (+2°C)' : 'Suhu Air Seduh',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PocketTheme.ui(
                                    size: 11,
                                    weight: 700,
                                    color: c.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Ketuk angka untuk pilih cepat',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PocketTheme.ui(
                                    size: 9.5,
                                    weight: 500,
                                    color: c.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _MiniStepCircle(
                          icon: PocketIconType.minus,
                          size: 30,
                          bg: c.surfaceCard,
                          fg: c.textPrimary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.updateDraft(tempC: plan.tempC - 1);
                          },
                        ),
                        PocketTapScale(
                          onTap: () => _showTempPickerSheet(context, plan.tempC),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              BrewRecipeScaler.formatTemp(
                                plan.tempC,
                                state.prefs.tempUnit,
                              ),
                              style: PocketTheme.mono(
                                size: 14,
                                weight: FontWeight.w800,
                                color: accentInk,
                              ),
                            ),
                          ),
                        ),
                        _MiniStepCircle(
                          icon: PocketIconType.plus,
                          size: 30,
                          bg: c.brandEspresso,
                          fg: c.textOnAccent,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.updateDraft(tempC: plan.tempC + 1);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2-Option Ice Order + Interactive Air Panas/Es Batu Card (smooth reveal in Japanese Iced mode)
            AnimatedSize(
              duration: PocketCurves.normal,
              curve: PocketCurves.smoothOut,
              alignment: Alignment.topCenter,
              child: isIced
                  ? Column(
                      key: const ValueKey('iced_controls_group'),
                      children: [
                        const SizedBox(height: 10),
                        PocketCard(
                          key: const ValueKey('iced_2options_card'),
                          backgroundColor: c.tintIce,
                          elevated: false,
                          radius: 18,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _IceOrderSlidingToggle(
                                selected: draft.icedMethod,
                                onChanged: (m) {
                                  HapticFeedback.selectionClick();
                                  notifier.updateDraft(icedMethod: m);
                                },
                              ),
                              const SizedBox(height: 7),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  key: ValueKey(draft.icedMethod),
                                  width: double.infinity,
                                  child: Text(
                                    plan.preBrewIceHint,
                                    style: PocketTheme.ui(
                                      size: 11,
                                      weight: 500,
                                      height: 1.41,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // CLEAR INTERACTIVE AIR PANAS vs ES BATU CARD
                        PocketCard(
                          key: const ValueKey('iced_split_card'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          radius: 18,
                          elevated: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Proporsi Air Panas vs Es Batu',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PocketTheme.ui(
                                        size: 13,
                                        weight: 700,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PocketPill(
                                    label: '$hotPct% / $icePct%',
                                    isMono: true,
                                    height: 22,
                                    fontSize: 11,
                                    fontWeight: 700,
                                    backgroundColor: c.tintIce,
                                    foregroundColor: c.brandIce,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final barW = constraints.maxWidth;
                                  void updateSplit(double dx) {
                                    final raw = 1.0 - (dx / barW);
                                    final clamped =
                                        BrewRecipeScaler.clampIceRatio(raw);
                                    final snapped =
                                        (clamped * 100).round() / 100.0;
                                    final pct = (snapped * 100).round();
                                    if (pct != _lastIcePctHaptic) {
                                      _lastIcePctHaptic = pct;
                                      HapticFeedback.selectionClick();
                                    }
                                    notifier.updateDraft(iceRatio: snapped);
                                  }

                                  final hotW =
                                      (barW - 4) * (1 - plan.iceRatio);
                                  final iceW = (barW - 4) * plan.iceRatio;

                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onHorizontalDragUpdate: (d) =>
                                        updateSplit(d.localPosition.dx),
                                    onTapDown: (d) =>
                                        updateSplit(d.localPosition.dx),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 140),
                                          curve: PocketCurves.smoothOut,
                                          width: hotW,
                                          height: 30,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: c.brandTerracotta,
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${BrewRecipeScaler.formatLiquidCompact(plan.hotWaterG, state.prefs.unitMode)} Panas',
                                              maxLines: 1,
                                              style: PocketTheme.mono(
                                                size: 10.5,
                                                weight: FontWeight.w700,
                                                color: c.textOnAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 140),
                                          curve: PocketCurves.smoothOut,
                                          width: iceW,
                                          height: 30,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: c.brandIce,
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${plan.iceG.round()}g Es',
                                              maxLines: 1,
                                              style: PocketTheme.mono(
                                                size: 10.5,
                                                weight: FontWeight.w700,
                                                color: c.textOnAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              // 3 Clear 1-Tap Ice Split Presets
                              Row(
                                children: [
                                  (0.30, '70/30 · Bold'),
                                  (0.35, '65/35 · Pas'),
                                  (0.40, '60/40 · Dingin'),
                                ].map((entry) {
                                  final (ratioVal, label) = entry;
                                  final active =
                                      (plan.iceRatio - ratioVal).abs() < 0.015;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: ratioVal < 0.40 ? 6 : 0,
                                      ),
                                      child: PocketTapScale(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          notifier.updateDraft(
                                            iceRatio: ratioVal,
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration: PocketCurves.fast,
                                          height: 30,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? c.brandIce
                                                : c.surfaceElevated,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              label,
                                              maxLines: 1,
                                              style: PocketTheme.ui(
                                                size: 10.5,
                                                weight: 700,
                                                color: active
                                                    ? c.textOnAccent
                                                    : c.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 4),
                              // Tactile Slider so user clearly sees they can fine-tune ice ratio!
                              Row(
                                children: [
                                  Text(
                                    '15% Es',
                                    style: PocketTheme.mono(
                                      size: 10,
                                      color: c.textTertiary,
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                          overlayRadius: 14,
                                        ),
                                      ),
                                      child: Slider(
                                        min: BrewRecipeScaler.minIceRatio,
                                        max: BrewRecipeScaler.maxIceRatio,
                                        divisions: 45,
                                        value: plan.iceRatio.clamp(
                                          BrewRecipeScaler.minIceRatio,
                                          BrewRecipeScaler.maxIceRatio,
                                        ),
                                        activeColor: c.brandIce,
                                        inactiveColor: c.surfaceElevated,
                                        onChanged: (v) {
                                          final snapped =
                                              (v * 100).round() / 100.0;
                                          final pct = (snapped * 100).round();
                                          if (pct != _lastIcePctHaptic) {
                                            _lastIcePctHaptic = pct;
                                            HapticFeedback.selectionClick();
                                          }
                                          notifier.updateDraft(
                                            iceRatio: snapped,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '60% Es',
                                    style: PocketTheme.mono(
                                      size: 10,
                                      color: c.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),

            // HERO GRINDER CLICK SCALE CARD (Tappable custom clicks + smooth ruler)
            PocketCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              radius: 22,
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxBadgeW =
                          constraints.maxWidth * (isIced ? 0.56 : 0.44);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: PocketTapScale(
                              onTap: () => context.go('/gear'),
                              child: Text(
                                isIced
                                    ? grinder.fullName
                                    : '${grinder.fullName} · ${grinder.umPerClick.round()} μm',
                                style: PocketTheme.ui(
                                  size: 12,
                                  weight: 600,
                                  height: 1.25,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxBadgeW),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: PocketPill(
                                label:
                                    isIced ? rec.badgeLabel : 'Saran kemarin ✓',
                                backgroundColor:
                                    isIced ? c.tintIce : c.tintSage,
                                foregroundColor:
                                    isIced ? c.brandIce : c.brandSage,
                                fontSize: isIced ? 10 : 10.5,
                                fontWeight: 600,
                                height: isIced ? 22 : 24,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 9),
                                isMono: isIced,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // − [21 klik / 18 klik — TAPPABLE FOR CUSTOM!] +
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _RoundStepButton(
                        icon: PocketIconType.minus,
                        size: 40,
                        iconSize: 16,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.updateDraft(
                            clickSetting: draft.clickSetting - 1,
                          );
                        },
                      ),
                      Expanded(
                        child: PocketTapScale(
                          pressedScale: 0.96,
                          onTap: () => _showCustomClickSheet(
                            context,
                            grinder: grinder,
                            currentClick: draft.clickSetting,
                            recommendedClick: rec.click,
                            accentColor: accentInk,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                switchInCurve: PocketCurves.smoothOut,
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.93, end: 1.0)
                                        .animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  '${draft.clickSetting} klik',
                                  key: ValueKey('${draft.clickSetting}_$isIced'),
                                  textAlign: TextAlign.center,
                                  style: PocketTheme.mono(
                                    size: isIced ? 34 : 36,
                                    weight: FontWeight.w700,
                                    height: 1.12,
                                    color: accentInk,
                                    letterSpacing: -0.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$approxUm μm · Ketuk angka untuk ubah bebas',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: PocketTheme.ui(
                                  size: 10.5,
                                  weight: 500,
                                  color: c.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _RoundStepButton(
                        icon: PocketIconType.plus,
                        size: 40,
                        iconSize: 16,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.updateDraft(
                            clickSetting: draft.clickSetting + 1,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),

                  ClickRulerWidget(
                    minClick: grinder.minClick,
                    maxClick: grinder.maxClick,
                    zoneMin: isIced
                        ? (grinder.v60HotMin - 3)
                            .clamp(grinder.minClick, grinder.maxClick)
                        : grinder.v60HotMin,
                    zoneMax: isIced
                        ? (grinder.v60HotMax - 3)
                            .clamp(grinder.minClick, grinder.maxClick)
                        : grinder.v60HotMax,
                    value: draft.clickSetting,
                    accentColor: accent,
                    tintColor: tint,
                    compact: isIced,
                    showLeftHalusLabel: true,
                    onChanged: (next) =>
                        notifier.updateDraft(clickSetting: next),
                  ),
                  const SizedBox(height: 11),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 2 Crisp Summary KPIs (Total Air tappable + Target Waktu)
                  Row(
                    children: [
                      Expanded(
                        child: PocketTapScale(
                          onTap: () => _showCustomRatioSheet(
                            context,
                            isIced: isIced,
                            doseG: draft.doseG,
                            currentRatio: draft.ratio,
                            unitMode: state.prefs.unitMode,
                          ),
                          child: _QuickKpi(
                            label: isIced ? 'Total Cairan' : 'Total Air',
                            value: BrewRecipeScaler.formatLiquidCompact(
                              plan.totalLiquidG,
                              state.prefs.unitMode,
                            ),
                            compact: isIced,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _QuickKpi(
                          label: 'Target Waktu',
                          value:
                              '~${BrewRecipeScaler.formatShortDuration(state.activeTargetDrawdownSec)}',
                          compact: isIced,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // VERTICAL POUR STAGES SCHEDULE CARD (With Session-Only Add / Edit / Delete!)
            PocketCard(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              radius: 20,
              elevated: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_shortRecipeTitle(recipe.name)} · ${plan.stages.length} Tahap',
                              style: PocketTheme.ui(
                                size: 13.5,
                                weight: 700,
                                height: 1.25,
                                color: c.textPrimary,
                              ),
                            ),
                            if (state.hasSessionStageOverrides) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  PocketPill(
                                    label: 'Tahap diubah sesi ini',
                                    height: 20,
                                    fontSize: 9.8,
                                    backgroundColor: c.tintSage,
                                    foregroundColor: c.brandSage,
                                  ),
                                  PocketTapScale(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      notifier.resetSessionStages();
                                    },
                                    child: Text(
                                      'Reset preset',
                                      style: PocketTheme.ui(
                                        size: 10.5,
                                        weight: 700,
                                        color: accentInk,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PocketPill(
                        label: 'Edit Preset',
                        pocketIcon: PocketIconType.edit,
                        iconSize: 13.5,
                        height: 28,
                        backgroundColor: tint,
                        foregroundColor: accentInk,
                        fontSize: 11.5,
                        fontWeight: 600,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        onTap: () => context.push('/brew/stages'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Ketuk tahap untuk ubah judul/air khusus sesi ini, atau tambah/hapus tahap tanpa mengubah preset asli.',
                    style: PocketTheme.ui(
                      size: 10.8,
                      weight: 500,
                      height: 1.38,
                      color: c.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Proportional multi-segment color bar (Sage Bloom + Accent Pours)
                  Row(
                    children: List.generate(plan.stages.length, (i) {
                      final st = plan.stages[i];
                      final weight = plan.hotWaterG > 0
                          ? (st.deltaWaterG / plan.hotWaterG * 100)
                              .round()
                              .clamp(12, 100)
                          : 20;
                      final segColor = i == 0 ? c.brandSage : accent;
                      return Expanded(
                        flex: weight,
                        child: AnimatedContainer(
                          duration: PocketCurves.normal,
                          curve: PocketCurves.smoothOut,
                          height: 8,
                          margin: EdgeInsets.only(
                            right: i < plan.stages.length - 1 ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: segColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  // Clean Vertical Step-by-Step Pour List (tappable to edit, deletable for this session!)
                  ...List.generate(plan.stages.length, (i) {
                    final s = plan.stages[i];
                    final isBloom = i == 0;
                    final dotColor = isBloom ? c.brandSage : accent;
                    final pourSec = BrewRecipeScaler.pourDurationSec(s.stage);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < plan.stages.length - 1 ? 8 : 0,
                      ),
                      child: PocketTapScale(
                        pressedScale: 0.985,
                        onTap: () => _openSessionStageSheet(
                          context,
                          plan: plan,
                          unitMode: state.prefs.unitMode,
                          accentColor: accent,
                          editIndex: i,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: c.isDark
                                ? c.surfaceElevated.withValues(alpha: 0.6)
                                : c.surfaceCanvas.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: dotColor.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${s.stage.order}',
                                  style: PocketTheme.mono(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: isBloom ? c.brandSage : accentInk,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.stage.label,
                                      style: PocketTheme.ui(
                                        size: 12.2,
                                        weight: 700,
                                        height: 1.25,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${BrewRecipeScaler.formatShortDuration(s.stage.startSec)} · Tuang ${BrewRecipeScaler.formatPourPace(s.deltaWaterG, pourSec, state.prefs.unitMode)}',
                                      style: PocketTheme.mono(
                                        size: 10,
                                        weight: FontWeight.w500,
                                        color: c.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '→ ${BrewRecipeScaler.formatLiquidCompact(s.cumulativeWaterG, state.prefs.unitMode)}',
                                style: PocketTheme.mono(
                                  size: 11.5,
                                  weight: FontWeight.w700,
                                  color: isBloom ? c.brandSage : accentInk,
                                ),
                              ),
                              if (plan.stages.length > 1) ...[
                                const SizedBox(width: 6),
                                PocketTapScale(
                                  onTap: () => _confirmDeleteSessionStage(
                                    context,
                                    plan: plan,
                                    index: i,
                                  ),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color:
                                          c.statusError.withValues(alpha: 0.11),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 14,
                                      color: c.statusError,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  PocketTapScale(
                    onTap: () => _openSessionStageSheet(
                      context,
                      plan: plan,
                      unitMode: state.prefs.unitMode,
                      accentColor: accent,
                    ),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: c.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.borderSubtle),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PocketIcon(
                              PocketIconType.plus,
                              size: 14,
                              color: accentInk,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tambah Tahap (Sesi Ini)',
                              style: PocketTheme.ui(
                                size: 12,
                                weight: 700,
                                color: accentInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Wet-hand Primary CTA (`Mulai Brew` / `Mulai Brew Iced` -> opens "Siap-siap Seduh" checklist sheet!)
            PocketButton(
              label: isIced ? 'Mulai Brew Iced' : 'Mulai Brew',
              pocketIcon:
                  isIced ? PocketIconType.snowflake : PocketIconType.timer,
              iconSize: 16,
              backgroundColor: accent,
              foregroundColor: c.textOnAccent,
              height: isIced ? 50 : 52,
              fontSize: isIced ? 14 : 14.5,
              fontWeight: 600,
              onTap: () => _showPreBrewChecklistSheet(
                context,
                plan: plan,
                grinder: grinder,
                clickSetting: draft.clickSetting,
                approxUm: approxUm,
                beanName: activeBean?.name,
                unitMode: state.prefs.unitMode,
                tempUnit: state.prefs.tempUnit,
                accentColor: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreBrewChecklistSheet(
    BuildContext context, {
    required ScaledBrewPlan plan,
    required GrinderSpec grinder,
    required int clickSetting,
    required int approxUm,
    required String? beanName,
    required UnitMode unitMode,
    required TempUnit tempUnit,
    required Color accentColor,
  }) {
    final router = GoRouter.of(context);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PreBrewChecklistSheet(
        plan: plan,
        grinder: grinder,
        clickSetting: clickSetting,
        approxUm: approxUm,
        beanName: beanName,
        unitMode: unitMode,
        tempUnit: tempUnit,
        accentColor: accentColor,
        ratioLabel: _formatRatioChip(plan.ratio),
        onProceedToTimer: () {
          Navigator.of(ctx).pop();
          router.push('/timer');
        },
      ),
    );
  }
}

class _QuickInputSheetContainer extends StatelessWidget {
  const _QuickInputSheetContainer({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.borderSubtle),
        ),
        child: SingleChildScrollView(
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
                title,
                textAlign: TextAlign.center,
                style: PocketTheme.ui(
                  size: 16.5,
                  weight: 700,
                  color: c.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: PocketTheme.ui(
                    size: 11.5,
                    weight: 500,
                    color: c.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickKpi extends StatelessWidget {
  const _QuickKpi({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: PocketTheme.ui(
            size: compact ? 10.5 : 11,
            weight: 500,
            color: c.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: FittedBox(
            key: ValueKey(value),
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: PocketTheme.mono(
                size: compact ? 15 : 16,
                weight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlidingCapsuleSwitch extends StatelessWidget {
  const _SlidingCapsuleSwitch({
    required this.isRightSelected,
    required this.leftLabel,
    required this.leftIcon,
    required this.leftActiveColor,
    required this.rightLabel,
    required this.rightIcon,
    required this.rightActiveColor,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  final bool isRightSelected;
  final String leftLabel;
  final PocketIconType leftIcon;
  final Color leftActiveColor;
  final String rightLabel;
  final PocketIconType rightIcon;
  final Color rightActiveColor;
  final VoidCallback onSelectLeft;
  final VoidCallback onSelectRight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: PocketCurves.gentleSpring,
            alignment:
                isRightSelected ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: c.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF1F1915)
                                .withValues(alpha: 0.055),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isRightSelected) {
                      HapticFeedback.selectionClick();
                      onSelectLeft();
                    }
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            PocketIcon(
                              leftIcon,
                              size: 16,
                              color: !isRightSelected
                                  ? leftActiveColor
                                  : c.textSecondary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              leftLabel,
                              maxLines: 1,
                              style: PocketTheme.ui(
                                size: 13.5,
                                weight: !isRightSelected ? 600 : 500,
                                height: 1.15,
                                color: !isRightSelected
                                    ? leftActiveColor
                                    : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!isRightSelected) {
                      HapticFeedback.selectionClick();
                      onSelectRight();
                    }
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            PocketIcon(
                              rightIcon,
                              size: 16,
                              color: isRightSelected
                                  ? rightActiveColor
                                  : c.textSecondary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              rightLabel,
                              maxLines: 1,
                              style: PocketTheme.ui(
                                size: 13.5,
                                weight: isRightSelected ? 600 : 500,
                                height: 1.15,
                                color: isRightSelected
                                    ? rightActiveColor
                                    : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IceOrderSlidingToggle extends StatelessWidget {
  const _IceOrderSlidingToggle({
    required this.selected,
    required this.onChanged,
  });

  final IcedMethod selected;
  final ValueChanged<IcedMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isRight = selected == IcedMethod.brewFirst;
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: PocketCurves.gentleSpring,
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: c.brandIce,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Row(
            children: IcedMethod.values.map((m) {
              final active = m == selected;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(m),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          m.label,
                          maxLines: 1,
                          style: PocketTheme.ui(
                            size: 11.5,
                            weight: active ? 700 : 600,
                            color: active ? c.textOnAccent : c.brandIce,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  final PocketIconType icon;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.88,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: PocketIcon(
          icon,
          size: iconSize,
          color: c.textPrimary,
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}

class _MiniStepCircle extends StatelessWidget {
  const _MiniStepCircle({
    required this.icon,
    required this.size,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final PocketIconType icon;
  final double size;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.88,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: PocketIcon(icon, size: 16, color: fg, strokeWidth: 2.0),
      ),
    );
  }
}

class _RatioChip extends StatelessWidget {
  const _RatioChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
    this.compact = false,
    this.flex = 10,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final bool compact;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      flex: flex,
      child: PocketTapScale(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: PocketCurves.fast,
          curve: PocketCurves.smoothOut,
          height: compact ? 36 : 38,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: active ? activeColor : c.surfaceCard,
            borderRadius: BorderRadius.circular(compact ? 11 : 12),
            border: !active && c.isDark
                ? Border.all(color: c.borderSubtle, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: PocketTheme.mono(
                size: compact ? 11.5 : 12,
                weight: FontWeight.w600,
                color: active ? c.textOnAccent : c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomClickSheetBody extends StatefulWidget {
  const _CustomClickSheetBody({
    required this.grinder,
    required this.initialClick,
    required this.recommendedClick,
    required this.accentColor,
    required this.onChanged,
  });

  final GrinderSpec grinder;
  final int initialClick;
  final int recommendedClick;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  State<_CustomClickSheetBody> createState() => _CustomClickSheetBodyState();
}

class _CustomClickSheetBodyState extends State<_CustomClickSheetBody> {
  late int _clicks;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _clicks = widget.initialClick;
    _ctrl = TextEditingController(text: '${widget.initialClick}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _applyClick(int next, {bool syncText = true}) {
    final safe = next.clamp(0, 250);
    setState(() {
      _clicks = safe;
      if (syncText) {
        _ctrl.text = '$safe';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      }
    });
    widget.onChanged(safe);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final estUm = DeltaMicronGrinderEngine.estimateMicrons(
      widget.grinder,
      _clicks,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _QuickInputSheetContainer(
        title: 'Atur Klik Grinder (Custom)',
        subtitle:
            '${widget.grinder.fullName} · ${widget.grinder.umPerClick.round()} μm/klik (bebas 0–250 klik)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _RoundStepButton(
                  icon: PocketIconType.minus,
                  size: 42,
                  iconSize: 17,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _applyClick(_clicks - 1);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: PocketTheme.mono(
                      size: 26,
                      weight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'klik',
                      suffixStyle: PocketTheme.mono(
                        size: 13,
                        weight: FontWeight.w600,
                        color: c.textTertiary,
                      ),
                    ),
                    onChanged: (raw) {
                      final parsed = int.tryParse(raw);
                      if (parsed != null) {
                        _applyClick(parsed, syncText: false);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _RoundStepButton(
                  icon: PocketIconType.plus,
                  size: 42,
                  iconSize: 17,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _applyClick(_clicks + 1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Perkiraan ukuran gilingan: ~$estUm μm',
              style: PocketTheme.mono(
                size: 11.5,
                weight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.center,
              children: [
                PocketPill(
                  label: '-5',
                  isMono: true,
                  height: 32,
                  onTap: () => _applyClick(_clicks - 5),
                ),
                PocketPill(
                  label: '-2',
                  isMono: true,
                  height: 32,
                  onTap: () => _applyClick(_clicks - 2),
                ),
                PocketPill(
                  label: 'Rekomendasi (${widget.recommendedClick})',
                  backgroundColor: c.tintSage,
                  foregroundColor: c.brandSage,
                  height: 32,
                  onTap: () => _applyClick(widget.recommendedClick),
                ),
                PocketPill(
                  label: '+2',
                  isMono: true,
                  height: 32,
                  onTap: () => _applyClick(_clicks + 2),
                ),
                PocketPill(
                  label: '+5',
                  isMono: true,
                  height: 32,
                  onTap: () => _applyClick(_clicks + 5),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PocketButton(
              label: 'Terapkan $_clicks klik',
              height: 46,
              backgroundColor: c.brandEspresso,
              foregroundColor: c.textOnAccent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomDoseSheetBody extends StatefulWidget {
  const _CustomDoseSheetBody({
    required this.initialDoseG,
    required this.onChanged,
  });

  final double initialDoseG;
  final ValueChanged<double> onChanged;

  @override
  State<_CustomDoseSheetBody> createState() => _CustomDoseSheetBodyState();
}

class _CustomDoseSheetBodyState extends State<_CustomDoseSheetBody> {
  late double _dose;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _dose = widget.initialDoseG;
    _ctrl = TextEditingController(text: widget.initialDoseG.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _applyDose(double next, {bool syncText = true}) {
    final safe = ((next * 10).round() / 10.0).clamp(1.0, 120.0);
    setState(() {
      _dose = safe;
      if (syncText) {
        _ctrl.text = safe.toStringAsFixed(1);
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      }
    });
    widget.onChanged(safe);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _QuickInputSheetContainer(
        title: 'Atur Dosis Kopi (Custom)',
        subtitle: 'Ketik angka bebas dengan presisi 0.1g',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _RoundStepButton(
                  icon: PocketIconType.minus,
                  size: 42,
                  iconSize: 17,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _applyDose(_dose - 0.1);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: PocketTheme.mono(
                      size: 26,
                      weight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'g',
                      suffixStyle: PocketTheme.mono(
                        size: 14,
                        weight: FontWeight.w700,
                        color: c.textTertiary,
                      ),
                    ),
                    onChanged: (raw) {
                      final parsed = double.tryParse(raw.replaceAll(',', '.'));
                      if (parsed != null && parsed >= 1.0) {
                        _applyDose(parsed, syncText: false);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _RoundStepButton(
                  icon: PocketIconType.plus,
                  size: 42,
                  iconSize: 17,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _applyDose(_dose + 0.1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.center,
              children: [
                PocketPill(
                  label: '-1.0g',
                  isMono: true,
                  height: 32,
                  onTap: () => _applyDose(_dose - 1.0),
                ),
                ...[12.0, 15.0, 18.0, 20.0].map((preset) {
                  final active = (_dose - preset).abs() < 0.05;
                  return PocketPill(
                    label: '${preset.toStringAsFixed(0)}g',
                    isMono: true,
                    height: 32,
                    backgroundColor:
                        active ? c.brandEspresso : c.surfaceElevated,
                    foregroundColor: active ? c.textOnAccent : c.textPrimary,
                    onTap: () => _applyDose(preset),
                  );
                }),
                PocketPill(
                  label: '+1.0g',
                  isMono: true,
                  height: 32,
                  onTap: () => _applyDose(_dose + 1.0),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PocketButton(
              label: 'Terapkan ${_dose.toStringAsFixed(1)}g',
              height: 46,
              backgroundColor: c.brandEspresso,
              foregroundColor: c.textOnAccent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRatioSheetBody extends StatefulWidget {
  const _CustomRatioSheetBody({
    required this.isIced,
    required this.doseG,
    required this.initialRatio,
    required this.unitMode,
    required this.formatRatioChip,
    required this.onChanged,
  });

  final bool isIced;
  final double doseG;
  final double initialRatio;
  final UnitMode unitMode;
  final String Function(double) formatRatioChip;
  final ValueChanged<double> onChanged;

  @override
  State<_CustomRatioSheetBody> createState() => _CustomRatioSheetBodyState();
}

class _CustomRatioSheetBodyState extends State<_CustomRatioSheetBody> {
  late double _ratio;
  late final TextEditingController _ratioCtrl;
  late final TextEditingController _waterCtrl;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
    final initialWater = (widget.doseG * _ratio).round();
    _ratioCtrl = TextEditingController(text: _ratio.toStringAsFixed(1));
    _waterCtrl = TextEditingController(text: '$initialWater');
  }

  @override
  void dispose() {
    _ratioCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  void _applyRatio(
    double nextRatio, {
    bool syncRatioText = true,
    bool syncWaterText = true,
  }) {
    final safe = nextRatio.clamp(6.0, 25.0);
    final totalWater = (widget.doseG * safe).round();
    setState(() {
      _ratio = safe;
      if (syncRatioText) {
        _ratioCtrl.text = safe.toStringAsFixed(1);
        _ratioCtrl.selection = TextSelection.collapsed(
          offset: _ratioCtrl.text.length,
        );
      }
      if (syncWaterText) {
        _waterCtrl.text = '$totalWater';
        _waterCtrl.selection = TextSelection.collapsed(
          offset: _waterCtrl.text.length,
        );
      }
    });
    widget.onChanged(safe);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isIced = widget.isIced;
    final unitMode = widget.unitMode;
    final totalWater = (widget.doseG * _ratio).roundToDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _QuickInputSheetContainer(
        title: isIced ? 'Atur Rasio & Total Cairan' : 'Atur Rasio & Total Air',
        subtitle:
            'Ubah rasio (1:XX) atau langsung ketik target air — keduanya sinkron otomatis.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIced
                  ? 'Rasio Total (Kopi : Air Panas + Es)'
                  : 'Rasio Seduh (Kopi : Air Panas)',
              style: PocketTheme.ui(
                size: 11.5,
                weight: 600,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _RoundStepButton(
                  icon: PocketIconType.minus,
                  size: 40,
                  iconSize: 16,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _applyRatio(_ratio - 0.5);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ratioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: PocketTheme.mono(
                      size: 20,
                      weight: FontWeight.w700,
                      color: isIced ? c.brandIce : c.brandTerracottaInk,
                    ),
                    decoration: InputDecoration(
                      prefixText: '1 : ',
                      prefixStyle: PocketTheme.mono(
                        size: 16,
                        weight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                    onChanged: (raw) {
                      final parsed = double.tryParse(raw.replaceAll(',', '.'));
                      if (parsed != null && parsed >= 6 && parsed <= 25) {
                        _applyRatio(parsed, syncRatioText: false);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                _RoundStepButton(
                  icon: PocketIconType.plus,
                  size: 40,
                  iconSize: 16,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _applyRatio(_ratio + 0.5);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isIced
                  ? 'Atau ketik langsung Target Total Cairan (${unitMode == UnitMode.oz ? 'ml/g' : unitMode.label})'
                  : 'Atau ketik langsung Target Total Air (${unitMode == UnitMode.oz ? 'ml/g' : unitMode.label})',
              style: PocketTheme.ui(
                size: 11.5,
                weight: 600,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _waterCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: PocketTheme.mono(
                size: 20,
                weight: FontWeight.w700,
                color: c.textPrimary,
              ),
              decoration: InputDecoration(
                suffixText: unitMode == UnitMode.gram ? 'g' : 'ml',
                suffixStyle: PocketTheme.mono(
                  size: 13,
                  weight: FontWeight.w600,
                  color: c.textTertiary,
                ),
              ),
              onChanged: (raw) {
                final w = double.tryParse(raw);
                if (w != null && widget.doseG > 0 && w >= widget.doseG * 6) {
                  _applyRatio(w / widget.doseG, syncWaterText: false);
                }
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: (isIced
                        ? [13.0, 14.0, 15.0, 15.5, 16.0, 17.0]
                        : [14.0, 15.0, 16.0, 16.67, 17.0, 18.0])
                    .map((preset) {
                  final active = (_ratio - preset).abs() < 0.25;
                  return PocketPill(
                    label: widget.formatRatioChip(preset),
                    isMono: true,
                    height: 30,
                    backgroundColor: active
                        ? (isIced ? c.brandIce : c.brandEspresso)
                        : c.surfaceElevated,
                    foregroundColor: active ? c.textOnAccent : c.textPrimary,
                    onTap: () => _applyRatio(preset),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            PocketButton(
              label:
                  'Pakai ${widget.formatRatioChip(_ratio)} (${BrewRecipeScaler.formatLiquidCompact(totalWater, unitMode)})',
              height: 46,
              backgroundColor: isIced ? c.brandIce : c.brandEspresso,
              foregroundColor: c.textOnAccent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile 5-step barista pour-over pre-brew checklist ("Siap-siap Seduh"):
/// 1) Panaskan air -> 2) Timbang biji -> 3) Giling -> 4) Bilas filter (+ Es jika Iced) -> 5) Ratakan & Tare 0.0g.
/// Optional & skippable via top-right "Lewati" or primary "Mulai Timer" CTA.
class _PreBrewChecklistSheet extends StatefulWidget {
  const _PreBrewChecklistSheet({
    required this.plan,
    required this.grinder,
    required this.clickSetting,
    required this.approxUm,
    required this.beanName,
    required this.unitMode,
    required this.tempUnit,
    required this.accentColor,
    required this.ratioLabel,
    required this.onProceedToTimer,
  });

  final ScaledBrewPlan plan;
  final GrinderSpec grinder;
  final int clickSetting;
  final int approxUm;
  final String? beanName;
  final UnitMode unitMode;
  final TempUnit tempUnit;
  final Color accentColor;
  final String ratioLabel;
  final VoidCallback onProceedToTimer;

  @override
  State<_PreBrewChecklistSheet> createState() => _PreBrewChecklistSheetState();
}

class _PreBrewChecklistSheetState extends State<_PreBrewChecklistSheet> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.plan;
    final isIced = p.mode == BrewMode.iced;
    final tempLabel = BrewRecipeScaler.formatTemp(p.tempC, widget.tempUnit);
    final hotLabel = BrewRecipeScaler.formatLiquidCompact(
      p.hotWaterG,
      widget.unitMode,
    );
    final doseLabel = BrewRecipeScaler.formatDose(p.doseG);

    final steps = [
      (
        title: 'Panaskan air ke $tempLabel',
        detail: isIced
            ? 'Siapkan $hotLabel air panas untuk seduh (+ sedikit untuk bilas filter)'
            : 'Siapkan minimal $hotLabel air panas (+ sedikit untuk bilas filter)',
      ),
      (
        title: 'Timbang biji $doseLabel',
        detail:
            '${widget.beanName ?? 'Biji kopi pilihan'} · Rasio ${widget.ratioLabel}',
      ),
      (
        title: 'Giling di ${widget.clickSetting} klik',
        detail: '${widget.grinder.fullName} (~${widget.approxUm} μm)',
      ),
      (
        title: isIced && p.icedMethod == IcedMethod.iceFirst
            ? 'Bilas filter & isi ${p.iceG.round()}g es di server'
            : 'Bilas kertas filter & buang air bilasan',
        detail: isIced && p.icedMethod == IcedMethod.iceFirst
            ? 'Bilas filter di wastafel agar es di server tidak meleleh sebelum seduh'
            : isIced
                ? 'Siapkan ${p.iceG.round()}g es batu di gelas terpisah untuk tahap akhir'
                : 'Hilangkan bau kertas sekaligus hangatkan dripper & server',
      ),
      (
        title: 'Masukkan bubuk, ratakan & tare 0.0g',
        detail: 'Goyang ringan dripper agar rata, lalu nol-kan timbangan',
      ),
    ];

    final doneCount = _checked.length;
    final allDone = doneCount == steps.length;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Siap-siap Seduh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PocketTheme.ui(
                            size: 17,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Urutan persiapan sebelum tuangan pertama',
                          style: PocketTheme.ui(
                            size: 11.5,
                            weight: 500,
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PocketTapScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onProceedToTimer();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        'Lewati',
                        style: PocketTheme.ui(
                          size: 13,
                          weight: 700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: steps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (context, idx) {
                    final s = steps[idx];
                    final checked = _checked.contains(idx);
                    return PocketTapScale(
                      pressedScale: 0.985,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (checked) {
                            _checked.remove(idx);
                          } else {
                            _checked.add(idx);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: PocketCurves.fast,
                        curve: PocketCurves.smoothOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: checked
                              ? c.tintSage
                              : (c.isDark
                                  ? c.surfaceElevated
                                  : c.surfaceCanvas),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: checked
                                ? c.brandSage.withValues(alpha: 0.45)
                                : c.borderSubtle,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: PocketCurves.fast,
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    checked ? c.brandSage : c.surfaceCard,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: checked
                                      ? c.brandSage
                                      : c.borderStrong,
                                  width: 1.4,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: checked
                                  ? PocketIcon(
                                      PocketIconType.check,
                                      size: 13,
                                      color: c.textOnAccent,
                                    )
                                  : Text(
                                      '${idx + 1}',
                                      style: PocketTheme.mono(
                                        size: 11,
                                        weight: FontWeight.w800,
                                        color: c.textSecondary,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: PocketTheme.ui(
                                      size: 13,
                                      weight: 700,
                                      color: checked
                                          ? c.brandSage
                                          : c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    s.detail,
                                    style: PocketTheme.ui(
                                      size: 11,
                                      weight: 500,
                                      height: 1.32,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              PocketButton(
                label: allDone
                    ? 'Semua Siap · Mulai Timer'
                    : doneCount > 0
                        ? 'Mulai Timer ($doneCount/${steps.length} siap)'
                        : 'Mulai Timer',
                pocketIcon: PocketIconType.timer,
                iconSize: 16,
                height: 50,
                backgroundColor: allDone ? c.brandSage : widget.accentColor,
                foregroundColor: c.textOnAccent,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onProceedToTimer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to add or edit a pour stage for the CURRENT brew session only
/// (leaves saved recipe presets untouched).
class _SessionStageSheet extends StatefulWidget {
  const _SessionStageSheet({
    required this.isEdit,
    required this.stageNumber,
    required this.initialStage,
    required this.initialWaterMl,
    required this.unitMode,
    required this.accentColor,
    required this.onSave,
  });

  final bool isEdit;
  final int stageNumber;
  final PourStage initialStage;
  final double initialWaterMl;
  final UnitMode unitMode;
  final Color accentColor;
  final void Function(PourStage stage, double waterMl) onSave;

  @override
  State<_SessionStageSheet> createState() => _SessionStageSheetState();
}

class _SessionStageSheetState extends State<_SessionStageSheet> {
  late TextEditingController _labelCtrl;
  late TextEditingController _waterCtrl;
  late int _pourSec;
  late PourPattern _pattern;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initialStage.label);
    _waterCtrl = TextEditingController(
      text: widget.initialWaterMl.round().toString(),
    );
    _pourSec = BrewRecipeScaler.pourDurationSec(widget.initialStage);
    _pattern = widget.initialStage.pattern;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final label = _labelCtrl.text.trim().isEmpty
        ? 'Tuangan ${widget.stageNumber}'
        : _labelCtrl.text.trim();
    final water =
        (double.tryParse(_waterCtrl.text.trim()) ?? widget.initialWaterMl)
            .clamp(5.0, 1200.0);
    final start = widget.initialStage.startSec;
    final pourEnd = start + _pourSec;
    final end = pourEnd > widget.initialStage.endSec
        ? pourEnd + 10
        : widget.initialStage.endSec;

    final updated = widget.initialStage.copyWith(
      label: label,
      pourEndSec: pourEnd,
      endSec: end,
      pattern: _pattern,
    );
    widget.onSave(updated, water);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final suffix = widget.unitMode == UnitMode.gram ? 'g' : 'ml';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _QuickInputSheetContainer(
        title: widget.isEdit
            ? 'Ubah Tahap ${widget.stageNumber} (Sesi Ini)'
            : 'Tambah Tahap ${widget.stageNumber} (Sesi Ini)',
        subtitle:
            'Perubahan hanya berlaku untuk seduhan kali ini, tidak merusak preset asli.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelCtrl,
              style: PocketTheme.ui(
                size: 14,
                weight: 700,
                color: c.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Judul Tahap',
                hintText: 'Contoh: Tuangan 4, Center Pour, Rao Spin',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _waterCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: PocketTheme.mono(
                      size: 16,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Air Tahap Ini',
                      suffixText: suffix,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RoundStepButton(
                        icon: PocketIconType.minus,
                        size: 30,
                        iconSize: 13,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _pourSec = (_pourSec - 1).clamp(3, 90));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_pourSec dtk',
                          style: PocketTheme.mono(
                            size: 13,
                            weight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      _RoundStepButton(
                        icon: PocketIconType.plus,
                        size: 30,
                        iconSize: 13,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _pourSec = (_pourSec + 1).clamp(3, 90));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Pola Tuangan',
                    style: PocketTheme.ui(
                      size: 11.5,
                      weight: 700,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PocketPill(
                  label: 'Info Pola',
                  icon: Icons.info_outline_rounded,
                  iconSize: 13.5,
                  height: 26,
                  fontSize: 10.8,
                  fontWeight: 700,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  backgroundColor: c.tintTerracotta,
                  foregroundColor: c.brandTerracottaInk,
                  onTap: () => showPourPatternGuideSheet(
                    context,
                    initialPattern: _pattern,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PourPattern.values.map((p) {
                final sel = _pattern == p;
                return PocketPill(
                  label: p.label,
                  height: 30,
                  backgroundColor: sel ? c.brandEspresso : c.surfaceElevated,
                  foregroundColor: sel ? c.textOnAccent : c.textPrimary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _pattern = p);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            PocketButton(
              label: widget.isEdit ? 'Simpan Tahap Sesi Ini' : 'Tambahkan Tahap',
              pocketIcon: PocketIconType.check,
              height: 48,
              backgroundColor: widget.accentColor,
              foregroundColor: c.textOnAccent,
              onTap: _apply,
            ),
          ],
        ),
      ),
    );
  }
}
