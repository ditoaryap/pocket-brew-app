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
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Clean, joyful Evaluasi Seduh:
/// - Focused on what home brewers actually want after brewing:
///   1) Summary of the brew (bean, clicks, temp, water, time)
///   2) Rating stars + 1-tap "Favorit ★" toggle
///   3) Interactive 4-bar flavor profile (Asam, Manis, Pahit, Body)
///   4) Tasting notes connected directly to the active bean's flavor profile + Roda Rasa + memo
///   5) Clean "Simpan Log" CTA (with quiet optional stock deduction toggle).
class EvaluationScreen extends ConsumerStatefulWidget {
  const EvaluationScreen({super.key});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  double _rating = 4.0;
  FlavorBars _bars = const FlavorBars(
    acidity: 3.5,
    sweetness: 4.0,
    bitterness: 2.0,
    body: 3.0,
  );
  bool _deductStock = true;
  final _notesCtrl = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _initializedBeanTags = false;

  static const _fallbackQuickNotes = [
    'Manis',
    'Clean',
    'Floral',
    'Citrus',
    'Berry',
    'Caramel',
    'Chocolate',
    'Tea-like',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _ratingWord(double r) {
    if (r >= 4.8) return 'Istimewa!';
    if (r >= 4.0) return 'Enak & Pas';
    if (r >= 3.0) return 'Cukup Oke';
    if (r >= 2.0) return 'Kurang Pas';
    return 'Perlu Diubah';
  }

  TasteFeeling _inferFeeling() {
    if (_rating >= 4.0 &&
        _bars.sweetness >= 3.5 &&
        _bars.bitterness <= 3.0 &&
        _bars.acidity <= 4.0) {
      return TasteFeeling.balancedSweet;
    }
    if (_bars.bitterness >= 3.8) return TasteFeeling.bitterDry;
    if (_bars.acidity >= 4.0 && _bars.sweetness <= 3.0) {
      return TasteFeeling.sourSharp;
    }
    if (_bars.body <= 2.0) return TasteFeeling.wateryWeak;
    return TasteFeeling.balancedSweet;
  }

  void _toggleTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    ref
        .read(pocketStoreProvider.notifier)
        .setPendingEvaluationTags(_selectedTags.toList());
  }

