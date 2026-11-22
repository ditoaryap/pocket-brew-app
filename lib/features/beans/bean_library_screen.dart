import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/canvas/coffee_atmosphere.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_confirm_dialog.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';
import '../../domain/models/enums.dart';

/// Screen 13 · Koleksi Kopi & Stok (Editorial Redesign):
/// - Clean "Kopi / Biji Kopi" terminology (zero ambiguous standalone "Biji" & zero grinder "klik" clutter!).
/// - Displays coffee-relevant signals: Roastery, Origin, Process, Roast tone strip,
///   Tasting Notes chips, AnimatedCoffeeStockBar, remaining cups & freshness badge.
/// - 2-Tab Aktif | Cadangan + Last-Cup Auto-Scale + Delete with confirmation modal.
class BeanLibraryScreen extends ConsumerStatefulWidget {
  const BeanLibraryScreen({super.key});

  @override
  ConsumerState<BeanLibraryScreen> createState() => _BeanLibraryScreenState();
}

class _BeanLibraryScreenState extends ConsumerState<BeanLibraryScreen> {
  static const int _pageSize = 12;
  int _tab = 0; // 0 = Aktif, 1 = Cadangan
  int _visibleCount = _pageSize;

  Future<void> _confirmDeleteBean({
    required String beanId,
    required String beanName,
  }) async {
    final ok = await showPocketDeleteDialog(
      context,
      title: 'Hapus Biji Kopi?',
      message:
          'Biji kopi "$beanName" akan dihapus permanen dari daftar stokmu. Riwayat seduhan yang sudah tercatat tetap aman.',
      confirmLabel: 'Hapus Kopi',
    );
    if (!ok) return;
    ref.read(pocketStoreProvider.notifier).deleteBean(beanId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$beanName dihapus dari koleksi kopi.')),
      );
    }
  }

  Color _roastAccentColor(RoastLevel level, PocketColors c) => switch (level) {
        RoastLevel.light => c.brandHoney,
        RoastLevel.lightMedium => c.brandTerracotta,
        RoastLevel.medium => const Color(0xFF8B5A3C),
        RoastLevel.mediumDark => const Color(0xFF5D3A26),
        RoastLevel.dark => const Color(0xFF3E271A),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);

    final activeList = state.beans.where((b) => !b.isFrozen).toList();
    final reserveList = state.beans.where((b) => b.isFrozen).toList();

    final shown = _tab == 1 ? reserveList : activeList;
    final visibleShown = shown.take(_visibleCount).toList();
    final hasMore = shown.length > visibleShown.length;

    final totalActiveG =
        activeList.fold<double>(0, (sum, b) => sum + b.remainingG);
    final totalActiveCups = (totalActiveG / 15.0).floor();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            // 1. Clean Editorial Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koleksi Kopi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeList.isEmpty
                            ? 'Pantau stok & masa paling enak biji kopi'
                            : '${activeList.length} kantong aktif · ${totalActiveG.round()}g (~$totalActiveCups cup)',
                        style: PocketTheme.mono(
                          size: 11.2,
                          weight: FontWeight.w600,
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PocketPill(
                  label: '+ Tambah',
                  backgroundColor: c.brandEspresso,
                  foregroundColor: c.textOnAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  onTap: () => context.push('/beans/add'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Smooth 2-Tab Sliding Capsule: Aktif | Cadangan
            Container(
              height: 44,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 230),
                    curve: PocketCurves.gentleSpring,
                    alignment: _tab == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
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
                                        .withValues(alpha: 0.07),
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
                      _CoffeeTab(
                        label: 'Aktif (${activeList.length})',
                        active: _tab == 0,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _tab = 0;
                            _visibleCount = _pageSize;
                          });
                        },
                      ),
                      _CoffeeTab(
                        label: 'Cadangan (${reserveList.length})',
                        active: _tab == 1,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _tab = 1;
                            _visibleCount = _pageSize;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Animated List or Empty State
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: PocketCurves.smoothOut,
              child: shown.isEmpty
                  ? PocketCard(
                      key: ValueKey('empty_$_tab'),
                      padding: const EdgeInsets.all(24),
                      radius: 22,
                      child: Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: c.tintTerracotta,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: PocketIcon(
                              PocketIconType.bean,
                              size: 26,
                              color: c.brandTerracottaInk,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _tab == 1
                                ? 'Belum ada stok cadangan'
                                : 'Belum ada biji kopi di sini',
                            textAlign: TextAlign.center,
                            style: PocketTheme.ui(
                              size: 16,
                              weight: 800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _tab == 1
                                ? 'Biji kopi yang disimpan di freezer atau ditandai sebagai cadangan akan muncul rapi di sini.'
                                : 'Tambahkan kantong biji kopi pertamamu agar masa paling enak dan sisa gram selalu terpantau otomatis.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 210,
                            child: PocketButton(
                              label: 'Tambah Kopi Baru',
                              pocketIcon: PocketIconType.plus,
                              height: 46,
                              backgroundColor: c.brandEspresso,
                              foregroundColor: c.textOnAccent,
                              onTap: () => context.push('/beans/add'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      key: ValueKey('list_${_tab}_${visibleShown.length}'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...List.generate(visibleShown.length, (idx) {
                          final bean = visibleShown[idx];
                          final info = BeanRestingCalculator.evaluate(
                            bean: bean,
                            prefs: state.prefs,
                          );
                          final isSelected = state.draft.beanId == bean.id;
                          final roastBarColor =
                              _roastAccentColor(bean.roastLevel, c);
                          final pillBg = info.isLastCupAlert
                              ? c.tintHoney
                              : (info.stage == BeanFreshnessStage.resting
                                  ? c.tintIce
                                  : c.tintSage);
                          final pillFg = info.isLastCupAlert
                              ? c.brandHoney
                              : (info.stage == BeanFreshnessStage.resting
                                  ? c.brandIce
                                  : c.brandSage);
                          final roastDays = DateTime.now()
                              .difference(bean.roastDate)
                              .inDays
                              .clamp(0, 999);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PocketEntrance(
                              delayMs: (idx * 30).clamp(0, 140),
                              offsetY: 8,
                              child: PocketCard(
                                backgroundColor: info.isLastCupAlert
                                    ? c.tintHoney
                                    : c.surfaceCard,
                                borderColor: isSelected && !info.isLastCupAlert
                                    ? c.brandTerracotta
                                    : (info.isLastCupAlert
                                        ? c.brandHoney.withValues(alpha: 0.35)
                                        : c.borderSubtle),
                                borderWidth:
                                    isSelected && !info.isLastCupAlert ? 1.4 : 1,
                                elevated: !info.isLastCupAlert,
                                radius: 22,
                                padding: const EdgeInsets.all(15),
                                onTap: () => context.push('/beans/${bean.id}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Roast Accent Bar + Name/Origin/Roastery + Delete
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 4.5,
                                          height: 40,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: roastBarColor,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      bean.name,
                                                      style: PocketTheme.ui(
                                                        size: 15.8,
                                                        weight: 800,
                                                        height: 1.22,
                                                        color: c.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                [
                                                  bean.roastery,
                                                  if (bean.origin.isNotEmpty)
                                                    bean.origin,
                                                  bean.process,
                                                  bean.roastLevel.shortLabel,
                                                ].join(' · '),
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
                                        const SizedBox(width: 8),
                                        PocketTapScale(
                                          onTap: () => _confirmDeleteBean(
                                            beanId: bean.id,
                                            beanName: bean.name,
                                          ),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: c.statusError
                                                  .withValues(alpha: 0.11),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: c.statusError,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Freshness Status + Tasting Notes Chips (Purely coffee-focused!)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        PocketPill(
                                          label: info.isLastCupAlert
                                              ? 'Sisa ${bean.remainingG.round()}g · Terakhir!'
                                              : info.badgeText,
                                          backgroundColor: pillBg,
                                          foregroundColor: pillFg,
                                          fontSize: 10.6,
                                        ),
                                        if (isSelected)
                                          PocketPill(
                                            label: 'Sedang Dipilih',
                                            backgroundColor: c.tintTerracotta,
                                            foregroundColor:
                                                c.brandTerracottaInk,
                                            fontSize: 10.5,
                                          ),
                                        if (bean.remainingG <= 0.1)
                                          PocketPill(
                                            label: 'Stok Habis',
                                            backgroundColor: c.statusError
                                                .withValues(alpha: 0.14),
                                            foregroundColor: c.statusError,
                                            fontSize: 10.5,
                                          ),
                                        ...bean.tastingNotes.take(3).map(
                                              (note) => PocketPill(
                                                label: note,
                                                backgroundColor: c.tintBerry,
                                                foregroundColor: c.brandBerry,
                                                fontSize: 10.4,
                                              ),
                                            ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Clean Stock Progress (Grams + Cups Remaining + Roast Age — ZERO grinder clicks!)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${bean.remainingG.round()}g / ${bean.bagWeightG.round()}g',
                                          style: PocketTheme.mono(
                                            size: 12.8,
                                            weight: FontWeight.w800,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            '~${info.cupsRemaining} cup · Sangrai $roastDays hr lalu',
                                            textAlign: TextAlign.right,
                                            style: PocketTheme.mono(
                                              size: 11,
                                              weight: FontWeight.w600,
                                              color: c.textTertiary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    AnimatedCoffeeStockBar(
                                      fraction: info.stockFraction,
                                      height: 6.5,
                                      trackColor: c.surfaceElevated,
                                      fillColor: info.isLastCupAlert
                                          ? c.brandHoney
                                          : c.brandSage,
                                    ),
                                    const SizedBox(height: 12),

                                    // Action Row
                                    if (info.isLastCupAlert)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: PocketButton(
                                              label:
                                                  'Auto-scale ${bean.remainingG.round()}g →',
                                              height: 40,
                                              fontSize: 12.4,
                                              backgroundColor: c.brandEspresso,
                                              foregroundColor: c.textOnAccent,
                                              onTap: () {
                                                notifier.startLastCupBrew(bean);
                                                context.go('/brew');
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: PocketButton(
                                              label: 'Koreksi Stok',
                                              height: 40,
                                              fontSize: 12.2,
                                              backgroundColor: c.surfaceCard,
                                              foregroundColor: c.textPrimary,
                                              borderColor: c.borderStrong,
                                              onTap: () => context
                                                  .push('/beans/${bean.id}'),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: PocketButton(
                                              label: 'Detail & Stok',
                                              height: 40,
                                              fontSize: 12.2,
                                              backgroundColor:
                                                  c.surfaceElevated,
                                              foregroundColor: c.textPrimary,
                                              onTap: () => context
                                                  .push('/beans/${bean.id}'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: PocketButton(
                                              label: 'Seduh Kopi Ini',
                                              height: 40,
                                              fontSize: 12.4,
                                              backgroundColor:
                                                  c.brandTerracotta,
                                              foregroundColor: c.textOnAccent,
                                              onTap: () {
                                                notifier.updateDraft(
                                                  beanId: bean.id,
                                                  clickSetting:
                                                      bean.preferredHotClick ??
                                                          state.draft
                                                              .clickSetting,
                                                );
                                                context.go('/brew');
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        if (hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              children: [
                                Text(
                                  'Menampilkan ${visibleShown.length} dari ${shown.length} biji kopi',
                                  style: PocketTheme.mono(
                                    size: 11,
                                    color: c.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                PocketButton(
                                  label: 'Muat Lebih Banyak (+$_pageSize)',
                                  height: 44,
                                  fontSize: 13,
                                  backgroundColor: c.surfaceElevated,
                                  foregroundColor: c.textPrimary,
                                  onTap: () => setState(
                                    () => _visibleCount += _pageSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoffeeTab extends StatelessWidget {
  const _CoffeeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: PocketTheme.ui(
                size: 12.5,
                weight: active ? 800 : 600,
                color: active ? c.textPrimary : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
