import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_confirm_dialog.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';

/// Screen 13 · Biji Kopi & Stok (Aktif / Cadangan + Last-Cup Auto-scale + Delete with confirmation).
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
          'Biji "$beanName" akan dihapus permanen dari daftar stokmu. Riwayat seduhan yang sudah tercatat tetap aman.',
      confirmLabel: 'Hapus Biji',
    );
    if (!ok) return;
    ref.read(pocketStoreProvider.notifier).deleteBean(beanId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$beanName dihapus dari stok biji.')),
      );
    }
  }

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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Biji Kopi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                PocketPill(
                  label: '+ Tambah',
                  backgroundColor: c.brandEspresso,
                  foregroundColor: c.textOnAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  onTap: () => context.push('/beans/add'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Smooth 2-Tab Sliding Capsule: Aktif | Cadangan (No Archive!)
            Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
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
                                        .withValues(alpha: 0.06),
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
                      _BeanTab(
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
                      _BeanTab(
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

            if (shown.isEmpty)
              PocketCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.grain_rounded,
                      size: 38,
                      color: c.brandTerracotta,
                    ),
                    const SizedBox(height: 10),
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
                          ? 'Biji yang kamu tandai sebagai Stok Cadangan akan tersimpan rapi di sini.'
                          : 'Tambahkan kantong biji baru atau sisa stok agar masa paling enak & sisa gram terpantau otomatis.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.brandEspresso,
                        foregroundColor: c.textOnAccent,
                        minimumSize: const Size(190, 46),
                      ),
                      onPressed: () => context.push('/beans/add'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Biji Baru'),
                    ),
                  ],
                ),
              )
            else ...[
              ...visibleShown.map((bean) {
                final info = BeanRestingCalculator.evaluate(
                  bean: bean,
                  prefs: state.prefs,
                );
                final isSelected = state.draft.beanId == bean.id;
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: PocketCard(
                    backgroundColor:
                        info.isLastCupAlert ? c.tintHoney : c.surfaceCard,
                    borderColor: isSelected && !info.isLastCupAlert
                        ? c.brandTerracotta
                        : null,
                    elevated: !info.isLastCupAlert,
                    padding: const EdgeInsets.all(15),
                    onTap: () => context.push('/beans/${bean.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bean.name,
                                    style: PocketTheme.ui(
                                      size: 15,
                                      weight: 800,
                                      height: 1.25,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${bean.roastery} · ${bean.process} · ${bean.roastLevel.shortLabel}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                                  color: c.statusError.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(height: 8),
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
                              fontSize: 10.5,
                            ),
                            if (bean.remainingG <= 0.1)
                              PocketPill(
                                label: 'Stok Habis',
                                backgroundColor:
                                    c.statusError.withValues(alpha: 0.14),
                                foregroundColor: c.statusError,
                                fontSize: 10.5,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${bean.remainingG.round()}g / ${bean.bagWeightG.round()}g',
                              style: PocketTheme.mono(
                                size: 12.5,
                                weight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '~${info.cupsRemaining} cup · ${bean.preferredHotClick != null ? '${bean.preferredHotClick} klik' : 'Belum dial-in'}',
                                textAlign: TextAlign.right,
                                style: PocketTheme.mono(
                                  size: 11,
                                  color: c.textTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: info.stockFraction,
                            minHeight: 6,
                            backgroundColor: c.surfaceElevated,
                            color: info.isLastCupAlert
                                ? c.brandHoney
                                : c.brandSage,
                          ),
                        ),
                        const SizedBox(height: 11),
                        if (info.isLastCupAlert)
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: c.brandEspresso,
                                    foregroundColor: c.textOnAccent,
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  onPressed: () {
                                    notifier.startLastCupBrew(bean);
                                    context.go('/brew');
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Auto-scale ${bean.remainingG.round()}g →',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  side: BorderSide(color: c.borderStrong),
                                  foregroundColor: c.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                onPressed: () =>
                                    context.push('/beans/${bean.id}'),
                                child: const Text(
                                  'Koreksi stok',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 38),
                                    side: BorderSide(color: c.borderStrong),
                                    foregroundColor: c.textPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  onPressed: () =>
                                      context.push('/beans/${bean.id}'),
                                  child: const Text(
                                    'Detail & Stok',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: c.brandTerracotta,
                                    foregroundColor: c.textOnAccent,
                                    minimumSize: const Size(0, 38),
                                  ),
                                  onPressed: () {
                                    notifier.updateDraft(
                                      beanId: bean.id,
                                      clickSetting: bean.preferredHotClick ??
                                          state.draft.clickSetting,
                                    );
                                    context.go('/brew');
                                  },
                                  child: const Text(
                                    'Brew Biji Ini',
                                    style: TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
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
                        onTap: () =>
                            setState(() => _visibleCount += _pageSize),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BeanTab extends StatelessWidget {
  const _BeanTab({
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
                weight: active ? 700 : 600,
                color: active ? c.textPrimary : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
