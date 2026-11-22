import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_confirm_dialog.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/bean_resting_calculator.dart';
import '../../domain/engines/brew_recipe_scaler.dart';

/// Screen 14 · Detail Biji & Koreksi Stok (Redesigned):
/// - Clean Hero Profile Card with status badges, 3-KPI stock/dial-in strip & tasting notes
/// - Flexible actual stock input: free numeric TextField (supports decimals!) + ±1g fine step + quick delta chips
/// - Direct Brew CTA, Cadangan toggle, and permanent Delete Bean with confirmation modal (NO Archive!)
/// - Last-Cup Auto-Scale + per-bean Brew Log history.
class BeanDetailScreen extends ConsumerStatefulWidget {
  const BeanDetailScreen({super.key, required this.beanId});

  final String beanId;

  @override
  ConsumerState<BeanDetailScreen> createState() => _BeanDetailScreenState();
}

class _BeanDetailScreenState extends ConsumerState<BeanDetailScreen> {
  double? _stockDraftG;
  final TextEditingController _stockCtrl = TextEditingController();
  bool _controllerInitialized = false;

  @override
  void dispose() {
    _stockCtrl.dispose();
    super.dispose();
  }

  String _formatGramsInput(double v) {
    final isWhole = (v - v.roundToDouble()).abs() < 0.05;
    return isWhole ? v.round().toString() : v.toStringAsFixed(1);
  }

