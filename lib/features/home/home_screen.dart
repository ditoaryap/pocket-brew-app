import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/bean_picker_sheet.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../core/widgets/pocket_logo.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Screen 02 · Beranda (Warm Editorial Redesign & Fast Brew Launchpad):
/// - Soft, airy, non-stiff editorial header + tappable active gear pill (no Meja Rumah/Kantor/Travel)
/// - Unified Quick-Brew Shortcut Card:
///   1) Sliding Hot V60 <-> Japanese Iced switcher
///   2) Active Bean selector with plain-language freshness badge
///   3) Inline horizontal Quick Method / Recipe selector strip
///   4) Live 4-KPI brew preview + direct "Seduh Sekarang" & "Edit Tahapan Seduh" CTAs
/// - Clean Stock cards, Exploration tiles, and Latest Brew recap.
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

    // Matching recipes for the selected Hot / Iced mode right on Beranda!
    final modeRecipes =
        state.recipes.where((r) => r.mode == state.draft.mode).toList();
    final displayRecipes =
        modeRecipes.isNotEmpty ? modeRecipes : state.recipes;

    final proCount = state.recipes.where((r) => r.isOfficial).length;
    final customCount = state.recipes.where((r) => !r.isOfficial).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 102),
          children: [
            // 1. COMPACT, PROPORTIONAL EDITORIAL HEADER (Light & Dark consistent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const PocketBrewMark(size: 38),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mau seduh apa, ${state.prefs.userName}?',
                          style: PocketTheme.ui(
                            size: 16.5,
                            weight: 800,
                            height: 1.2,
                            letterSpacing: -0.25,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        PocketTapScale(
                          onTap: () => context.go('/gear'),
                          pressedScale: 0.97,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${_greeting()} · ${state.activeGrinder.model} · ${_shortDripperName(state.activeDripper.name)}',
                                  style: PocketTheme.ui(
                                    size: 11.2,
                                    weight: 600,
                                    height: 1.25,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              PocketIcon(
                                PocketIconType.chevronRight,
                                size: 12,
                                color: c.textTertiary,
                              ),
                            ],
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.borderSubtle),
                      ),
                      alignment: Alignment.center,
                      child: PocketIcon(
                        PocketIconType.sliders,
                        size: 17,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. HERO SHORTCUT LAUNCHPAD CARD (Mode + Active Bean + Quick Method Picker + Launch!)
            PocketEntrance(
              delayMs: 0,
              child: PocketCard(
                padding: const EdgeInsets.all(16),
                radius: 26,
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
                    const SizedBox(height: 14),

                    // Step B: Active Bean Summary + Freshness Badge + Ganti biji
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: PocketCurves.smoothOut,
                            child: SizedBox(
                              key: ValueKey(heroBean?.id ?? 'free'),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (heroStatus != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.tintSage,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5.5,
                                            height: 5.5,
                                            decoration: BoxDecoration(
                                              color: c.brandSage,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              heroStatus.badgeText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: PocketTheme.ui(
                                                size: 10.5,
                                                weight: 700,
                                                color: c.brandSage,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  Text(
                                    heroBean?.name ?? 'Seduhan Bebas (V60)',
                                    style: PocketTheme.ui(
                                      size: 19.5,
                                      weight: 800,
                                      height: 1.2,
                                      letterSpacing: -0.25,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    heroBean != null
                                        ? '${heroBean.process} · ${heroBean.roastLevel.shortLabel} · ${heroBean.remainingG.round()}g${heroBean.tastingNotes.isNotEmpty ? ' · ${heroBean.tastingNotes.take(2).join(', ')}' : ''}'
                                        : state.activeRecipe.name,
                                    style: PocketTheme.ui(
                                      size: 11.8,
                                      weight: 500,
                                      height: 1.35,
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
                          label: 'Ganti biji',
                          height: 30,
                          fontSize: 11.5,
                          fontWeight: 700,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          backgroundColor: accentTint,
                          foregroundColor: accentInk,
                          onTap: () => showBeanPickerSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Step C: Quick Method / Recipe Picker right inside Beranda!
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
                              size: 11.5,
                              weight: 700,
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

                    // Step D: Live 4-KPI Brew Preview Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: c.isDark ? c.surfaceElevated : c.surfaceCanvas,
                        borderRadius: BorderRadius.circular(16),
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
                            label: isIced ? 'Cairan' : 'Air',
                            value: BrewRecipeScaler.formatLiquidCompact(
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
                    const SizedBox(height: 13),

                    // Step E: Direct Launch CTA + Secondary Edit Tahapan
                    PocketButton(
                      label: isIced
                          ? 'Seduh Japanese Iced Sekarang'
                          : 'Seduh Hot V60 Sekarang',
                      pocketIcon: isIced
                          ? PocketIconType.snowflake
                          : PocketIconType.flame,
                      iconSize: 16,
                      backgroundColor: accent,
                      foregroundColor: c.textOnAccent,
                      height: 50,
                      fontSize: 14,
                      fontWeight: 700,
                      onTap: () => context.go('/brew'),
                    ),
                    const SizedBox(height: 8),
                    PocketButton(
                      label: 'Edit Tahapan Seduh',
                      pocketIcon: PocketIconType.edit,
                      iconSize: 14.5,
                      backgroundColor: c.surfaceElevated,
                      foregroundColor: c.textPrimary,
                      height: 38,
                      fontSize: 12.2,
                      fontWeight: 600,
                      onTap: () => context.push('/brew/stages'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. STOK BIJI DI RUMAH
            PocketEntrance(
              delayMs: 55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PocketSectionHeader(
                    title: 'Stok Biji di Rumah',
                    actionLabel: 'Semua (${activeBeans.length}) →',
                    onAction: () => context.go('/beans'),
                  ),
                  const SizedBox(height: 10),
                  if (activeBeans.isEmpty)
                    PocketCard(
                      radius: 18,
                      onTap: () => context.push('/beans/add'),
                      child: Row(
                        children: [
                          PocketIcon(
                            PocketIconType.bean,
                            size: 20,
                            color: c.brandTerracotta,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Belum ada biji tercatat — tambah kantong pertamamu.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
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
                              right: isFirst && activeBeans.length > 1 ? 10 : 0,
                            ),
                            child: PocketCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 12,
                              ),
                              radius: 18,
                              backgroundColor:
                                  isAlert ? c.tintHoney : c.surfaceCard,
                              elevated: false,
                              onTap: () => context.push('/beans/${b.id}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          b.name,
                                          maxLines: 2,
                                          style: PocketTheme.ui(
                                            size: 13,
                                            weight: 700,
                                            height: 1.2,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isAlert
                                            ? '${b.remainingG.round()}g!'
                                            : '${b.remainingG.round()}g',
                                        style: PocketTheme.mono(
                                          size: 12,
                                          weight: FontWeight.w700,
                                          color: isAlert
                                              ? c.brandHoney
                                              : c.brandSage,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  _SmoothStockBar(
                                    fraction: st.stockFraction,
                                    trackColor: c.isDark && isAlert
                                        ? c.brandHoney.withValues(alpha: 0.22)
                                        : c.surfaceSubtle,
                                    fillColor:
                                        isAlert ? c.brandHoney : c.brandSage,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    isAlert
                                        ? 'Stok hampir habis · Koreksi →'
                                        : st.badgeText,
                                    style: PocketTheme.ui(
                                      size: 10.8,
                                      weight: isAlert ? 600 : 500,
                                      height: 1.25,
                                      color: isAlert
                                          ? c.brandHoney
                                          : c.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 4. EKSPLORASI & PANDUAN
            PocketEntrance(
              delayMs: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PocketSectionHeader(title: 'Eksplorasi & Panduan'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PocketCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          radius: 20,
                          elevated: false,
                          onTap: () => context.push('/methods'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c.tintTerracotta,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: PocketIcon(
                                  PocketIconType.recipe,
                                  size: 16,
                                  color: c.brandTerracottaInk,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Metode & Resep',
                                style: PocketTheme.ui(
                                  size: 13.5,
                                  weight: 700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$proCount resep pro · $customCount buatanmu',
                                style: PocketTheme.ui(
                                  size: 11.5,
                                  weight: 400,
                                  height: 1.3,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          radius: 20,
                          backgroundColor: c.tintSage,
                          elevated: false,
                          onTap: () => context.push('/learn'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c.surfaceCard,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: PocketIcon(
                                  PocketIconType.book,
                                  size: 16,
                                  color: c.brandSage,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belajar Seduh',
                                style: PocketTheme.ui(
                                  size: 13.5,
                                  weight: 700,
                                  color: c.brandSage,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Biji, tuangan & alat →',
                                style: PocketTheme.ui(
                                  size: 11.5,
                                  weight: 500,
                                  height: 1.3,
                                  color: c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. SEDUHAN TERAKHIR RECAP
            if (latestLog != null)
              PocketEntrance(
                delayMs: 155,
                child: PocketCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  radius: 18,
                  elevated: false,
                  onTap: () => context.push('/log/${latestLog.id}'),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c.tintHoney,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: PocketIcon(
                          PocketIconType.starFilled,
                          size: 16,
                          color: c.brandHoney,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terakhir · ${latestLog.beanName} (${latestLog.mode.shortBadge})',
                              style: PocketTheme.ui(
                                size: 13,
                                weight: 600,
                                height: 1.25,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${latestLog.clickSetting} klik · ${BrewRecipeScaler.formatLiquidCompact(latestLog.totalLiquidG, state.prefs.unitMode)} · ${BrewRecipeScaler.formatShortDuration(latestLog.actualDrawdownSec)} · ★ ${latestLog.rating.toStringAsFixed(1)}',
                              style: PocketTheme.mono(
                                size: 11,
                                color: c.textSecondary,
                                weight: FontWeight.w400,
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
                ),
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
                                const Color(0xFF1F1915).withValues(alpha: 0.07),
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

class _SmoothStockBar extends StatelessWidget {
  const _SmoothStockBar({
    required this.fraction,
    required this.trackColor,
    required this.fillColor,
  });

  final double fraction;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final safeFrac = fraction.clamp(0.06, 1.0);
    return Container(
      height: 5,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: PocketCurves.gentle,
        curve: PocketCurves.smoothOut,
        widthFactor: safeFrac,
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
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
              size: 10,
              weight: 500,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: isMono
                  ? PocketTheme.mono(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: valueColor ?? c.textPrimary,
                    )
                  : PocketTheme.ui(
                      size: 13.5,
                      weight: 700,
                      color: valueColor ?? c.textPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
