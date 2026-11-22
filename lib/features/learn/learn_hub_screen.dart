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

/// Screen 19 · Belajar Seduh (Pro-Standard Pour-Over Academy — 9 Structured Topics):
/// Organized by learning tracks with clear SCA / World Brewers Cup / modern extraction
/// references, interactive visual labs, and readable mobile cards.
class LearnHubScreen extends ConsumerStatefulWidget {
  const LearnHubScreen({super.key});

  @override
  ConsumerState<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends ConsumerState<LearnHubScreen> {
  String _track = 'all'; // all | foundation | craft | gear

  bool _matchesTrack(String category) {
    if (_track == 'all') return true;
    if (_track == 'foundation') {
      return category == 'beans' ||
          category == 'basics' ||
          category == 'water';
    }
    if (_track == 'craft') {
      return category == 'pour' ||
          category == 'wheel' ||
          category == 'troubleshoot' ||
          category == 'iced';
    }
    return category == 'dripper' ||
        category == 'filter' ||
        category == 'grinder';
  }

  String _trackBadge(String category) => switch (category) {
        'beans' || 'basics' || 'water' => 'Pondasi',
        'pour' || 'wheel' || 'troubleshoot' || 'iced' => 'Teknik & Rasa',
        _ => 'Peralatan',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final guides = ref.watch(pocketStoreProvider).guides;
    final shown = guides.where((g) => _matchesTrack(g.category)).toList();

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
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                children: [
                  // Intro Reference Card
                  PocketCard(
                    backgroundColor: c.tintSage,
                    borderColor: c.brandSage.withValues(alpha: 0.25),
                    elevated: false,
                    radius: 20,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.surfaceCard,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: PocketIcon(
                            PocketIconType.book,
                            size: 18,
                            color: c.brandSage,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kurikulum Pour-Over Rumahan',
                                style: PocketTheme.ui(
                                  size: 13.8,
                                  weight: 800,
                                  color: c.brandSage,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Disusun dari standar SCA, World Brewers Cup, dan riset ekstraksi modern — disajikan ringkas, visual, dan langsung bisa dipraktikkan.',
                                style: PocketTheme.ui(
                                  size: 12.2,
                                  weight: 500,
                                  height: 1.44,
                                  color: c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Track Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ('all', 'Semua (${guides.length})'),
                        ('foundation', 'Kopi & Pondasi'),
                        ('craft', 'Teknik & Rasa'),
                        ('gear', 'Alat & Grinder'),
                      ].map((t) {
                        final (id, label) = t;
                        final active = _track == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: PocketPill(
                            label: label,
                            height: 34,
                            fontSize: 12,
                            fontWeight: 700,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            backgroundColor:
                                active ? c.brandEspresso : c.surfaceCard,
                            foregroundColor:
                                active ? c.textOnAccent : c.textSecondary,
                            borderColor:
                                active ? Colors.transparent : c.borderSubtle,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _track = id);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 13),

                  ...List.generate(shown.length, (i) {
                    final g = shown[i];
                    final (
                      PocketIconType icon,
                      Color cardBg,
                      Color iconBg,
                      Color iconFg,
                      Color titleColor,
                      String route,
                    ) = switch (g.category) {
                      'beans' => (
                          PocketIconType.bean,
                          c.tintTerracotta,
                          c.brandTerracotta,
                          c.textOnAccent,
                          c.brandTerracottaInk,
                          '/learn/beans',
                        ),
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
                          c.surfaceCard,
                          c.tintTerracotta,
                          c.brandTerracottaInk,
                          c.textPrimary,
                          '/learn/pour',
                        ),
                      'wheel' => (
                          PocketIconType.starFilled,
                          c.tintBerry,
                          c.brandBerry,
                          c.textOnAccent,
                          c.brandBerry,
                          '/learn/wheel',
                        ),
                      'troubleshoot' => (
                          PocketIconType.compass,
                          c.tintSage,
                          c.brandSage,
                          c.textOnAccent,
                          c.brandSage,
                          '/learn/troubleshoot',
                        ),
                      'iced' => (
                          PocketIconType.snowflake,
                          c.tintIce,
                          c.brandIce,
                          c.textOnAccent,
                          c.brandIce,
                          '/learn/iced',
                        ),
                      'water' => (
                          PocketIconType.snowflake,
                          c.surfaceCard,
                          c.tintIce,
                          c.brandIce,
                          c.textPrimary,
                          '/learn/water',
                        ),
                      'dripper' || 'filter' => (
                          PocketIconType.v60,
                          c.surfaceCard,
                          c.tintSage,
                          c.brandSage,
                          c.textPrimary,
                          '/learn/dripper',
                        ),
                      _ => (
                          PocketIconType.burrGear,
                          c.surfaceCard,
                          c.tintHoney,
                          c.brandHoney,
                          c.textPrimary,
                          '/learn/grinder',
                        ),
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: PocketEntrance(
                        key: ValueKey('${_track}_${g.id}'),
                        delayMs: (i * 25).clamp(0, 150),
                        offsetY: 8,
                        child: PocketCard(
                          backgroundColor: cardBg,
                          borderColor: cardBg == c.surfaceCard
                              ? c.borderSubtle
                              : iconBg.withValues(alpha: 0.25),
                          elevated: cardBg == c.surfaceCard,
                          padding: const EdgeInsets.all(15),
                          radius: 21,
                          onTap: () => context.push(route),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    alignment: Alignment.center,
                                    child: PocketIcon(
                                      icon,
                                      color: iconFg,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: _trackBadge(g.category),
                                                style: PocketTheme.ui(
                                                  size: 10.5,
                                                  weight: 800,
                                                  color: cardBg == c.surfaceCard
                                                      ? iconFg
                                                      : titleColor,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    ' · ${g.readMinutes} mnt baca',
                                                style: PocketTheme.mono(
                                                  size: 10.5,
                                                  weight: FontWeight.w600,
                                                  color: c.textTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          g.title,
                                          style: PocketTheme.ui(
                                            size: 14.5,
                                            weight: 800,
                                            height: 1.25,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          g.subtitle,
                                          style: PocketTheme.ui(
                                            size: 11.8,
                                            weight: 500,
                                            height: 1.38,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: PocketIcon(
                                      PocketIconType.chevronRight,
                                      size: 17,
                                      color: c.textTertiary,
                                    ),
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
                                                .withValues(alpha: 0.84),
                                        foregroundColor: c.textSecondary,
                                        fontSize: 10.6,
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
