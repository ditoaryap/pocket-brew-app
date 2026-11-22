import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/widgets/canvas/spiral_pour_diagram.dart';
import '../../core/widgets/pocket_card.dart';

/// Screen 20 · Detail Teknik Penuangan (Interactive 60fps Animated Stage for all 5 Pour Patterns).
class LearnPourDetailScreen extends StatefulWidget {
  const LearnPourDetailScreen({super.key});

  @override
  State<LearnPourDetailScreen> createState() => _LearnPourDetailScreenState();
}

class _LearnPourDetailScreenState extends State<LearnPourDetailScreen> {
  PourDemoType _selected = PourDemoType.spiral;
  bool _playing = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Teknik Penuangan',
              onBack: () => context.pop(),
              trailing: PocketPill(
                label: '5 Pola · Animasi',
                icon: Icons.play_circle_outline_rounded,
                backgroundColor: c.tintTerracotta,
                foregroundColor: c.brandTerracottaInk,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                children: [
                  // Interactive 5-Technique Selector Strip
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PourDemoType.values.map((t) {
                        final active = _selected == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: PocketPill(
                            label: t.shortLabel,
                            height: 34,
                            fontSize: 12.2,
                            fontWeight: 700,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            backgroundColor:
                                active ? c.brandEspresso : c.surfaceElevated,
                            foregroundColor:
                                active ? c.textOnAccent : c.textSecondary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selected = t;
                                _playing = true;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Studio Animated Stage Card (Responsive centered layout!)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1512),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF332923)),
                    ),
                    child: Column(
                      children: [
                        SpiralPourDiagram(
                          type: _selected,
                          isPlaying: _playing,
                          size: 164,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selected.title,
                          textAlign: TextAlign.center,
                          style: PocketTheme.ui(
                            size: 16,
                            weight: 800,
                            color: const Color(0xFFFAF5EE),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B221D),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _selected.paceBadge,
                            style: PocketTheme.mono(
                              size: 11,
                              weight: FontWeight.w700,
                              color: const Color(0xFFE48F6E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selected.caption,
                          textAlign: TextAlign.center,
                          style: PocketTheme.ui(
                            size: 12.5,
                            height: 1.48,
                            color: const Color(0xFFD0C5B9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PocketPill(
                          label: _playing ? 'Jeda Animasi' : 'Putar Animasi',
                          icon: _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          height: 34,
                          backgroundColor: const Color(0xFFC05E3A),
                          foregroundColor: const Color(0xFFFFFDF9),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _playing = !_playing);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detailed Breakdown for Selected Technique
                  PocketCard(
                    padding: const EdgeInsets.all(15),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langkah Praktik · ${_selected.shortLabel}',
                          style: PocketTheme.ui(
                            size: 14,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(_selected.howToSteps.length, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  i < _selected.howToSteps.length - 1 ? 8 : 0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    color: c.tintTerracotta,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: PocketTheme.mono(
                                      size: 11,
                                      weight: FontWeight.w800,
                                      color: c.brandTerracottaInk,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selected.howToSteps[i],
                                    style: PocketTheme.ui(
                                      size: 13,
                                      weight: 500,
                                      height: 1.45,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 11),
                          child: Divider(),
                        ),
                        Text(
                          'Efek Rasa: ${_selected.tasteEffect}',
                          style: PocketTheme.ui(
                            size: 12.8,
                            weight: 700,
                            height: 1.4,
                            color: c.brandSage,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cocok untuk: ${_selected.bestFor}',
                          style: PocketTheme.ui(
                            size: 12.4,
                            weight: 500,
                            height: 1.4,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  PocketCard(
                    backgroundColor: c.tintHoney,
                    borderColor: Colors.transparent,
                    elevated: false,
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Tip Penting: ${_selected.watchOut}',
                      style: PocketTheme.ui(
                        size: 12.6,
                        height: 1.45,
                        weight: 600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick overview cards for all 5 techniques (tap to jump animation)
                  const PocketSectionHeader(title: 'Ringkasan 5 Pola Tuangan'),
                  const SizedBox(height: 8),
                  ...PourDemoType.values.map((t) {
                    final sel = t == _selected;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: PocketCard(
                        borderColor: sel ? c.brandTerracotta : c.borderSubtle,
                        borderWidth: sel ? 1.5 : 1.0,
                        elevated: false,
                        padding: const EdgeInsets.all(13),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selected = t;
                            _playing = true;
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    t.title,
                                    style: PocketTheme.ui(
                                      size: 13.5,
                                      weight: 800,
                                      color: sel
                                          ? c.brandTerracottaInk
                                          : c.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PocketPill(
                                  label: t.shortLabel,
                                  height: 22,
                                  fontSize: 10.5,
                                  backgroundColor: sel
                                      ? c.tintTerracotta
                                      : c.surfaceElevated,
                                  foregroundColor: sel
                                      ? c.brandTerracottaInk
                                      : c.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.tasteEffect,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: 'Praktikkan di Brew',
                icon: Icons.local_cafe_rounded,
                backgroundColor: c.brandTerracotta,
                foregroundColor: c.textOnAccent,
                height: 50,
                onTap: () => context.go('/brew'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
