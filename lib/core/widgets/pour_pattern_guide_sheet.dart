import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../domain/models/enums.dart';
import '../motion/pocket_motion.dart';
import 'canvas/spiral_pour_diagram.dart';
import 'pocket_card.dart';

/// Interactive animated pour-technique guide popup modal.
/// Accessible from ANY pour-pattern selector (Pour Stage Editor, Brew session stage sheet, Timer)
/// with 60fps looping animated motion demo + detailed, beginner-friendly instructions.
Future<void> showPourPatternGuideSheet(
  BuildContext context, {
  PourPattern initialPattern = PourPattern.spiral,
}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PourPatternGuideSheet(
      initialType: PourDemoType.fromPattern(initialPattern),
    ),
  );
}

/// Uniform, tactile, never-squished "Info Pola" pill button used beside every
/// pour-pattern selector (Edit Tahapan, Brew sesi ini, Timer Seduh).
class PourInfoButton extends StatelessWidget {
  const PourInfoButton({
    super.key,
    required this.pattern,
    this.label = 'Info Pola',
  });

  final PourPattern pattern;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketTapScale(
      pressedScale: 0.94,
      onTap: () => showPourPatternGuideSheet(
        context,
        initialPattern: pattern,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 11, 5),
        decoration: BoxDecoration(
          color: c.tintTerracotta,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: c.brandTerracotta.withValues(alpha: c.isDark ? 0.42 : 0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: c.brandTerracotta,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 13,
                color: c.textOnAccent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: PocketTheme.ui(
                size: 11.5,
                weight: 800,
                height: 1.15,
                color: c.brandTerracottaInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PourPatternGuideSheet extends StatefulWidget {
  const _PourPatternGuideSheet({required this.initialType});

  final PourDemoType initialType;

  @override
  State<_PourPatternGuideSheet> createState() => _PourPatternGuideSheetState();
}

class _PourPatternGuideSheetState extends State<_PourPatternGuideSheet> {
  late PourDemoType _selected;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.borderSubtle),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panduan Teknik Tuangan',
                        style: PocketTheme.ui(
                          size: 17,
                          weight: 800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Simulasi gerak tampak atas dripper & efek ke rasa kopi',
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
                PocketTapScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5 Pattern Switcher Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PourDemoType.values.map((t) {
                  final active = t == _selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PocketPill(
                      label: t.shortLabel,
                      height: 32,
                      fontSize: 12,
                      fontWeight: 700,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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

            // Scrollable Visual Animation Stage + Detailed Readable Breakdown
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Motion Stage (Video-like Dark Studio Preview)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1512),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF332923),
                        ),
                      ),
                      child: Column(
                        children: [
                          SpiralPourDiagram(
                            type: _selected,
                            isPlaying: _playing,
                            size: 152,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selected.title,
                            textAlign: TextAlign.center,
                            style: PocketTheme.ui(
                              size: 15,
                              weight: 800,
                              color: const Color(0xFFFAF5EE),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                              size: 12.2,
                              weight: 500,
                              height: 1.45,
                              color: const Color(0xFFD0C5B9),
                            ),
                          ),
                          const SizedBox(height: 11),
                          PocketPill(
                            label: _playing ? 'Jeda Simulasi' : 'Putar Simulasi',
                            icon: _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            height: 32,
                            fontSize: 11.5,
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

                    // Step-by-step How-To Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cara Melakukan Teknik Ini',
                            style: PocketTheme.ui(
                              size: 13,
                              weight: 800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(_selected.howToSteps.length, (i) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: i < _selected.howToSteps.length - 1
                                    ? 7
                                    : 0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(top: 1),
                                    decoration: BoxDecoration(
                                      color: c.tintTerracotta,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${i + 1}',
                                      style: PocketTheme.mono(
                                        size: 10.5,
                                        weight: FontWeight.w800,
                                        color: c.brandTerracottaInk,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      _selected.howToSteps[i],
                                      style: PocketTheme.ui(
                                        size: 12.4,
                                        weight: 500,
                                        height: 1.42,
                                        color: c.textPrimary,
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
                    const SizedBox(height: 10),

                    // Taste Effect & Best For
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: c.tintSage,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Efek ke Rasa di Cangkir',
                            style: PocketTheme.ui(
                              size: 12.2,
                              weight: 800,
                              color: c.brandSage,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selected.tasteEffect,
                            style: PocketTheme.ui(
                              size: 12.4,
                              weight: 600,
                              height: 1.4,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Paling Cocok Dipakai Saat',
                            style: PocketTheme.ui(
                              size: 11.5,
                              weight: 800,
                              color: c.brandSage,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selected.bestFor,
                            style: PocketTheme.ui(
                              size: 12.2,
                              weight: 500,
                              height: 1.4,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Watch Out Tip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: c.tintHoney,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perhatian Penting',
                            style: PocketTheme.ui(
                              size: 12,
                              weight: 800,
                              color: c.brandHoney,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selected.watchOut,
                            style: PocketTheme.ui(
                              size: 12.2,
                              weight: 500,
                              height: 1.42,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            PocketButton(
              label: 'Paham · Tutup Panduan',
              height: 46,
              backgroundColor: c.brandEspresso,
              foregroundColor: c.textOnAccent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