  Future<void> _openFlavorWheel() async {
    final current = _selectedTags.toList();
    ref.read(pocketStoreProvider.notifier).setPendingEvaluationTags(current);
    final result = await context.push<List<String>>(
      '/evaluation/wheel',
      extra: current,
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedTags
        ..clear()
        ..addAll(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final store = ref.watch(pocketStoreProvider);
    final pending = store.pendingEval;
    final unit = store.prefs.unitMode;

    final activeBean = pending?.beanId != null
        ? store.beans.where((b) => b.id == pending!.beanId).firstOrNull
        : store.activeBean;
    final beanNotes = activeBean?.tastingNotes ?? const <String>[];

    // Initialize tags ONCE from pendingEval (if already picked) or the active bean's tasting notes
    if (!_initializedBeanTags) {
      _initializedBeanTags = true;
      final fromPending = pending?.selectedTags ?? const <String>[];
      if (fromPending.isNotEmpty) {
        _selectedTags.addAll(fromPending);
      } else if (beanNotes.isNotEmpty) {
        _selectedTags.addAll(beanNotes.take(2));
      }
    }

    final click = pending?.clickSetting ?? store.draft.clickSetting;
    final tempC = pending?.tempC ?? store.currentPlan.tempC;
    final actualSec = pending?.actualDrawdownSec ??
        store.activeRecipe.targetDrawdownSec;
    final doseG = pending?.doseG ?? store.currentPlan.doseG;
    final totalLiquidG = pending?.totalLiquidG ?? store.currentPlan.totalLiquidG;
    final mode = pending?.mode ?? store.draft.mode;
    final isIced = mode == BrewMode.iced;
    final beanName =
        pending?.beanName ?? (activeBean?.name ?? 'Biji Kopi Pilihan');

    // Single source of truth: `_selectedTags`!
    final extraSuggestions = _fallbackQuickNotes
        .where((n) => !beanNotes.contains(n))
        .take(beanNotes.isEmpty ? 6 : 4)
        .toList();
    final customWheelTags = _selectedTags
        .where((t) => !beanNotes.contains(t) && !extraSuggestions.contains(t))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Evaluasi Seduh',
              onBack: () => context.go('/home'),
              trailing: PocketPill(
                label: 'Roda Rasa',
                pocketIcon: PocketIconType.compass,
                backgroundColor: c.tintTerracotta,
                foregroundColor: c.brandTerracottaInk,
                onTap: _openFlavorWheel,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                children: [
                  // 1. Compact, Easy-to-Read Brew Summary Card
                  PocketEntrance(
                    delayMs: 0,
                    offsetY: 8,
                    child: PocketCard(
                      padding: const EdgeInsets.all(14),
                      radius: 20,
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
                                      beanName,
                                      style: PocketTheme.ui(
                                        size: 15,
                                        weight: 800,
                                        height: 1.25,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pending?.recipeName ?? store.activeRecipe.name} · ${BrewRecipeScaler.formatDose(doseG)}',
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
                              PocketPill(
                                label: isIced ? 'Japanese Iced' : 'Hot V60',
                                backgroundColor:
                                    isIced ? c.tintIce : c.tintTerracotta,
                                foregroundColor: isIced
                                    ? c.brandIce
                                    : c.brandTerracottaInk,
                                fontSize: 10.5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              _EvalKpiTile(label: 'Giling', value: '$click klik'),
                              const SizedBox(width: 6),
                              _EvalKpiTile(
                                label: 'Suhu',
                                value: BrewRecipeScaler.formatTemp(
                                  tempC,
                                  store.prefs.tempUnit,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _EvalKpiTile(
                                label: isIced ? 'Total' : 'Air',
                                value: BrewRecipeScaler.formatLiquidCompact(
                                  totalLiquidG,
                                  unit,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _EvalKpiTile(
                                label: 'Waktu',
                                value: BrewRecipeScaler.formatShortDuration(
                                  actualSec,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Hero Rating + 1-Tap Favorit Card
                  PocketEntrance(
                    delayMs: 40,
                    offsetY: 8,
                    child: PocketCard(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
                      radius: 20,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Seberapa enak cangkir ini?',
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
                              PocketPill(
                                label:
                                    '${_rating.toStringAsFixed(1)} · ${_ratingWord(_rating)}',
                                backgroundColor: c.tintHoney,
                                foregroundColor: c.brandHoney,
                                fontSize: 11,
                                isMono: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Interactive 5 Stars (supports half-star .5 display & toggle!)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (idx) {
                              final fullVal = idx + 1.0;
                              final halfVal = idx + 0.5;
                              final isFull = _rating >= fullVal;
                              final isHalf = !isFull && _rating >= halfVal;
                              return PocketTapScale(
                                pressedScale: 0.86,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    // Tap same full star again to step to half (e.g. 5.0 -> 4.5)
                                    if ((_rating - fullVal).abs() < 0.05 &&
                                        fullVal > 1.0) {
                                      _rating = halfVal;
                                    } else {
                                      _rating = fullVal;
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: AnimatedScale(
                                    scale: (isFull || isHalf) ? 1.07 : 0.96,
                                    duration: PocketCurves.fast,
                                    curve: PocketCurves.gentleSpring,
                                    child: SizedBox(
                                      width: 34,
                                      height: 34,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          PocketIcon(
                                            PocketIconType.star,
                                            size: 32,
                                            color: c.borderStrong,
                                          ),
                                          if (isFull)
                                            PocketIcon(
                                              PocketIconType.starFilled,
                                              size: 32,
                                              color: c.brandHoney,
                                            )
                                          else if (isHalf)
                                            ClipRect(
                                              clipper: _LeftHalfClipper(),
                                              child: PocketIcon(
                                                PocketIconType.starFilled,
                                                size: 32,
                                                color: c.brandHoney,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),

                          // Fine 0.5 Rating Precision Controls (`− 0.5` / `4.5 ★` / `+ 0.5` + quick chips)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PocketTapScale(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _rating = ((_rating - 0.5) * 2)
                                              .round()
                                              .clamp(2, 10) /
                                          2.0;
                                    });
                                  },
                                  child: Container(
                                    height: 30,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.surfaceElevated,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '− 0.5',
                                      style: PocketTheme.mono(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '★ ${_rating.toStringAsFixed(1)} / 5.0',
                                  style: PocketTheme.mono(
                                    size: 13.5,
                                    weight: FontWeight.w800,
                                    color: c.brandHoney,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                PocketTapScale(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _rating = ((_rating + 0.5) * 2)
                                              .round()
                                              .clamp(2, 10) /
                                          2.0;
                                    });
                                  },
                                  child: Container(
                                    height: 30,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.surfaceElevated,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '+ 0.5',
                                      style: PocketTheme.mono(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [3.5, 4.0, 4.5, 5.0].map((preset) {
                              final sel = (_rating - preset).abs() < 0.05;
                              return PocketPill(
                                label: preset.toStringAsFixed(1),
                                isMono: true,
                                height: 26,
                                fontSize: 11,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                backgroundColor:
                                    sel ? c.brandHoney : c.surfaceElevated,
                                foregroundColor:
                                    sel ? c.textOnAccent : c.textSecondary,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _rating = preset);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Karakter Rasa (4 Real Tactile Sliders with clear draggable thumbs!)
                  PocketEntrance(
                    delayMs: 80,
                    offsetY: 8,
                    child: PocketCard(
                      padding: const EdgeInsets.all(15),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Karakter Rasa',
                            style: PocketTheme.ui(
                              size: 13.5,
                              weight: 800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Geser titik slider ke kiri atau kanan sesuai rasa di cangkirmu',
                            style: PocketTheme.ui(
                              size: 11.2,
                              weight: 500,
                              color: c.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _FlavorSliderRow(
                            label: 'Keasaman (Acidity)',
                            lowLabel: 'Lembut',
                            highLabel: 'Cerah / Tajam',
                            value: _bars.acidity,
                            color: c.brandHoney,
                            onChanged: (v) => setState(
                              () => _bars = _bars.copyWith(acidity: v),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _FlavorSliderRow(
                            label: 'Rasa Manis (Sweetness)',
                            lowLabel: 'Tipis',
                            highLabel: 'Manis Kaya',
                            value: _bars.sweetness,
                            color: c.brandSage,
                            onChanged: (v) => setState(
                              () => _bars = _bars.copyWith(sweetness: v),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _FlavorSliderRow(
                            label: 'Pahit (Bitterness)',
                            lowLabel: 'Hampir Tidak',
                            highLabel: 'Kuat / Pekat',
                            value: _bars.bitterness,
                            color: c.brandTerracotta,
                            onChanged: (v) => setState(
                              () => _bars = _bars.copyWith(bitterness: v),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _FlavorSliderRow(
                            label: 'Kekentalan (Body)',
                            lowLabel: 'Ringan (Tea-like)',
                            highLabel: 'Tebal / Creamy',
                            value: _bars.body,
                            color: c.brandIce,
                            onChanged: (v) => setState(
                              () => _bars = _bars.copyWith(body: v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Notes Rasa dari Biji + Roda Rasa + Catatan Singkat
                  PocketEntrance(
                    delayMs: 120,
                    offsetY: 8,
                    child: PocketCard(
                      padding: const EdgeInsets.all(15),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Notes Rasa yang Keluar',
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
                              PocketTapScale(
                                onTap: _openFlavorWheel,
                                child: Text(
                                  '+ Roda Rasa',
                                  style: PocketTheme.ui(
                                    size: 11.5,
                                    weight: 700,
                                    color: c.brandTerracottaInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (beanNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Dari profil $beanName (ketuk untuk pilih/batal):',
                              style: PocketTheme.ui(
                                size: 11,
                                weight: 500,
                                color: c.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: beanNotes.map((note) {
                                final active = _selectedTags.contains(note);
                                return PocketPill(
                                  label: active ? '$note ✓' : note,
                                  backgroundColor: active
                                      ? c.brandBerry
                                      : c.tintBerry,
                                  foregroundColor:
                                      active ? c.textOnAccent : c.brandBerry,
                                  borderColor: active
                                      ? c.brandBerry
                                      : c.brandBerry.withValues(alpha: 0.25),
                                  fontSize: 11.5,
                                  onTap: () => _toggleTag(note),
                                );
                              }).toList(),
                            ),
                          ],
                          if (customWheelTags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Dipilih dari Roda Rasa:',
                              style: PocketTheme.ui(
                                size: 11,
                                weight: 500,
                                color: c.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: customWheelTags.map((tag) {
                                return PocketPill(
                                  label: '$tag ×',
                                  backgroundColor: c.tintTerracotta,
                                  foregroundColor: c.brandTerracottaInk,
                                  fontSize: 11,
                                  onTap: () => _toggleTag(tag),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Tambahan cepat:',
                            style: PocketTheme.ui(
                              size: 11,
                              weight: 500,
                              color: c.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: extraSuggestions.map((tag) {
                              final active = _selectedTags.contains(tag);
                              return PocketPill(
                                label: active ? '$tag ✓' : '+ $tag',
                                backgroundColor: active
                                    ? c.brandEspresso
                                    : c.surfaceElevated,
                                foregroundColor:
                                    active ? c.textOnAccent : c.textSecondary,
                                fontSize: 11,
                                onTap: () => _toggleTag(tag),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            minLines: 1,
                            style: PocketTheme.ui(
                              size: 12.5,
                              weight: 500,
                              color: c.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              hintText: 'Catatan rasa pribadi (opsional)...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Compact 1-row optional stock deduction switch right above Save CTA
                  if (activeBean != null) ...[
                    const SizedBox(height: 10),
                    PocketCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      radius: 16,
                      elevated: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kurangi stok biji (−${BrewRecipeScaler.formatDose(doseG)})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PocketTheme.ui(
                                size: 12,
                                weight: 700,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: _deductStock,
                            activeTrackColor: c.brandSage,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _deductStock = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Clean, Calm Primary CTA ("Simpan Log")
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: PocketButton(
                label: 'Simpan Log',
                pocketIcon: PocketIconType.check,
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                height: 52,
                onTap: () {
                  final saved = ref
                      .read(pocketStoreProvider.notifier)
                      .saveEvaluatedBrew(
                        feeling: _inferFeeling(),
                        rating: _rating,
                        bars: _bars,
                        tags: _selectedTags.toList(),
                        notes: _notesCtrl.text,
                        isGolden: _rating >= 4.5,
                        applyRecommendedClickForTomorrow: false,
                        recommendedClick: click,
                        recommendedTempC: tempC,
                        deductBeanStock: _deductStock,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catatan seduhan berhasil disimpan ✓'),
                    ),
                  );
                  context.go('/log/${saved.id}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvalKpiTile extends StatelessWidget {
  const _EvalKpiTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(11),
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
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: PocketTheme.mono(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * 0.5, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// Real tactile Slider with circular thumb knob & endpoint labels so users immediately see it is draggable!
class _FlavorSliderRow extends StatelessWidget {
  const _FlavorSliderRow({
    required this.label,
    required this.lowLabel,
    required this.highLabel,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final String lowLabel;
  final String highLabel;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 6),
      decoration: BoxDecoration(
        color: c.isDark ? c.surfaceElevated : c.surfaceCanvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PocketTheme.ui(
                    size: 12.2,
                    weight: 700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${value == value.roundToDouble() ? value.round() : value.toStringAsFixed(1)} / 5',
                  style: PocketTheme.mono(
                    size: 11,
                    weight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: color,
              inactiveTrackColor: c.borderSubtle,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Slider(
              min: 1.0,
              max: 5.0,
              divisions: 8,
              value: value.clamp(1.0, 5.0),
              onChanged: (v) {
                final stepped = (v * 2).round() / 2.0;
                if ((stepped - value).abs() >= 0.45) {
                  HapticFeedback.selectionClick();
                }
                onChanged(stepped.clamp(1.0, 5.0));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lowLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PocketTheme.ui(
                      size: 10,
                      weight: 500,
                      color: c.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    highLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: PocketTheme.ui(
                      size: 10,
                      weight: 500,
                      color: c.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
