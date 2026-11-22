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

/// Editorial Barista Entrance Curtain:
/// Plays a signature precision burr-dial & crema-glow reveal on app launch,
/// then unmounts cleanly to zero overhead once completed.
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
      duration: const Duration(milliseconds: 1420),
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

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        // Reveal transition phase (0.64 -> 1.0)
        final exitT =
            Curves.easeInOutCubic.transform(((t - 0.64) / 0.36).clamp(0.0, 1.0));
        final curtainOpacity = (1.0 - exitT).clamp(0.0, 1.0);
        final curtainScale = 1.0 + (exitT * 0.045);
        final curtainSlideY = -22.0 * exitT;

        // Crest & dial entrance phase (0.0 -> 0.58)
        final crestIn =
            PocketCurves.gentleSpring.transform((t / 0.42).clamp(0.0, 1.0));
        final dialSweep =
            Curves.easeOutCubic.transform((t / 0.62).clamp(0.0, 1.0));
        final textIn =
            Curves.easeOutCubic.transform(((t - 0.12) / 0.38).clamp(0.0, 1.0));
        final pillIn =
            Curves.easeOutCubic.transform(((t - 0.22) / 0.38).clamp(0.0, 1.0));

        // Underlying app gentle scale-in as curtain lifts
        final appScale = 0.985 + (0.015 * exitT);

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
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0.0, -0.18),
                              radius: 1.05,
                              colors: [
                                Color(0xFF2B201A),
                                Color(0xFF17120F),
                                Color(0xFF100D0B),
                              ],
                              stops: [0.0, 0.58, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              children: [
                                const Spacer(flex: 5),
                                // Precision Burr-Dial Ring + Pocket Brew Crest
                                Transform.scale(
                                  scale: 0.72 + (0.28 * crestIn),
                                  child: SizedBox(
                                    width: 124,
                                    height: 124,
                                    child: CustomPaint(
                                      painter: _BaristaDialRingPainter(
                                        progress: dialSweep,
                                      ),
                                      child: const Center(
                                        child: PocketBrewMark(
                                          size: 72,
                                          backgroundColor: Color(0xFFC05E3A),
                                          foregroundColor: Color(0xFFFFFDF9),
                                          dropColor: Color(0xFFF6E3DA),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                // Editorial Wordmark & Atelier Tagline
                                Opacity(
                                  opacity: textIn,
                                  child: Transform.translate(
                                    offset: Offset(0, (1.0 - textIn) * 14),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Column(
                                        children: [
                                          FittedBox(
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
                                                    size: 28,
                                                    weight: 800,
                                                    letterSpacing: -0.6,
                                                    color: const Color(
                                                      0xFFFAF5EE,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '.',
                                                  style: PocketTheme.ui(
                                                    size: 30,
                                                    weight: 800,
                                                    color: const Color(
                                                      0xFFD9724C,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'MANUAL POUR-OVER COMPANION',
                                              style: PocketTheme.mono(
                                                size: 10.2,
                                                weight: FontWeight.w700,
                                                letterSpacing: 2.3,
                                                color:
                                                    const Color(0xFFD6A48C),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Specialty Capability Pill
                                Opacity(
                                  opacity: pillIn,
                                  child: Transform.translate(
                                    offset: Offset(0, (1.0 - pillIn) * 10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF261E19),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: const Color(0xFF43342B),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration:
                                                    const BoxDecoration(
                                                  color: Color(0xFF6A9A78),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Hot V60  ·  Japanese Iced  ·  Δμm Click',
                                                style: PocketTheme.ui(
                                                  size: 11.2,
                                                  weight: 600,
                                                  color: const Color(
                                                    0xFFD4C6B8,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(flex: 6),
                                Opacity(
                                  opacity: pillIn * 0.75,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      0,
                                      24,
                                      18,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Pocket Brew ${PocketVersion.fullLabel} · 100% Offline',
                                        style: PocketTheme.mono(
                                          size: 10,
                                          weight: FontWeight.w600,
                                          color: const Color(0xFF8C7B6E),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

class _BaristaDialRingPainter extends CustomPainter {
  const _BaristaDialRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 4;
    final arcR = outerR - 8;

    // 36 Precision Burr Click Ticks around outer perimeter
    const tickCount = 36;
    final activeTicks = (tickCount * progress).round();
    for (int i = 0; i < tickCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / tickCount);
      final isMajor = i % 3 == 0;
      final isLit = i <= activeTicks;
      final len = isMajor ? 5.5 : 3.2;
      final p1 = Offset(
        center.dx + (outerR - len) * math.cos(angle),
        center.dy + (outerR - len) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isLit
              ? (isMajor
                  ? const Color(0xFFE0855E)
                  : const Color(0xFFA06A50))
              : const Color(0xFF362B24)
          ..strokeWidth = isMajor ? 1.7 : 1.1
          ..strokeCap = StrokeCap.round,
      );
    }

    // Subtle track circle
    canvas.drawCircle(
      center,
      arcR,
      Paint()
        ..color = const Color(0xFF2D231D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Sweeping Crema Arc
    if (progress > 0.01) {
      final rect = Rect.fromCircle(center: center, radius: arcR);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = const Color(0xFFD9724C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BaristaDialRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
