import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';
import '../../domain/engines/brew_recipe_scaler.dart';

/// Screen 14 · Detail Biji & Koreksi Stok:
/// - Crisp top Edit CTA (opens AddBeanScreen in Edit mode for custom resting, process, roast, etc.)
/// - High-contrast, clearly readable Aktifkan / Arsipkan & Stok Cadangan action buttons
/// - Stock Opname stepper + Last-Cup Auto-Scale + per-bean Brew Log history.
class BeanDetailScreen extends ConsumerStatefulWidget {
  const BeanDetailScreen({super.key, required this.beanId});

  final String beanId;

  @override
  ConsumerState<BeanDetailScreen> createState() => _BeanDetailScreenState();
}

class _BeanDetailScreenState extends ConsumerState<BeanDetailScreen> {
  double? _stockDraftG;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);
    final bean = state.beans.where((b) => b.id == widget.beanId).firstOrNull;

    if (bean == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PocketTopBar(title: 'Detail Biji', onBack: () => context.pop()),
              const Expanded(
                child: Center(child: Text('Biji tidak ditemukan.')),
              ),
            ],
          ),
        ),
      );
    }

    final actualG = _stockDraftG ?? bean.remainingG;
    final info = BeanRestingCalculator.evaluate(
      bean: bean.copyWith(remainingG: actualG),
      prefs: state.prefs,
    );
    final beanLogs = state.logs.where((l) => l.beanId == bean.id).toList();
    final scaledWater = (actualG * 16.67).roundToDouble();
    final hasStockChanges =
        _stockDraftG != null && (_stockDraftG! - bean.remainingG).abs() >= 0.1;

    final statusLabel = bean.isArchived
        ? 'Diarsipkan'
        : (bean.isFrozen ? 'Stok Cadangan' : 'Aktif Dipakai');
    final statusBg = bean.isArchived
        ? c.surfaceElevated
        : (bean.isFrozen ? c.tintIce : c.tintSage);
    final statusFg = bean.isArchived
        ? c.textSecondary
        : (bean.isFrozen ? c.brandIce : c.brandSage);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Detail Biji',
              onBack: () => context.pop(),
              trailing: PocketPill(
                label: 'Edit',
                pocketIcon: PocketIconType.edit,
                iconSize: 13,
                height: 34,
                fontSize: 12,
                fontWeight: 700,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: c.tintTerracotta,
                foregroundColor: c.brandTerracottaInk,
                onTap: () => context.push('/beans/edit/${bean.id}'),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                children: [
                  // 1. Hero Bean Profile Card
                  PocketCard(
                    padding: const EdgeInsets.all(16),
                    radius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            PocketPill(
                              label: statusLabel,
                              height: 24,
                              fontSize: 10.5,
                              backgroundColor: statusBg,
                              foregroundColor: statusFg,
                            ),
                            PocketPill(
                              label: info.badgeText,
                              height: 24,
                              fontSize: 10.5,
                              isMono: true,
                              backgroundColor: c.tintSage,
                              foregroundColor: c.brandSage,
                            ),
                            if (bean.hasCustomResting)
                              PocketPill(
                                label:
                                    'Masa Enak ${bean.customRestMinD}–${bean.customRestMaxD} hr',
                                height: 24,
                                fontSize: 10,
                                isMono: true,
                                backgroundColor: c.surfaceElevated,
                                foregroundColor: c.textSecondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          bean.name,
                          style: PocketTheme.ui(
                            size: 20,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            bean.roastery,
                            bean.process,
                            bean.roastLevel.label,
                            if (bean.variety.isNotEmpty) bean.variety,
                          ].join(' · '),
                          style: PocketTheme.ui(
                            size: 12.5,
                            weight: 500,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          info.subtitle,
                          style: PocketTheme.ui(
                            size: 12,
                            weight: 600,
                            color: c.brandSage,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Stock progress summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Stok: ${actualG.round()}g / ${bean.bagWeightG.round()}g',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PocketTheme.mono(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '~${info.cupsRemaining} cup tersisa',
                              style: PocketTheme.mono(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: info.stockFraction,
                            minHeight: 7,
                            backgroundColor: c.surfaceElevated,
                            color: info.isLastCupAlert
                                ? c.brandHoney
                                : c.brandSage,
                          ),
                        ),
                        if (bean.tastingNotes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: bean.tastingNotes
                                .map(
                                  (n) => PocketPill(
                                    label: n,
                                    backgroundColor: c.tintBerry,
                                    foregroundColor: c.brandBerry,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. High-Contrast Status & Quick Actions Card (CLEAR Aktifkan / Arsipkan!)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    elevated: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aksi & Status Biji',
                          style: PocketTheme.ui(
                            size: 13,
                            weight: 700,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!bean.isArchived) ...[
                          PocketButton(
                            label: 'Brew Biji Ini',
                            pocketIcon: PocketIconType.v60,
                            iconSize: 16,
                            height: 46,
                            backgroundColor: c.brandTerracotta,
                            foregroundColor: c.textOnAccent,
                            onTap: () {
                              notifier.updateDraft(
                                beanId: bean.id,
                                clickSetting: bean.preferredHotClick ??
                                    state.draft.clickSetting,
                              );
                              context.go('/brew');
                            },
                          ),
                          const SizedBox(height: 9),
                        ],
                        Row(
                          children: [
                            if (!bean.isArchived) ...[
                              Expanded(
                                child: PocketButton(
                                  label: bean.isFrozen
                                      ? 'Pakai Aktif'
                                      : 'Simpan Cadangan',
                                  height: 44,
                                  fontSize: 12.5,
                                  backgroundColor: bean.isFrozen
                                      ? c.brandSage
                                      : c.surfaceElevated,
                                  foregroundColor: bean.isFrozen
                                      ? c.textOnAccent
                                      : c.textPrimary,
                                  borderColor: bean.isFrozen
                                      ? null
                                      : c.borderStrong,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    notifier.toggleBeanFreeze(bean.id);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: PocketButton(
                                label: bean.isArchived
                                    ? 'Aktifkan Kembali'
                                    : 'Arsipkan Biji',
                                height: 44,
                                fontSize: 12.5,
                                backgroundColor: bean.isArchived
                                    ? c.brandSage
                                    : c.statusError.withValues(alpha: 0.14),
                                foregroundColor: bean.isArchived
                                    ? c.textOnAccent
                                    : c.statusError,
                                borderColor: bean.isArchived
                                    ? null
                                    : c.statusError.withValues(alpha: 0.35),
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  final willArchive = !bean.isArchived;
                                  notifier.toggleBeanArchive(bean.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        willArchive
                                            ? '${bean.name} dipindahkan ke Arsip.'
                                            : '${bean.name} diaktifkan kembali ✓',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Stock Opname Correction Card
                  PocketCard(
                    backgroundColor: c.tintHoney,
                    elevated: false,
                    radius: 20,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Koreksi Sisa Stok Aktual',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PocketTheme.ui(
                                  size: 13.5,
                                  weight: 800,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tercatat: ${bean.remainingG.round()}g',
                              style: PocketTheme.mono(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Berat asli di timbangan berbeda? Sesuaikan langsung tanpa mengubah catatan Brew Log.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PocketTapScale(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _stockDraftG =
                                        (actualG - 5).clamp(0, bean.bagWeightG);
                                  });
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: c.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: PocketIcon(
                                    PocketIconType.minus,
                                    size: 16,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${actualG.toStringAsFixed(1)} g',
                                style: PocketTheme.mono(
                                  size: 26,
                                  weight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                              ),
                              PocketTapScale(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _stockDraftG =
                                        (actualG + 5).clamp(0, bean.bagWeightG);
                                  });
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: c.brandEspresso,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: PocketIcon(
                                    PocketIconType.plus,
                                    size: 16,
                                    color: c.textOnAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: PocketPill(
                                label: '0g (Habis)',
                                height: 32,
                                backgroundColor: c.surfaceCard,
                                foregroundColor: c.textPrimary,
                                onTap: () => setState(() => _stockDraftG = 0),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: PocketPill(
                                label: '15g (1 cup)',
                                height: 32,
                                backgroundColor: c.surfaceCard,
                                foregroundColor: c.textPrimary,
                                onTap: () => setState(() => _stockDraftG = 15),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: PocketPill(
                                label: 'Reset (${bean.remainingG.round()}g)',
                                height: 32,
                                backgroundColor: c.surfaceCard,
                                foregroundColor: c.textSecondary,
                                onTap: () =>
                                    setState(() => _stockDraftG = null),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Last-Cup Auto-Scale Card
                  if (actualG >= 8 && actualG <= 30) ...[
                    const SizedBox(height: 12),
                    PocketCard(
                      backgroundColor: c.tintTerracotta,
                      borderColor: Colors.transparent,
                      elevated: false,
                      radius: 20,
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habiskan Sekali Brew (Auto-Scale ${actualG.round()}g)',
                            style: PocketTheme.ui(
                              size: 13.5,
                              weight: 800,
                              color: c.brandTerracottaInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${actualG.toStringAsFixed(1)}g kopi → ${BrewRecipeScaler.formatLiquid(scaledWater, state.prefs.unitMode)} air (1:16.7) · ${bean.preferredHotClick ?? state.draft.clickSetting} klik · sisa 0g.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          PocketButton(
                            label: 'Buka di Brew →',
                            height: 44,
                            backgroundColor: c.brandTerracotta,
                            foregroundColor: c.textOnAccent,
                            onTap: () {
                              notifier.correctBeanStock(bean.id, actualG);
                              notifier.startLastCupBrew(
                                bean.copyWith(remainingG: actualG),
                              );
                              context.go('/brew');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 5. Riwayat Seduhan Biji Ini
                  PocketCard(
                    padding: const EdgeInsets.all(14),
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
                                'Riwayat Biji Ini (${beanLogs.length} seduhan)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PocketTheme.ui(
                                  size: 13,
                                  weight: 700,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            if (bean.preferredHotClick != null)
                              Text(
                                'Andalan: ${bean.preferredHotClick} klik',
                                style: PocketTheme.mono(
                                  size: 11,
                                  color: c.brandTerracottaInk,
                                  weight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                        if (beanLogs.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Belum ada catatan seduhan untuk biji ini.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          ...beanLogs.take(3).map((l) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: PocketTapScale(
                                onTap: () => context.push('/log/${l.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.surfaceElevated,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '★ ${l.rating.toStringAsFixed(1)}',
                                        style: PocketTheme.mono(
                                          size: 12,
                                          weight: FontWeight.w800,
                                          color: c.brandHoney,
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          '${l.mode.shortBadge} · ${l.clickSetting} klik · ${BrewRecipeScaler.formatDuration(l.actualDrawdownSec)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: PocketTheme.mono(
                                            size: 11,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                      ),
                                      PocketIcon(
                                        PocketIconType.chevronRight,
                                        size: 14,
                                        color: c.textTertiary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Bottom Save Stock Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: hasStockChanges
                    ? 'Simpan Koreksi Stok (${actualG.round()}g)'
                    : 'Selesai & Kembali',
                pocketIcon: PocketIconType.check,
                backgroundColor:
                    hasStockChanges ? c.brandTerracotta : c.brandEspresso,
                foregroundColor: c.textOnAccent,
                height: 50,
                onTap: () {
                  if (hasStockChanges) {
                    notifier.correctBeanStock(bean.id, actualG);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Stok ${bean.name} diperbarui ke ${actualG.round()}g ✓',
                        ),
                      ),
                    );
                  }
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
