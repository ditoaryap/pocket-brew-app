import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/pocket_motion.dart';
import '../core/widgets/pocket_logo.dart';
import '../data/repositories/pocket_store.dart';
import '../domain/models/enums.dart';
import 'pocket_version.dart';
import 'router.dart';
import 'theme/pocket_theme.dart';
import 'theme/pocket_tokens.dart';

class PocketBrewApp extends ConsumerWidget {
  const PocketBrewApp({super.key, this.router});

  final GoRouter? router;

  static final ThemeData _lightTheme = PocketTheme.build(PocketColors.softOat);
  static final ThemeData _darkTheme =
      PocketTheme.build(PocketColors.espressoDusk);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref =
        ref.watch(pocketStoreProvider.select((s) => s.prefs.themePref));
    final themeMode = switch (themePref) {
      AppThemePref.light => ThemeMode.light,
      AppThemePref.dark => ThemeMode.dark,
      AppThemePref.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Pocket Brew',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const PocketScrollBehavior(),
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      routerConfig: router ?? pocketRouter,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final framedChild = _PocketEntranceCurtain(child: child);
        // On real phones (Chrome/Safari mobile or DevTools mobile <= 520px), run 100% edge-to-edge full screen!
        // On wide desktop browsers, center inside a clean 412x880 Android phone preview bezel.
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktopPreview = kIsWeb && constraints.maxWidth > 540;
            if (!isDesktopPreview) return framedChild;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final frameH = (constraints.maxHeight - 32).clamp(700.0, 900.0);
            return AnimatedContainer(
              duration: PocketCurves.normal,
              color: isDark
                  ? const Color(0xFF0B0A09)
                  : const Color(0xFFE7DFD3),
              child: Center(
                child: Container(
                  width: 412,
                  height: frameH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A322C)
                          : const Color(0xFF241C16),
                      width: 6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(400, frameH - 12),
                      ),
                      child: framedChild,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Artisan Pour-Over Welcome Entrance:
/// Theme-aware (Soft Oat Light / Espresso Dusk Dark), calm 2.35s reveal with
/// animated pour-over ripples, sweeping crema arc, rising aroma wisps, and
/// staggered editorial typography before smoothly lifting into Beranda.
class _PocketEntranceCurtain extends StatefulWidget {
  const _PocketEntranceCurtain({required this.child});

  final Widget child;

  @override
  State<_PocketEntranceCurtain> createState() => _PocketEntranceCurtainState();
}

class _PocketEntranceCurtainState extends State<_PocketEntranceCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2350),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _completed = true);
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return widget.child;

    final c = context.colors;
    final isDark = c.isDark;

    final bgColors = isDark
        ? const [
            Color(0xFF281F1A),
            Color(0xFF171310),
            Color(0xFF100D0B),
          ]
        : const [
            Color(0xFFFFFCF7),
            Color(0xFFF6F1E9),
            Color(0xFFECE3D6),
          ];

    final emblemBg = isDark ? const Color(0xFF241D18) : const Color(0xFFFFFDF9);
    final emblemBorder =
        isDark ? const Color(0xFF3E322B) : const Color(0xFFE4D8C9);
    final ringTrack =
        isDark ? const Color(0xFF362B24) : const Color(0xFFE2D6C7);
    final accent = c.brandTerracotta;
    final accentInk = c.brandTerracottaInk;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;

        // Smooth lift & fade reveal phase (0.76 -> 1.0)
        final exitT =
            Curves.easeInOutCubic.transform(((t - 0.76) / 0.24).clamp(0.0, 1.0));
        final curtainOpacity = (1.0 - exitT).clamp(0.0, 1.0);
        final curtainSlideY = -28.0 * exitT;
        final curtainScale = 1.0 + (exitT * 0.03);