  void _syncStockDraft(double nextG, {bool updateTextField = true}) {
    final clamped = ((nextG * 10).round() / 10.0).clamp(0.0, 5000.0);
    setState(() {
      _stockDraftG = clamped;
      if (updateTextField) {
        final formatted = _formatGramsInput(clamped);
        _stockCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  Future<void> _confirmDeleteBean(String beanId, String beanName) async {
    final ok = await showPocketDeleteDialog(
      context,
      title: 'Hapus Biji Kopi?',
      message:
          'Biji "$beanName" akan dihapus permanen dari daftar stokmu. Catatan riwayat seduhan sebelumnya tetap aman.',
      confirmLabel: 'Hapus Biji',
    );
    if (!ok) return;
    ref.read(pocketStoreProvider.notifier).deleteBean(beanId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$beanName berhasil dihapus.')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/beans');
      }
    }
  }

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

    if (!_controllerInitialized) {
      _controllerInitialized = true;
      _stockCtrl.text = _formatGramsInput(bean.remainingG);
    }

    final actualG = _stockDraftG ?? bean.remainingG;
    final effectiveBagG =
        actualG > bean.bagWeightG ? actualG : bean.bagWeightG;
    final info = BeanRestingCalculator.evaluate(
      bean: bean.copyWith(remainingG: actualG, bagWeightG: effectiveBagG),
      prefs: state.prefs,
    );
    final beanLogs = state.logs.where((l) => l.beanId == bean.id).toList();
    final scaledWater = (actualG * 16.67).roundToDouble();
    final hasStockChanges =
        _stockDraftG != null && (_stockDraftG! - bean.remainingG).abs() >= 0.05;

    final statusLabel = bean.isFrozen ? 'Stok Cadangan' : 'Aktif Dipakai';
    final statusBg = bean.isFrozen ? c.tintIce : c.tintSage;
    final statusFg = bean.isFrozen ? c.brandIce : c.brandSage;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Detail Biji',
              onBack: () => context.pop(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PocketPill(
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
                  const SizedBox(width: 6),
                  PocketTapScale(
                    onTap: () => _confirmDeleteBean(bean.id, bean.name),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c.statusError.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: c.statusError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                children: [
                  // 1. HERO BEAN PROFILE CARD (Editorial layout, crisp metrics & full wrapping)
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
                              backgroundColor: info.stage ==
                                      BeanFreshnessStage.resting
                                  ? c.tintIce
                                  : c.tintSage,
                              foregroundColor: info.stage ==
                                      BeanFreshnessStage.resting
                                  ? c.brandIce
                                  : c.brandSage,
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
                        const SizedBox(height: 12),
                        Text(
                          bean.name,
                          style: PocketTheme.ui(
                            size: 21,
                            weight: 800,
                            height: 1.2,
                            letterSpacing: -0.3,
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
                            size: 12.8,
                            weight: 500,
                            height: 1.35,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          info.subtitle,
                          style: PocketTheme.ui(
                            size: 12,
                            weight: 600,
                            height: 1.35,
                            color: c.brandSage,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3-Column Crisp Metric Strip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: c.isDark
                                ? c.surfaceElevated
                                : c.surfaceCanvas,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: c.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              _BeanKpi(
                                label: 'Sisa Stok',
                                value:
                                    '${_formatGramsInput(actualG)}g',
                                sub: 'dari ${effectiveBagG.round()}g',
                                highlight: info.isLastCupAlert
                                    ? c.brandHoney
                                    : c.brandSage,
                              ),
                              _BeanKpi(
                                label: 'Estimasi',
                                value: '~${info.cupsRemaining} cup',
                                sub: 'dosis 15g',
                              ),
                              _BeanKpi(
                                label: 'Klik Andalan',
                                value: bean.preferredHotClick != null
                                    ? '${bean.preferredHotClick} klik'
                                    : 'Belum',
                                sub: bean.preferredIcedClick != null
                                    ? 'Es: ${bean.preferredIcedClick}'
                                    : 'Hot V60',
                                highlight: bean.preferredHotClick != null
                                    ? c.brandTerracottaInk
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
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
                          const SizedBox(height: 14),
                          Text(
                            'Notes Rasa Kemasan',
                            style: PocketTheme.ui(
                              size: 11,
                              weight: 700,
                              color: c.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
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

                  // 2. FLEXIBLE KOREKSI SISA STOK AKTUAL (Free numeric input + ±1g + quick deltas!)
                  PocketCard(
                    backgroundColor: c.tintHoney,
                    borderColor: c.brandHoney.withValues(alpha: 0.25),
                    elevated: false,
                    radius: 20,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Koreksi Sisa Stok Aktual',
                                style: PocketTheme.ui(
                                  size: 14,
                                  weight: 800,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PocketPill(
                              label:
                                  'Tercatat: ${_formatGramsInput(bean.remainingG)}g',
                              isMono: true,
                              height: 24,
                              fontSize: 10.5,
                              backgroundColor: c.surfaceCard,
                              foregroundColor: c.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ketik langsung berat aktual di timbangan (bisa desimal, mis. 18.5) atau pakai tombol cepat di bawah.',
                          style: PocketTheme.ui(
                            size: 11.8,
                            weight: 500,
                            height: 1.38,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Flexible Editable Input Box + Fine -1g / +1g Steppers
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              PocketTapScale(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _syncStockDraft(actualG - 1);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _stockCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    final normalized =
                                        val.trim().replaceAll(',', '.');
                                    if (normalized.isEmpty) {
                                      setState(() => _stockDraftG = 0.0);
                                      return;
                                    }
                                    final parsed = double.tryParse(normalized);
                                    if (parsed != null) {
                                      setState(() {
                                        _stockDraftG =
                                            parsed.clamp(0.0, 5000.0);
                                      });
                                    }
                                  },
                                  style: PocketTheme.mono(
                                    size: 24,
                                    weight: FontWeight.w800,
                                    color: c.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: c.isDark
                                        ? c.surfaceElevated
                                        : c.surfaceCanvas,
                                    suffixText: 'g',
                                    suffixStyle: PocketTheme.mono(
                                      size: 16,
                                      weight: FontWeight.w700,
                                      color: c.textSecondary,
                                    ),
                                    hintText: '0',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: c.borderSubtle),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: c.brandTerracotta,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              PocketTapScale(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _syncStockDraft(actualG + 1);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
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

                        // Quick flexible delta & preset chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            PocketPill(
                              label: '−10g',
                              isMono: true,
                              height: 30,
                              backgroundColor: c.surfaceCard,
                              foregroundColor: c.textPrimary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _syncStockDraft(actualG - 10);
                              },
                            ),
                            PocketPill(
                              label: '−5g',
                              isMono: true,
                              height: 30,
                              backgroundColor: c.surfaceCard,
                              foregroundColor: c.textPrimary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _syncStockDraft(actualG - 5);
                              },
                            ),
                            PocketPill(
                              label: '+5g',
                              isMono: true,
                              height: 30,
                              backgroundColor: c.surfaceCard,
                              foregroundColor: c.textPrimary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _syncStockDraft(actualG + 5);
                              },
                            ),
                            PocketPill(
                              label: '+10g',
                              isMono: true,
                              height: 30,
                              backgroundColor: c.surfaceCard,
                              foregroundColor: c.textPrimary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _syncStockDraft(actualG + 10);
                              },
                            ),
                            PocketPill(
                              label: '0g (Habis)',
                              height: 30,
                              backgroundColor: c.surfaceCard,
                              foregroundColor: c.statusError,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _syncStockDraft(0);
                              },
                            ),
                            if (hasStockChanges)
                              PocketPill(
                                label:
                                    'Reset (${_formatGramsInput(bean.remainingG)}g)',
                                height: 30,
                                backgroundColor: c.surfaceElevated,
                                foregroundColor: c.textSecondary,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _stockDraftG = null;
                                    final f =
                                        _formatGramsInput(bean.remainingG);
                                    _stockCtrl.value = TextEditingValue(
                                      text: f,
                                      selection: TextSelection.collapsed(
                                        offset: f.length,
                                      ),
                                    );
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Last-Cup Auto-Scale Card (if stock is in single-cup range)
                  if (actualG >= 8 && actualG <= 30) ...[
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
                            'Habiskan Sekali Brew (Auto-Scale ${_formatGramsInput(actualG)}g)',
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
                    const SizedBox(height: 12),
                  ],

                  // 4. AKSI BIJI CARD (Brew + Cadangan + Hapus Biji — NO Archive!)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    elevated: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aksi Biji Kopi',
                          style: PocketTheme.ui(
                            size: 13,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        PocketButton(
                          label: 'Brew Biji Ini',
                          pocketIcon: PocketIconType.v60,
                          iconSize: 16,
                          height: 46,
                          backgroundColor: c.brandTerracotta,
                          foregroundColor: c.textOnAccent,
                          onTap: () {
                            if (hasStockChanges) {
                              notifier.correctBeanStock(bean.id, actualG);
                            }
                            notifier.updateDraft(
                              beanId: bean.id,
                              clickSetting: bean.preferredHotClick ??
                                  state.draft.clickSetting,
                            );
                            context.go('/brew');
                          },
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
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
                                borderColor:
                                    bean.isFrozen ? null : c.borderStrong,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  notifier.toggleBeanFreeze(bean.id);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PocketButton(
                                label: 'Hapus Biji',
                                icon: Icons.delete_outline_rounded,
                                iconSize: 15,
                                height: 44,
                                fontSize: 12.5,
                                backgroundColor:
                                    c.statusError.withValues(alpha: 0.14),
                                foregroundColor: c.statusError,
                                borderColor:
                                    c.statusError.withValues(alpha: 0.35),
                                onTap: () =>
                                    _confirmDeleteBean(bean.id, bean.name),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                                style: PocketTheme.ui(
                                  size: 13,
                                  weight: 800,
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
                          ...beanLogs.take(5).map((l) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: PocketTapScale(
                                onTap: () => context.push('/log/${l.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 9,
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
                                          style: PocketTheme.mono(
                                            size: 11.2,
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
                    ? 'Simpan Koreksi Stok (${_formatGramsInput(actualG)}g)'
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
                          'Stok ${bean.name} diperbarui ke ${_formatGramsInput(actualG)}g ✓',
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

class _BeanKpi extends StatelessWidget {
  const _BeanKpi({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight,
  });

  final String label;
  final String value;
  final String sub;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: PocketTheme.ui(
              size: 10,
              weight: 600,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: PocketTheme.mono(
                size: 14.5,
                weight: FontWeight.w800,
                color: highlight ?? c.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              sub,
              style: PocketTheme.ui(
                size: 10,
                weight: 500,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
