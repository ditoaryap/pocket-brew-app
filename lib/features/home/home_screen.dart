import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/bean_picker_sheet.dart';
import '../../core/widgets/canvas/coffee_atmosphere.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../core/widgets/pocket_logo.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Screen 02 · Beranda (Cohesive Editorial Flow + Living Coffee/Ice Atmosphere):
/// - Seamless canvas header (no boxy header card) linked directly into the hero Launchpad.
/// - Living BrewAtmosphereBackdrop morphs smoothly between rising Hot V60 aroma wisps
///   and drifting Japanese Iced crystal facets.
/// - Consistent "Kopi / Biji Kopi" terminology & unified visual rhythm down to the bottom cards.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _shortDripperName(String name) {
    if (name.contains('V60-02')) return 'V60-02';
    if (name.contains('V60-01')) return 'V60-01';
    if (name.contains('Switch')) return 'Switch';
    if (name.contains('Kalita')) return 'Kalita 185';
    if (name.contains('Origami')) return 'Origami M';
    return name.split(' ').take(2).join(' ');
  }

  String _shortMethodChipName(BrewRecipe r) {
    final n = r.name;
    if (n.contains('Better 1-Cup')) return 'Hoffmann 1-Cup';
    if (n.contains('4:6')) return 'Tetsu 4:6';
    if (n.contains('Osmotic')) return 'Osmotic Flow';
    if (n.contains('Hoffmann') && n.contains('Iced')) return 'Hoffmann Iced';
    if (n.contains('Kasuya') && n.contains('Iced')) return 'Kasuya Iced';
    if (n.contains('·')) {
      final parts = n.split('·');
      if (parts.length >= 2) return parts.last.trim();
    }
    return n;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);

    final activeBeans = state.beans.where((b) => !b.isFrozen).toList();
    final heroBean = state.activeBean ??
        activeBeans.firstOrNull ??
        state.beans.firstOrNull;
    final heroStatus = heroBean != null
        ? BeanRestingCalculator.evaluate(bean: heroBean, prefs: state.prefs)
        : null;
    final plan = state.currentPlan;
    final latestLog = state.logs.firstOrNull;

    final isIced = state.draft.mode == BrewMode.iced;
    final accent = isIced ? c.brandIce : c.brandTerracotta;
    final accentInk = isIced ? c.brandIce : c.brandTerracottaInk;
    final accentTint = isIced ? c.tintIce : c.tintTerracotta;

    final modeRecipes =
        state.recipes.where((r) => r.mode == state.draft.mode).toList();
    final displayRecipes =
        modeRecipes.isNotEmpty ? modeRecipes : state.recipes;

    final proCount = state.recipes.where((r) => r.isOfficial).length;
    final customCount = state.recipes.where((r) => !r.isOfficial).length;
    final guideCount = state.guides.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
          children: [
            // 1. SEAMLESS EDITORIAL TOP BAR (Flows naturally into the Launchpad!)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const PocketBrewMark(size: 38),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: PocketTheme.ui(
                          size: 11.5,
                          weight: 600,
                          color: c.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Mau seduh apa, ${state.prefs.userName}?',
                        style: PocketTheme.ui(
                          size: 18.5,
                          weight: 800,
                          height: 1.18,
                          letterSpacing: -0.35,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PocketTapScale(
                  onTap: () => context.push('/settings'),
                  pressedScale: 0.92,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.borderSubtle),
                    ),
                    alignment: Alignment.center,
                    child: PocketIcon(
                      PocketIconType.sliders,
                      size: 18,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Connected Active Setup Ribbon (1-tap jump to Alat Seduh)
            PocketTapScale(
              onTap: () => context.go('/gear'),
              pressedScale: 0.985,
              child: AnimatedContainer(
                duration: PocketCurves.normal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.surfaceCard.withValues(alpha: c.isDark ? 0.72 : 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: c.isDark ? 0.28 : 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: PocketCurves.normal,
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alat aktif: ${state.activeGrinder.model} · ${_shortDripperName(state.activeDripper.name)}',
                        style: PocketTheme.ui(
                          size: 12,
                          weight: 700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ubah',
                      style: PocketTheme.ui(
                        size: 11.5,
                        weight: 800,
                        color: accentInk,
                      ),
                    ),
                    const SizedBox(width: 2),
                    PocketIcon(
                      PocketIconType.chevronRight,
                      size: 13,
                      color: accentInk,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. HERO LIVING LAUNCHPAD CARD (Animated Aroma/Ice Atmosphere!)
            PocketEntrance(
              delayMs: 0,
              child: AnimatedContainer(
                duration: PocketCurves.normal,
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: accent.withValues(alpha: c.isDark ? 0.34 : 0.22),
                    width: 1.15,
                  ),
                  boxShadow: c.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: BrewAtmosphereBackdrop(
                  isIced: isIced,
                  borderRadius: 25,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step A: Smooth Sliding Mode Switcher (Hot V60 <-> Japanese Iced)
                        _HomeModeSwitch(
                          isIced: isIced,
                          onSelectHot: () {
                            HapticFeedback.selectionClick();
                            notifier.selectBrewMode(BrewMode.hot);
                          },
                          onSelectIced: () {
                            HapticFeedback.selectionClick();
                            notifier.selectBrewMode(BrewMode.iced);
                          },
                        ),
                        const SizedBox(height: 15),

                        // Step B: Active Coffee Bean Block + Ganti kopi
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: PocketCurves.smoothOut,
                                child: SizedBox(
                                  key: ValueKey(heroBean?.id ?? 'free'),
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (heroStatus != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 3.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: heroStatus.isLastCupAlert
                                                ? c.tintHoney
                                                : c.tintSage,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color:
                                                      heroStatus.isLastCupAlert
                                                          ? c.brandHoney
                                                          : c.brandSage,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Flexible(
                                                child: Text(
                                                  heroStatus.badgeText,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: PocketTheme.ui(
                                                    size: 10.8,
                                                    weight: 700,
                                                    color: heroStatus
                                                            .isLastCupAlert
                                                        ? c.brandHoney
                                                        : c.brandSage,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                      ],
                                      Text(
                                        heroBean?.name ?? 'Seduhan Bebas (V60)',
                                        style: PocketTheme.ui(
                                          size: 20,
                                          weight: 800,
                                          height: 1.2,
                                          letterSpacing: -0.3,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        heroBean != null
                                            ? '${heroBean.process} · ${heroBean.roastLevel.shortLabel} · ${heroBean.remainingG.round()}g${heroBean.tastingNotes.isNotEmpty ? ' · ${heroBean.tastingNotes.take(2).join(', ')}' : ''}'
                                            : state.activeRecipe.name,
                                        style: PocketTheme.ui(
                                          size: 12,
                                          weight: 500,
                                          height: 1.38,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PocketPill(
                              label: 'Ganti kopi',
                              height: 32,
                              fontSize: 11.5,
                              fontWeight: 800,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: accentTint,
                              foregroundColor: accentInk,
                              onTap: () => showBeanPickerSheet(context, ref),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Step C: Quick Method Picker right inside Launchpad
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Pilih Metode',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PocketTheme.ui(
                                  size: 12,
                                  weight: 700,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PocketTapScale(
                              onTap: () => context.push('/methods'),
                              child: Text(
                                'Semua resep →',
                                style: PocketTheme.ui(
                                  size: 11.8,
                                  weight: 800,
                                  color: accentInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: displayRecipes.map((r) {
                              final active = r.id == state.activeRecipe.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: PocketTapScale(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    notifier.selectRecipe(
                                      r.id,
                                      forceMode: state.draft.mode,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: PocketCurves.fast,
                                    curve: PocketCurves.smoothOut,
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? accent
                                          : (c.isDark
                                              ? c.surfaceElevated
                                              : c.surfaceCanvas),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: active ? accent : c.borderSubtle,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _shortMethodChipName(r),
                                      maxLines: 1,
                                      style: PocketTheme.ui(
                                        size: 12,
                                        weight: active ? 700 : 600,
                                        color: active
                                            ? c.textOnAccent
                                            : c.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 13),

                        // Step D: Live Animated 4-KPI Brew Preview Strip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: c.isDark
                                ? c.surfaceElevated.withValues(alpha: 0.92)
                                : c.surfaceCanvas.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              _HeroKpi(
                                label: 'Giling',
                                value: '${state.draft.clickSetting} klik',
                                valueColor: accentInk,
                              ),
                              _HeroKpi(
                                label: 'Suhu',
                                value: BrewRecipeScaler.formatTemp(
                                  plan.tempC,
                                  state.prefs.tempUnit,
                                ),
                              ),
                              _HeroKpi(
                                label: isIced ? 'Air + Es' : 'Air',
                                value: isIced
                                    ? '${plan.hotWaterG.round()}+${plan.iceG.round()}g'
                                    : BrewRecipeScaler.formatLiquidCompact(
                                        plan.totalLiquidG,
                                        state.prefs.unitMode,
                                      ),
                              ),
                              _HeroKpi(
                                label: 'Tahap',
                                value: '${plan.stages.length} tuang',
                                isMono: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Step E: Launch CTA + Edit Tahapan
                        PocketButton(
                          label: isIced
                              ? 'Seduh Japanese Iced Sekarang'
                              : 'Seduh Hot V60 Sekarang',
                          pocketIcon: isIced
                              ? PocketIconType.snowflake
                              : PocketIconType.flame,
                          iconSize: 16.5,
                          backgroundColor: accent,
                          foregroundColor: c.textOnAccent,
                          height: 50,
                          fontSize: 14,
                          fontWeight: 800,
                          onTap: () => context.go('/brew'),
                        ),
                        const SizedBox(height: 8),
                        PocketButton(
                          label: 'Edit Tahapan Seduh',
                          pocketIcon: PocketIconType.edit,
                          iconSize: 14.5,
                          backgroundColor: c.surfaceElevated,
                          foregroundColor: c.textPrimary,
                          height: 39,
                          fontSize: 12.4,
                          fontWeight: 700,
                          onTap: () => context.push('/brew/stages'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. STOK KOPI DI RUMAH (Cohesive Equal-Height Editorial Cards)
            PocketEntrance(
              delayMs: 55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PocketSectionHeader(
                    title: 'Stok Kopi di Rumah',
                    actionLabel: 'Semua (${activeBeans.length}) →',
                    onAction: () => context.go('/beans'),
                  ),
                  const SizedBox(height: 10),
                  if (activeBeans.isEmpty)
                    PocketCard(
                      radius: 20,
                      onTap: () => context.push('/beans/add'),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: c.tintTerracotta,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: PocketIcon(
                              PocketIconType.bean,
                              size: 19,
                              color: c.brandTerracottaInk,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'Belum ada biji kopi tercatat — tambah kantong pertamamu.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: activeBeans.take(2).map((b) {
                          final st = BeanRestingCalculator.evaluate(
                            bean: b,
                            prefs: state.prefs,
                          );
                          final isAlert = st.isLastCupAlert;
                          final isFirst = b == activeBeans.first;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right:
                                    isFirst && activeBeans.length > 1 ? 10 : 0,
                              ),
                              child: PocketCard(
                                padding: const EdgeInsets.all(13),
                                radius: 20,
                                backgroundColor:
                                    isAlert ? c.tintHoney : c.surfaceCard,
                                borderColor: isAlert
                                    ? c.brandHoney.withValues(alpha: 0.32)
                                    : c.borderSubtle,
                                elevated: false,
                                onTap: () => context.push('/beans/${b.id}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            b.name,
                                            maxLines: 2,
                                            style: PocketTheme.ui(
                                              size: 13.2,
                                              weight: 800,
                                              height: 1.22,
                                              color: c.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${b.remainingG.round()}g',
                                          style: PocketTheme.mono(
                                            size: 12.2,
                                            weight: FontWeight.w800,
                                            color: isAlert
                                                ? c.brandHoney
                                                : c.brandSage,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${b.process} · ${b.roastLevel.shortLabel}',
                                      style: PocketTheme.ui(
                                        size: 10.8,
                                        weight: 500,
                                        color: c.textTertiary,
                                      ),
                                    ),
                                    const Spacer(),
                                    const SizedBox(height: 9),
                                    AnimatedCoffeeStockBar(
                                      fraction: st.stockFraction,
                                      height: 5.5,
                                      trackColor: c.isDark && isAlert
                                          ? c.brandHoney.withValues(alpha: 0.22)
                                          : c.surfaceElevated,
                                      fillColor:
                                          isAlert ? c.brandHoney : c.brandSage,
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      isAlert
                                          ? 'Hampir habis · Cek →'
                                          : st.badgeText,
                                      style: PocketTheme.ui(
                                        size: 10.8,
                                        weight: 700,
                                        height: 1.25,
                                        color: isAlert
                                            ? c.brandHoney
                                            : c.brandSage,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. EKSPLORASI & PANDUAN (Matching Cohesive Bento Pair)
            PocketEntrance(
              delayMs: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PocketSectionHeader(title: 'Eksplorasi & Panduan'),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: PocketCard(
                            padding: const EdgeInsets.all(14),
                            radius: 20,
                            elevated: false,
                            onTap: () => context.push('/methods'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: c.tintTerracotta,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: PocketIcon(
                                    PocketIconType.recipe,
                                    size: 17,
                                    color: c.brandTerracottaInk,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Metode & Resep',
                                  style: PocketTheme.ui(
                                    size: 13.8,
                                    weight: 800,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$proCount resep pro · $customCount buatanmu',
                                  style: PocketTheme.ui(
                                    size: 11.5,
                                    weight: 500,
                                    height: 1.32,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PocketCard(
                            padding: const EdgeInsets.all(14),
                            radius: 20,
                            backgroundColor: c.tintSage,
                            borderColor: c.brandSage.withValues(alpha: 0.25),
                            elevated: false,
                            onTap: () => context.push('/learn'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: c.surfaceCard,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: PocketIcon(
                                    PocketIconType.book,
                                    size: 17,
                                    color: c.brandSage,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Belajar Seduh',
                                  style: PocketTheme.ui(
                                    size: 13.8,
                                    weight: 800,
                                    color: c.brandSage,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$guideCount materi pro · Roda Rasa →',
                                  style: PocketTheme.ui(
                                    size: 11.5,
                                    weight: 600,
                                    height: 1.32,
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. SEDUHAN TERAKHIR (Mode-Differentiated Hot vs Iced Recap)
            if (latestLog != null)
              PocketEntrance(
                delayMs: 155,
                child: () {
                  final logIced = latestLog.mode == BrewMode.iced;
                  final logAccent =
                      logIced ? c.brandIce : c.brandTerracottaInk;
                  final logTint = logIced ? c.tintIce : c.tintTerracotta;
                  return PocketCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    radius: 20,
                    borderColor: logAccent.withValues(alpha: 0.22),
                    elevated: false,
                    onTap: () => context.push('/log/${latestLog.id}'),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: logTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: PocketIcon(
                            logIced
                                ? PocketIconType.snowflake
                                : PocketIconType.flame,
                            size: 18,
                            color: logAccent,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Terakhir · ${latestLog.beanName}',
                                      style: PocketTheme.ui(
                                        size: 13.2,
                                        weight: 700,
                                        height: 1.25,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                logIced
                                    ? '${latestLog.mode.shortBadge} · ${latestLog.hotWaterG.round()} ml + ${latestLog.iceG.round()}g es · ★ ${latestLog.rating.toStringAsFixed(1)}'
                                    : '${latestLog.mode.shortBadge} · ${latestLog.clickSetting} klik · ${BrewRecipeScaler.formatLiquidCompact(latestLog.totalLiquidG, state.prefs.unitMode)} · ★ ${latestLog.rating.toStringAsFixed(1)}',
                                style: PocketTheme.mono(
                                  size: 11,
                                  color: c.textSecondary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        PocketIcon(
                          PocketIconType.chevronRight,
                          size: 16,
                          color: c.textTertiary,
                        ),
                      ],
                    ),
                  );
                }(),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeModeSwitch extends StatelessWidget {
  const _HomeModeSwitch({
    required this.isIced,
    required this.onSelectHot,
    required this.onSelectIced,
  });

  final bool isIced;
  final VoidCallback onSelectHot;
  final VoidCallback onSelectIced;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: PocketCurves.gentleSpring,
            alignment: isIced ? Alignment.centerRight : Alignment.centerLeft,
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
                            color:
                                const Color(0xFF1F1915).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSelectHot,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PocketIcon(
                              PocketIconType.flame,
                              size: 14.5,
                              color: !isIced
                                  ? c.brandTerracottaInk
                                  : c.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hot V60',
                              maxLines: 1,
                              style: PocketTheme.ui(
                                size: 12.5,
                                weight: !isIced ? 700 : 600,
                                color: !isIced
                                    ? c.brandTerracottaInk
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
                  onTap: onSelectIced,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PocketIcon(
                              PocketIconType.snowflake,
                              size: 14.5,
                              color: isIced ? c.brandIce : c.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Japanese Iced',
                              maxLines: 1,
                              style: PocketTheme.ui(
                                size: 12.5,
                                weight: isIced ? 700 : 600,
                                color: isIced ? c.brandIce : c.textSecondary,
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

class _HeroKpi extends StatelessWidget {
  const _HeroKpi({
    required this.label,
    required this.value,
    this.valueColor,
    this.isMono = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: PocketTheme.ui(
              size: 10.2,
              weight: 600,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: FittedBox(
              key: ValueKey(value),
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: isMono
                    ? PocketTheme.mono(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: valueColor ?? c.textPrimary,
                      )
                    : PocketTheme.ui(
                        size: 13.5,
                        weight: 800,
                        color: valueColor ?? c.textPrimary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
