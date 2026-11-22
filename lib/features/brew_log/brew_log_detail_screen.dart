import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/widgets/pocket_card.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';

/// Screen 23 · Detail Riwayat Seduh (KPIs, 4 Flavor Bars, Notes, Pour Stages Snapshot, Golden Toggle, Re-brew).
class BrewLogDetailScreen extends ConsumerWidget {
  const BrewLogDetailScreen({super.key, required this.logId});

  final String logId;

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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Detail Seduhan',
              onBack: () => context.canPop() ? context.pop() : context.go('/log'),
              trailing: IconButton(
                onPressed: () {
                  notifier.deleteLog(log.id);
                  context.go('/log');
                },
                icon: Icon(Icons.delete_outline_rounded, color: c.statusError),
                tooltip: 'Hapus Log',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                children: [
                  // Header + 4 KPIs
                  PocketCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                log.beanName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            PocketPill(
                              label: '★ ${log.rating.toStringAsFixed(1)}',
                              backgroundColor: log.rating >= 4.5
                                  ? c.tintHoney
                                  : c.surfaceElevated,
                              foregroundColor: log.rating >= 4.5
                                  ? c.brandHoney
                                  : c.textPrimary,
                              isMono: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${log.mode.label}${log.mode == BrewMode.iced ? ' (${log.icedMethod.shortLabel})' : ''} · ${log.recipeName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _DetailKpi('Gilingan', '${log.clickSetting} klik'),
                              _DetailKpi(
                                'Suhu',
                                BrewRecipeScaler.formatTemp(
                                  log.tempC,
                                  state.prefs.tempUnit,
                                ),
                              ),
                              _DetailKpi(
                                'Dosis/Air',
                                '${log.doseG.round()}g/${BrewRecipeScaler.formatLiquid(log.totalLiquidG, unit)}',
                              ),
                              _DetailKpi(
                                'Drawdown',
                                BrewRecipeScaler.formatDuration(
                                  log.actualDrawdownSec,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4 Flavor Bars + Tasting Chips + Memo
                  PocketCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profil Rasa & Catatan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StaticFlavorBar(
                                label: 'Asam',
                                value: log.flavorBars.acidity,
                                color: c.brandTerracotta,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StaticFlavorBar(
                                label: 'Manis',
                                value: log.flavorBars.sweetness,
                                color: c.brandSage,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _StaticFlavorBar(
                                label: 'Pahit',
                                value: log.flavorBars.bitterness,
                                color: c.brandHoney,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StaticFlavorBar(
                                label: 'Body',
                                value: log.flavorBars.body,
                                color: c.brandIce,
                              ),
                            ),
                          ],
                        ),
                        if (log.tastingTags.isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 10),
                          Text(
                            '"${log.notes}"',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pour Stages Snapshot
                  if (log.stageSnapshots.isNotEmpty)
                    PocketCard(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tahapan Tuangan yang Dipakai (${log.stageSnapshots.length} Tahap)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...log.stageSnapshots.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                line,
                                style: PocketTheme.mono(
                                  size: 11.5,
                                  color: c.textSecondary,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom CTA: Brew Ulang Resep Ini
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: 'Brew Ulang Resep Ini',
                height: 52,
                backgroundColor: c.brandTerracotta,
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

class _DetailKpi extends StatelessWidget {
  const _DetailKpi(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: c.textTertiary),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PocketTheme.mono(
              size: 12,
              weight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticFlavorBar extends StatelessWidget {
  const _StaticFlavorBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              '${value.toStringAsFixed(1)}/5',
              style: PocketTheme.mono(
                size: 11,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (value / 5.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: c.surfaceElevated,
            color: color,
          ),
        ),
      ],
    );
  }
}
