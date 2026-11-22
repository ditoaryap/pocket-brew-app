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
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Screen 03 · Metode & Resep Seduh:
/// - Smooth sliding segment (`Resep Profesional` | `Resep Custom`) + Hot/Japanese filter
/// - Unified 1:xx ratio, explicit hot water + temp + drawdown specs (ZERO g/L jargon!)
/// - Quick "Edit" action on EVERY recipe card (edit hot water, temp & stages easily!)
/// - Signature bottom Sage Custom Recipe quick-edit strip.
class MethodsScreen extends ConsumerStatefulWidget {
  const MethodsScreen({super.key});

  @override
  ConsumerState<MethodsScreen> createState() => _MethodsScreenState();
}

class _MethodsScreenState extends ConsumerState<MethodsScreen> {
  static const int _pageSize = 12;
  int _tab = 0; // 0 = Resep Profesional, 1 = Resep Custom
  String _modeFilter = 'all'; // all | hot | iced
  int _visibleCount = _pageSize;

  String _formatRatio(double r) {
    final isWhole = (r - r.roundToDouble()).abs() < 0.05;
    return isWhole ? '1:${r.round()}' : '1:${r.toStringAsFixed(1)}';
  }

  String _recipeSpecLine(BrewRecipe r, UserPrefs prefs) {
    final dur = BrewRecipeScaler.formatShortDuration(r.targetDrawdownSec);
    final temp = BrewRecipeScaler.formatTemp(r.tempC, prefs.tempUnit);
    final totalWater = r.waterG > 0 ? r.waterG : r.doseG * r.ratio;

    if (r.mode == BrewMode.iced) {
      final iceRatio = r.iceRatio > 0 ? r.iceRatio : 0.40;
      final hotWater = totalWater * (1.0 - iceRatio);
      final iceG = (totalWater * iceRatio).round();
      final hotLabel =
          BrewRecipeScaler.formatLiquidCompact(hotWater, prefs.unitMode);
      return '${_formatRatio(r.ratio)} · $hotLabel panas + ${iceG}g es · $temp · ~$dur';
    }

    final waterLabel =
        BrewRecipeScaler.formatLiquidCompact(totalWater, prefs.unitMode);
    return '${_formatRatio(r.ratio)} · $waterLabel · $temp · ${r.stages.length} tahap · ~$dur';
  }