        // Staggered entrance curves
        final emblemIn =
            PocketCurves.gentleSpring.transform((t / 0.30).clamp(0.0, 1.0));
        final sweepProgress =
            Curves.easeOutCubic.transform(((t - 0.05) / 0.56).clamp(0.0, 1.0));
        final ripplePhase = Curves.easeOut.transform((t / 0.78).clamp(0.0, 1.0));
        final titleIn =
            Curves.easeOutCubic.transform(((t - 0.16) / 0.28).clamp(0.0, 1.0));
        final ruleIn =
            Curves.easeOutCubic.transform(((t - 0.26) / 0.26).clamp(0.0, 1.0));
        final subtitleIn =
            Curves.easeOutCubic.transform(((t - 0.30) / 0.28).clamp(0.0, 1.0));
        final badgeIn =
            Curves.easeOutCubic.transform(((t - 0.40) / 0.26).clamp(0.0, 1.0));
        final barProgress =
            Curves.easeInOutCubic.transform((t / 0.76).clamp(0.0, 1.0));

        // Underlying app gentle settle-in as curtain lifts
        final appScale = 0.988 + (0.012 * exitT);

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: appScale,
              child: child,
            ),
            if (curtainOpacity > 0.005)
              ExcludeSemantics(
                excluding: true,
                child: IgnorePointer(
                  ignoring: true,
                  child: Opacity(
                    opacity: curtainOpacity,
                    child: Transform.translate(
                      offset: Offset(0, curtainSlideY),
                      child: Transform.scale(
                        scale: curtainScale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0.0, -0.22),
                              radius: 1.15,
                              colors: bgColors,
                              stops: const [0.0, 0.56, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final isCompactH = box.maxHeight < 640;
                                final ringSize = isCompactH ? 142.0 : 164.0;
                                final markSize = isCompactH ? 66.0 : 76.0;
                                final pedestalSize = isCompactH ? 92.0 : 104.0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                  ),
                                  child: Column(
                                    children: [
                                      const Spacer(flex: 5),

                                      // Sculpted Emblem + Rippling Pour-Over Rings
                                      Transform.scale(
                                        scale: 0.78 + (0.22 * emblemIn),
                                        child: Opacity(
                                          opacity: emblemIn.clamp(0.0, 1.0),
                                          child: SizedBox(
                                            width: ringSize,
                                            height: ringSize,
                                            child: CustomPaint(
                                              painter: _ArtisanPourSplashPainter(
                                                sweep: sweepProgress,
                                                ripple: ripplePhase,
                                                accentColor: accent,
                                                sageColor: c.brandSage,
                                                trackColor: ringTrack,
                                                isDark: isDark,
                                              ),
                                              child: Center(
                                                child: Container(
                                                  width: pedestalSize,
                                                  height: pedestalSize,
                                                  decoration: BoxDecoration(
                                                    color: emblemBg,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: emblemBorder,
                                                      width: 1.2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: accent.withValues(
                                                          alpha:
                                                              isDark ? 0.18 : 0.14,
                                                        ),
                                                        blurRadius: 28,
                                                        spreadRadius: 2,
                                                        offset:
                                                            const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: PocketBrewMark(
                                                    size: markSize,
                                                    backgroundColor:
                                                        const Color(0xFFC05E3A),
                                                    foregroundColor:
                                                        const Color(0xFFFFFDF9),
                                                    dropColor:
                                                        const Color(0xFFF6E3DA),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isCompactH ? 20 : 28),

                                      // Wordmark
                                      Opacity(
                                        opacity: titleIn,
                                        child: Transform.translate(
                                          offset:
                                              Offset(0, (1.0 - titleIn) * 14),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  'pocket brew',
                                                  style: PocketTheme.ui(
                                                    size: 31,
                                                    weight: 800,
                                                    letterSpacing: -0.75,
                                                    color: c.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  '.',
                                                  style: PocketTheme.ui(
                                                    size: 33,
                                                    weight: 800,
                                                    color: accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Expanding Warm Hairline Accent Rule
                                      Container(
                                        width: 44 * ruleIn,
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Calm Editorial Tagline
                                      Opacity(
                                        opacity: subtitleIn,
                                        child: Transform.translate(
                                          offset: Offset(
                                            0,
                                            (1.0 - subtitleIn) * 10,
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Seduh manual presisi,\ntenang setiap pagi.',
                                                textAlign: TextAlign.center,
                                                style: PocketTheme.ui(
                                                  size: 14.5,
                                                  weight: 600,
                                                  height: 1.4,
                                                  color: c.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Opacity(
                                                opacity: badgeIn,
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 6,
                                                  alignment:
                                                      WrapAlignment.center,
                                                  children: [
                                                    _SplashTag(
                                                      label: 'Hot V60',
                                                      dotColor: accent,
                                                      bg: c.tintTerracotta,
                                                      fg: accentInk,
                                                    ),
                                                    _SplashTag(
                                                      label: 'Japanese Iced',
                                                      dotColor: c.brandIce,
                                                      bg: c.tintIce,
                                                      fg: c.brandIce,
                                                    ),
                                                    _SplashTag(
                                                      label: '100% Offline',
                                                      dotColor: c.brandSage,
                                                      bg: c.tintSage,
                                                      fg: c.brandSage,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const Spacer(flex: 6),

                                      // Minimal Progress Ribbon + Version Stamp
                                      Opacity(
                                        opacity: badgeIn,
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: 112,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                child: LinearProgressIndicator(
                                                  value: barProgress,
                                                  minHeight: 3,
                                                  backgroundColor: ringTrack,
                                                  color: accent,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'POCKET BREW ${PocketVersion.fullLabel.toUpperCase()}',
                                                style: PocketTheme.mono(
                                                  size: 9.8,
                                                  weight: FontWeight.w700,
                                                  letterSpacing: 1.6,
                                                  color: c.textTertiary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _SplashTag extends StatelessWidget {
  const _SplashTag({
    required this.label,
    required this.dotColor,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color dotColor;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: PocketTheme.ui(
              size: 11,
              weight: 700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtisanPourSplashPainter extends CustomPainter {
  const _ArtisanPourSplashPainter({
    required this.sweep,
    required this.ripple,
    required this.accentColor,
    required this.sageColor,
    required this.trackColor,
    required this.isDark,
  });

  final double sweep;
  final double ripple;
  final Color accentColor;
  final Color sageColor;
  final Color trackColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 4;
    final primaryR = maxR - 12;

    // 1. Expanding outer pour-over bloom ripple
    final rippleR = primaryR + (14.0 * ripple);
    final rippleAlpha = ((1.0 - ripple) * (isDark ? 0.34 : 0.28)).clamp(0.0, 1.0);
    if (rippleAlpha > 0.01) {
      canvas.drawCircle(
        center,
        rippleR,
        Paint()
          ..color = accentColor.withValues(alpha: rippleAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // 2. Subtle precision dial track
    canvas.drawCircle(
      center,
      primaryR,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 3. 12 Minimalist Compass / Burr Dots on outer ring
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 12);
      final isCard = i % 3 == 0;
      final isLit = (i / 12.0) <= sweep;
      final pos = Offset(
        center.dx + (maxR - 2) * math.cos(angle),
        center.dy + (maxR - 2) * math.sin(angle),
      );
      canvas.drawCircle(
        pos,
        isCard ? 2.1 : 1.25,
        Paint()
          ..color = isLit
              ? (isCard ? accentColor : accentColor.withValues(alpha: 0.65))
              : trackColor,
      );
    }

    // 4. Sweeping Pour-Over Crema Arc + Glowing Leading Drop
    if (sweep > 0.01) {
      final sweepAngle = 2 * math.pi * sweep;
      final rect = Rect.fromCircle(center: center, radius: primaryR);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );

      // Leading glowing tip dot
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tip = Offset(
        center.dx + primaryR * math.cos(tipAngle),
        center.dy + primaryR * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tip,
        5.5,
        Paint()..color = accentColor.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        tip,
        2.7,
        Paint()..color = sageColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArtisanPourSplashPainter oldDelegate) =>
      oldDelegate.sweep != sweep ||
      oldDelegate.ripple != ripple ||
      oldDelegate.isDark != isDark;
}
