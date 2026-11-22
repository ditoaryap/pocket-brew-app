import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';
import '../motion/pocket_motion.dart';
import 'pocket_card.dart';
import 'pocket_icons.dart';

/// Lightweight M3 bottom sheet for selecting a coffee bean in 1 tap
/// from Screen 02 (Beranda) or Screens 04 & 05 (Quick Brew Hot V60 & Japanese Iced).
Future<void> showBeanPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _BeanPickerSheet(),
  );
}

class _BeanPickerSheet extends ConsumerWidget {
  const _BeanPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);
    final activeBeans = [
      ...state.beans.where((b) => !b.isFrozen),
      ...state.beans.where((b) => b.isFrozen),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.borderSubtle, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F1915)
                  .withValues(alpha: c.isDark ? 0.5 : 0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Pilih Biji Kopi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PocketTheme.ui(
                      size: 17,
                      weight: 700,
                      letterSpacing: -0.2,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PocketPill(
                  label: '+ Tambah Kopi',
                  backgroundColor: c.tintTerracotta,
                  foregroundColor: c.brandTerracottaInk,
                  fontSize: 11.5,
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/beans/add');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeBeans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      PocketIcon(
                        PocketIconType.bean,
                        size: 28,
                        color: c.brandTerracotta,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada stok kopi aktif. Tambah biji kopi pertamamu dulu ya!',
                        textAlign: TextAlign.center,
                        style: PocketTheme.ui(
                          size: 12.5,
                          weight: 500,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeBeans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bean = activeBeans[index];
                    final selected = state.draft.beanId == bean.id;
                    final info = BeanRestingCalculator.evaluate(
                      bean: bean,
                      prefs: state.prefs,
                    );

                    return PocketTapScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.selectBean(bean.id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? c.tintSage.withValues(alpha: 0.65)
                              : c.surfaceCanvas,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? c.brandSage : c.borderSubtle,
                            width: selected ? 1.3 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: info.isLastCupAlert
                                    ? c.tintHoney
                                    : c.tintSage,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              alignment: Alignment.center,
                              child: PocketIcon(
                                PocketIconType.bean,
                                size: 17,
                                color: info.isLastCupAlert
                                    ? c.brandHoney
                                    : c.brandSage,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bean.name,
                                    style: PocketTheme.ui(
                                      size: 13.5,
                                      weight: 700,
                                      height: 1.25,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${bean.remainingG.round()}g stok · ${info.badgeText} · ${bean.process}${bean.isFrozen ? ' · Cadangan' : ''}',
                                    style: PocketTheme.mono(
                                      size: 10.5,
                                      weight: FontWeight.w500,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (selected)
                              PocketIcon(
                                PocketIconType.check,
                                size: 18,
                                color: c.brandSage,
                                strokeWidth: 2.2,
                              )
                            else
                              PocketIcon(
                                PocketIconType.chevronRight,
                                size: 16,
                                color: c.textTertiary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            PocketTapScale(
              onTap: () {
                Navigator.pop(context);
                context.go('/beans');
              },
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Kelola Semua Stok Kopi (${activeBeans.length}) →',
                  style: PocketTheme.ui(
                    size: 12.5,
                    weight: 600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
