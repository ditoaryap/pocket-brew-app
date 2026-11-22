import 'package:flutter/material.dart';
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
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';

/// Screen 23 · Detail Seduhan (Mode-Differentiated Hot V60 vs Japanese Iced Redesign):
/// - Clear visual distinction between Hot V60 (Terracotta) and Japanese Iced (Glacier Ice).
/// - Dedicated Japanese Iced Composition Card with AnimatedWaterIceSplitBar showing
///   exact Hot Water vs Ice Cube grams/ml, ratio %, total yield, and ice technique.
/// - Spacious 2x2 brew parameter grid, animated sensory gauges, notes, and clean timeline.
class BrewLogDetailScreen extends ConsumerWidget {
  const BrewLogDetailScreen({super.key, required this.logId});

  final String logId;

  String _formatDateFull(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);
    final log = state.logs.where((l) => l.id == logId).firstOrNull;

    if (log == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PocketTopBar(
                title: 'Detail Seduhan',
                onBack: () => context.pop(),
              ),
              const Expanded(
                child: Center(child: Text('Riwayat seduhan tidak ditemukan.')),
              ),
            ],
          ),
        ),
      );
    }

    final unit = state.prefs.unitMode;
    final isIced = log.mode == BrewMode.iced;
    final modeAccent = isIced ? c.brandIce : c.brandTerracotta;
    final modeInk = isIced ? c.brandIce : c.brandTerracottaInk;
    final modeTint = isIced ? c.tintIce : c.tintTerracotta;

    final effectiveTotal = log.totalLiquidG > 0
        ? log.totalLiquidG
        : (log.hotWaterG + log.iceG).clamp(1.0, 5000.0);
    final ratioVal = log.doseG > 0 ? (effectiveTotal / log.doseG) : 16.0;
    final ratioLabel =
        '1:${ratioVal.toStringAsFixed(ratioVal % 1 < 0.05 ? 0 : 1)}';
    final hotFraction =
        isIced ? (log.hotWaterG / effectiveTotal).clamp(0.25, 0.88) : 1.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Detail Seduhan',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/log'),
              trailing: IconButton(
                onPressed: () async {
                  final ok = await showPocketDeleteDialog(
                    context,
                    title: 'Hapus Catatan Seduhan?',
                    message:
                        'Hapus riwayat seduhan "${log.beanName}" ini secara permanen? Tindakan ini tidak bisa dibatalkan.',
                    confirmLabel: 'Hapus',
                  );
                  if (!ok) return;
                  notifier.deleteLog(log.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Catatan seduhan berhasil dihapus.'),
                      ),
                    );
                    context.go('/log');
                  }
                },
                icon: Icon(Icons.delete_outline_rounded, color: c.statusError),
                tooltip: 'Hapus Log',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                children: [
                  // 1. MODE-THEMED HERO SUMMARY CARD
                  PocketEntrance(
                    delayMs: 0,
                    child: PocketCard(
                      padding: const EdgeInsets.all(16),
                      radius: 22,
                      borderColor: modeAccent.withValues(
                        alpha: c.isDark ? 0.36 : 0.25,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: modeTint,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PocketIcon(
                                      isIced
                                          ? PocketIconType.snowflake
                                          : PocketIconType.flame,
                                      size: 13,
                                      color: modeInk,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isIced ? 'Japanese Iced' : 'Hot V60',
                                      style: PocketTheme.ui(
                                        size: 11.5,
                                        weight: 800,
                                        color: modeInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              PocketPill(
                                label: '★ ${log.rating.toStringAsFixed(1)}',
                                backgroundColor: log.rating >= 4.5
                                    ? c.tintHoney
                                    : c.surfaceElevated,
                                foregroundColor: log.rating >= 4.5
                                    ? c.brandHoney
                                    : c.textPrimary,
                                isMono: true,
                                fontSize: 12.5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          Text(
                            log.beanName,
                            style: PocketTheme.ui(
                              size: 20,
                              weight: 800,
                              height: 1.2,
                              letterSpacing: -0.3,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${log.recipeName} · ${log.grinderName}',
                            style: PocketTheme.ui(
                              size: 12.6,
                              weight: 600,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateFull(log.brewedAt),
                            style: PocketTheme.mono(
                              size: 11,
                              color: c.textTertiary,
                            ),
                          ),

                          // JAPANESE ICED DEDICATED WATER + ICE BREAKDOWN
                          if (isIced) ...[
                            const SizedBox(height: 14),
                            AnimatedWaterIceSplitBar(
                              hotWaterLabel:
                                  BrewRecipeScaler.formatLiquid(
                                log.hotWaterG,
                                unit,
                              ),
                              iceLabel: '${log.iceG.round()}g',
                              hotFraction: hotFraction,
                              methodBadge: log.icedMethod.shortLabel,
                              totalLabel: BrewRecipeScaler.formatLiquid(
                                log.totalLiquidG,
                                unit,
                              ),
                            ),
                          ],

                          const SizedBox(height: 13),

                          // 2x2 SPACIOUS BREW PARAMETER GRID
                          Row(
                            children: [
                              _ParamTile(
                                label: isIced ? 'Dosis & Rasio' : 'Dosis → Air',
                                value: isIced
                                    ? '${BrewRecipeScaler.formatDose(log.doseG)} · $ratioLabel'
                                    : '${BrewRecipeScaler.formatDose(log.doseG)} → ${BrewRecipeScaler.formatLiquidCompact(log.totalLiquidG, unit)}',
                                sub: isIced
                                    ? 'Total ${BrewRecipeScaler.formatLiquid(log.totalLiquidG, unit)}'
                                    : 'Rasio $ratioLabel',
                              ),
                              const SizedBox(width: 8),
                              _ParamTile(
                                label: 'Gilingan',
                                value: '${log.clickSetting} klik',
                                sub: log.grinderName,
                                accent: modeInk,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ParamTile(
                                label: 'Suhu Air',
                                value: BrewRecipeScaler.formatTemp(
                                  log.tempC,
                                  state.prefs.tempUnit,
                                ),
                                sub: isIced
                                    ? 'Air seduh panas'
                                    : 'Suhu tuangan',
                              ),
                              const SizedBox(width: 8),
                              _ParamTile(
                                label: 'Waktu Turun',
                                value: BrewRecipeScaler.formatDuration(
                                  log.actualDrawdownSec,
                                ),
                                sub:
                                    'Target ~${BrewRecipeScaler.formatShortDuration(log.targetDrawdownSec)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. ANIMATED FLAVOR PROFILE & TASTING NOTES CARD
                  PocketEntrance(
                    delayMs: 55,
                    child: PocketCard(
                      padding: const EdgeInsets.all(16),
                      radius: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Profil Rasa & Catatan',
                                  style: PocketTheme.ui(
                                    size: 14.5,
                                    weight: 800,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PocketPill(
                                label: log.tasteFeeling.title,
                                fontSize: 10.8,
                                backgroundColor: c.tintSage,
                                foregroundColor: c.brandSage,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedFlavorGauge(
                                  label: 'Asam',
                                  value: log.flavorBars.acidity,
                                  color: c.brandTerracotta,
                                  delayMs: 0,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: AnimatedFlavorGauge(
                                  label: 'Manis',
                                  value: log.flavorBars.sweetness,
                                  color: c.brandSage,
                                  delayMs: 80,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedFlavorGauge(
                                  label: 'Pahit',
                                  value: log.flavorBars.bitterness,
                                  color: c.brandHoney,
                                  delayMs: 160,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: AnimatedFlavorGauge(
                                  label: 'Body',
                                  value: log.flavorBars.body,
                                  color: c.brandIce,
                                  delayMs: 240,
                                ),
                              ),
                            ],
                          ),
                          if (log.tastingTags.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Notes Rasa Terdeteksi',
                              style: PocketTheme.ui(
                                size: 11.2,
                                weight: 700,
                                color: c.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: log.tastingTags.map((t) {
                                return PocketPill(
                                  label: t,
                                  backgroundColor: c.tintBerry,
                                  foregroundColor: c.brandBerry,
                                );
                              }).toList(),
                            ),
                          ],
                          if (log.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: c.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '"${log.notes}"',
                                style: PocketTheme.ui(
                                  size: 13,
                                  weight: 500,
                                  height: 1.45,
                                  color: c.textPrimary,
                                ).copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. CLEAN NUMBERED POUR STAGES SNAPSHOT
                  if (log.stageSnapshots.isNotEmpty)
                    PocketEntrance(
                      delayMs: 110,
                      child: PocketCard(
                        padding: const EdgeInsets.all(16),
                        radius: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tahapan Tuangan (${log.stageSnapshots.length} Tahap)',
                              style: PocketTheme.ui(
                                size: 14.5,
                                weight: 800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(log.stageSnapshots.length, (i) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: i < log.stageSnapshots.length - 1
                                      ? 8
                                      : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: modeTint,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${i + 1}',
                                        style: PocketTheme.mono(
                                          size: 10.5,
                                          weight: FontWeight.w800,
                                          color: modeInk,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        log.stageSnapshots[i],
                                        style: PocketTheme.mono(
                                          size: 12,
                                          color: c.textSecondary,
                                          weight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Mode-Themed Bottom CTA: Brew Ulang Resep Ini
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: 'Brew Ulang Resep Ini',
                pocketIcon:
                    isIced ? PocketIconType.snowflake : PocketIconType.flame,
                height: 52,
                backgroundColor: modeAccent,
                foregroundColor: c.textOnAccent,
                onTap: () {
                  notifier.rebrewFromLog(log);
                  context.go('/brew');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParamTile extends StatelessWidget {
  const _ParamTile({
    required this.label,
    required this.value,
    required this.sub,
    this.accent,
  });

  final String label;
  final String value;
  final String sub;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: PocketTheme.ui(
                size: 10.8,
                weight: 700,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: PocketTheme.mono(
                  size: 14.5,
                  weight: FontWeight.w800,
                  color: accent ?? c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PocketTheme.ui(
                size: 11,
                weight: 500,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
