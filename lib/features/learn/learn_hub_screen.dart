import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';

/// Screen 19 · Belajar Seduh — Complete Pour-Over Education Hub (7 Structured Topics).
class LearnHubScreen extends ConsumerWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final guides = ref.watch(pocketStoreProvider).guides;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Belajar Seduh',
              onBack: () => context.pop(),
              trailing: PocketPill(
                label: '${guides.length} Materi',
                backgroundColor: c.tintSage,
                foregroundColor: c.brandSage,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                children: [
                  Text(
                    'Panduan ringkas & praktis untuk pemula hingga rumahan — dari dasar rasio, teknik tuang, perbaikan rasa, hingga air & alat seduh.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(guides.length, (i) {
                    final g = guides[i];
                    final (
                      PocketIconType icon,
                      Color cardBg,
                      Color iconBg,
                      Color iconFg,
                      Color titleColor,
                      String route,
                    ) = switch (g.category) {
                      'basics' => (
                          PocketIconType.flame,
                          c.tintHoney,
                          c.brandHoney,
                          c.textOnAccent,
                          c.brandHoney,
                          '/learn/basics',
                        ),
                      'pour' => (
                          PocketIconType.play,
                          c.tintTerracotta,
                          c.brandTerracotta,
                          c.textOnAccent,
                          c.brandTerracottaInk,
                          '/learn/pour',
                        ),
                      'troubleshoot' => (
                          PocketIconType.compass,
                          c.tintSage,
                          c.brandSage,
                          c.textOnAccent,
                          c.brandSage,
                          '/learn/troubleshoot',
                        ),
                      'beans' => (
                          PocketIconType.bean,
                          c.surfaceCard,
                          c.tintBerry,
                          c.brandBerry,
                          c.textPrimary,
                          '/learn/beans',
                        ),
                      'water' => (
                          PocketIconType.snowflake,
                          c.tintIce,
                          c.brandIce,
                          c.textOnAccent,
                          c.brandIce,
                          '/learn/water',
                        ),
                      'dripper' => (
                          PocketIconType.v60,
                          c.surfaceCard,
                          c.tintTerracotta,
                          c.brandTerracottaInk,
                          c.textPrimary,
                          '/learn/dripper',
                        ),
                      _ => (
                          PocketIconType.filterPaper,
                          c.surfaceCard,
                          c.tintSage,
                          c.brandSage,
                          c.textPrimary,
                          '/learn/filter',
                        ),
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: PocketEntrance(
                        delayMs: (i * 25).clamp(0, 160),
                        offsetY: 8,
                        child: PocketCard(
                          backgroundColor: cardBg,
                          elevated: cardBg == c.surfaceCard,
                          padding: const EdgeInsets.all(15),
                          radius: 20,
                          onTap: () => context.push(route),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: PocketIcon(
                                      icon,
                                      color: iconFg,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.title,
                                          style: PocketTheme.ui(
                                            size: 14,
                                            weight: 800,
                                            height: 1.25,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${g.subtitle} · ${g.readMinutes} mnt',
                                          style: PocketTheme.ui(
                                            size: 11.2,
                                            weight: 500,
                                            height: 1.35,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  PocketIcon(
                                    PocketIconType.chevronRight,
                                    size: 17,
                                    color: c.textTertiary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: g.tags
                                    .map(
                                      (t) => PocketPill(
                                        label: t,
                                        backgroundColor: cardBg == c.surfaceCard
                                            ? c.surfaceElevated
                                            : c.surfaceCard
                                                .withValues(alpha: 0.78),
                                        foregroundColor: c.textSecondary,
                                        fontSize: 10.5,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