  Future<void> _confirmDeleteRecipe(BrewRecipe recipe) async {
    final ok = await showPocketDeleteDialog(
      context,
      title: 'Hapus Metode Resep?',
      message: recipe.isOfficial
          ? 'Hapus resep bawaan "${recipe.name}" dari daftar? Jika nanti butuh lagi, kamu bisa memulihkannya di menu Pengaturan.'
          : 'Hapus resep custom "${recipe.name}" secara permanen?',
      confirmLabel: 'Hapus Resep',
    );
    if (!ok) return;
    ref.read(pocketStoreProvider.notifier).deleteRecipe(recipe.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${recipe.name} dihapus dari daftar resep.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);

    final proRecipes = state.recipes.where((r) => r.isOfficial).toList();
    final customRecipes = state.recipes.where((r) => !r.isOfficial).toList();
    final tabRecipes = _tab == 0 ? proRecipes : customRecipes;
    final shown = tabRecipes.where((r) {
      return switch (_modeFilter) {
        'hot' => r.mode == BrewMode.hot,
        'iced' => r.mode == BrewMode.iced,
        _ => true,
      };
    }).toList();
    final visibleShown = shown.take(_visibleCount).toList();
    final hasMore = shown.length > visibleShown.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar: Back + Metode & Resep + `+ Buat` terracotta capsule
            PocketTopBar(
              title: 'Metode & Resep',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              trailing: PocketPill(
                label: 'Buat',
                pocketIcon: PocketIconType.plus,
                iconSize: 15,
                height: 36,
                fontSize: 12.5,
                fontWeight: 600,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: c.tintTerracotta,
                foregroundColor: c.brandTerracottaInk,
                onTap: () => context.push('/brew/stages?new=1'),
              ),
            ),

            // Smooth Full-Capsule Sliding Segment
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Container(
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
                      children: [
                        _SegmentLabel(
                          label: 'Resep Profesional (${proRecipes.length})',
                          selected: _tab == 0,
                          onTap: () {
                            if (_tab != 0) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _tab = 0;
                                _visibleCount = _pageSize;
                              });
                            }
                          },
                        ),
                        _SegmentLabel(
                          label: 'Resep Custom (${customRecipes.length})',
                          selected: _tab == 1,
                          onTap: () {
                            if (_tab != 1) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _tab = 1;
                                _visibleCount = _pageSize;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Clean Mode Filter Pills (Semua | Hot V60 | Japanese Iced)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ModeFilterChip(
                        label: 'Semua',
                        active: _modeFilter == 'all',
                        activeBg: c.brandEspresso,
                        onTap: () => setState(() {
                          _modeFilter = 'all';
                          _visibleCount = _pageSize;
                        }),
                      ),
                      const SizedBox(width: 7),
                      _ModeFilterChip(
                        label: 'Hot V60',
                        active: _modeFilter == 'hot',
                        activeBg: c.brandTerracotta,
                        onTap: () => setState(() {
                          _modeFilter = 'hot';
                          _visibleCount = _pageSize;
                        }),
                      ),
                      const SizedBox(width: 7),
                      _ModeFilterChip(
                        label: 'Japanese Iced',
                        active: _modeFilter == 'iced',
                        activeBg: c.brandIce,
                        onTap: () => setState(() {
                          _modeFilter = 'iced';
                          _visibleCount = _pageSize;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Recipe Cards + Bottom Sage Custom Strip
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: PocketCurves.smoothOut,
                child: shown.isEmpty
                    ? Center(
                        key: ValueKey('empty_${_tab}_$_modeFilter'),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: c.tintTerracotta,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: PocketIcon(
                                  PocketIconType.edit,
                                  size: 24,
                                  color: c.brandTerracottaInk,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada resep di filter ini',
                                style: PocketTheme.ui(
                                  size: 16,
                                  weight: 700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Buat resep custom sendiri — atur dosis, air panas, suhu, dan tahapan tuangan bebas.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 220,
                                child: PocketButton(
                                  label: 'Buat Resep Custom',
                                  pocketIcon: PocketIconType.plus,
                                  height: 46,
                                  backgroundColor: c.brandTerracotta,
                                  foregroundColor: c.textOnAccent,
                                  onTap: () =>
                                      context.push('/brew/stages?new=1'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        key: ValueKey('tab_${_tab}_$_modeFilter'),
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                        children: [
                          ...List.generate(visibleShown.length, (i) {
                            final r = visibleShown[i];
                            final isSelected = r.id == state.draft.recipeId;
                            final isIced = r.mode == BrewMode.iced;
                            final isCustom = !r.isOfficial;

                            final badgeBg = isCustom
                                ? c.tintSage
                                : (isIced ? c.tintIce : c.tintTerracotta);
                            final badgeFg = isCustom
                                ? c.brandSage
                                : (isIced
                                    ? c.brandIce
                                    : c.brandTerracottaInk);
                            final activeBorder = isIced
                                ? c.brandIce
                                : c.brandTerracotta;
                            final specColor = isSelected
                                ? (isIced ? c.brandIce : c.brandTerracottaInk)
                                : c.textSecondary;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: PocketEntrance(
                                delayMs: (i * 25).clamp(0, 150),
                                offsetY: 8,
                                child: PocketCard(
                                  borderColor:
                                      isSelected ? activeBorder : null,
                                  borderWidth: 1.35,
                                  radius: 18,
                                  elevated: false,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    notifier.selectRecipe(r.id);
                                    context.go('/brew');
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                isSelected
                                                    ? '${r.name} ✓'
                                                    : r.name,
                                                style: PocketTheme.ui(
                                                  size: 13.8,
                                                  weight: 700,
                                                  height: 1.25,
                                                  color: c.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            PocketPill(
                                              label: r.badge,
                                              backgroundColor: badgeBg,
                                              foregroundColor: badgeFg,
                                              fontSize: 10,
                                              fontWeight: 600,
                                              height: 22,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _recipeSpecLine(r, state.prefs),
                                          style: PocketTheme.mono(
                                            size: 11,
                                            weight: FontWeight.w600,
                                            height: 1.35,
                                            color: specColor,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.summary,
                                                style: PocketTheme.ui(
                                                  size: 11.8,
                                                  weight: 400,
                                                  height: 1.38,
                                                  color: c.textTertiary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PocketPill(
                                                  label: isCustom
                                                      ? 'Edit'
                                                      : 'Ubah',
                                                  pocketIcon:
                                                      PocketIconType.edit,
                                                  iconSize: 12.5,
                                                  height: 30,
                                                  fontSize: 11,
                                                  fontWeight: 600,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                  ),
                                                  backgroundColor:
                                                      c.surfaceElevated,
                                                  foregroundColor:
                                                      c.textPrimary,
                                                  onTap: () => context.push(
                                                    '/brew/stages?recipeId=${r.id}',
                                                  ),
                                                ),
                                                if (state.recipes.length >
                                                    1) ...[
                                                  const SizedBox(width: 6),
                                                  PocketTapScale(
                                                    onTap: () =>
                                                        _confirmDeleteRecipe(r),
                                                    child: Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color: c.statusError
                                                            .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 15,
                                                        color: c.statusError,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
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
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Text(
                                    'Menampilkan ${visibleShown.length} dari ${shown.length} resep',
                                    style: PocketTheme.mono(
                                      size: 11,
                                      color: c.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  PocketButton(
                                    label: 'Muat Lebih Banyak (+$_pageSize)',
                                    height: 42,
                                    fontSize: 12.5,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeFilterChip extends StatelessWidget {
  const _ModeFilterChip({
    required this.label,
    required this.active,
    required this.activeBg,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketPill(
      label: label,
      height: 30,
      fontSize: 11.5,
      fontWeight: 600,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      backgroundColor: active ? activeBg : c.surfaceCard,
      foregroundColor: active ? c.textOnAccent : c.textSecondary,
      borderColor: active ? Colors.transparent : c.borderSubtle,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: PocketCurves.fast,
                style: PocketTheme.ui(
                  size: 13,
                  weight: selected ? 600 : 500,
                  color: selected ? c.textPrimary : c.textSecondary,
                ),
                child: Text(label, maxLines: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
