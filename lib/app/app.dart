import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/pocket_motion.dart';
import '../core/widgets/pocket_logo.dart';
import '../data/repositories/pocket_store.dart';
import '../domain/models/enums.dart';
import 'router.dart';
import 'theme/pocket_theme.dart';
import 'theme/pocket_tokens.dart';

class PocketBrewApp extends ConsumerStatefulWidget {
  const PocketBrewApp({
    super.key,
    this.router,
    this.enableOnboardingGate = true,
  });

  final GoRouter? router;
  final bool enableOnboardingGate;

  @override
  ConsumerState<PocketBrewApp> createState() => _PocketBrewAppState();
}

class _PocketBrewAppState extends ConsumerState<PocketBrewApp> {
  static final ThemeData _lightTheme = PocketTheme.build(PocketColors.softOat);
  static final ThemeData _darkTheme =
      PocketTheme.build(PocketColors.espressoDusk);

  bool _didCheckInitialOnboarding = false;

  GoRouter get _activeRouter => widget.router ?? pocketRouter;

  void _maybeRouteToOnboarding(PocketAppState state) {
    if (!widget.enableOnboardingGate || _didCheckInitialOnboarding) return;
    if (!state.isLoaded) return;
    _didCheckInitialOnboarding = true;
    if (!state.prefs.onboarded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _activeRouter.go('/onboarding');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PocketAppState>(pocketStoreProvider, (prev, next) {
      _maybeRouteToOnboarding(next);
    });
    final current = ref.read(pocketStoreProvider);
    if (current.isLoaded && !_didCheckInitialOnboarding) {
      _maybeRouteToOnboarding(current);
    }

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
      routerConfig: _activeRouter,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final framedChild = _PocketEntranceCurtain(child: child);
        // On real phones (or mobile viewports <= 540px), run 100% edge-to-edge full screen.
        // On wide desktop browsers, center inside a clean 412px Android phone preview bezel.
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

/// Pure, minimalist iconic launch animation (ZERO text clutter):
/// Theme-aware Soft Oat / Espresso Dusk canvas with a smooth circular pour-over
/// orbit reveal and soft concentric bloom around the Pocket Brew mark.
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
      duration: const Duration(milliseconds: 1950),
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
            Color(0xFF211B17),
            Color(0xFF141210),
          ]
        : const [
            Color(0xFFFFFCF8),
            Color(0xFFF3ECE2),
          ];

    final ringTrack =
        isDark ? const Color(0xFF2E2621) : const Color(0xFFE5DACB);
    final pedestalBg = isDark ? const Color(0xFF1E1A17) : const Color(0xFFFFFDF9);
    final pedestalBorder =
        isDark ? const Color(0xFF352C26) : const Color(0xFFE6DACC);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;

        // Smooth lift & crossfade out (0.74 -> 1.0)
        final exitT =
            Curves.easeInOutCubic.transform(((t - 0.74) / 0.26).clamp(0.0, 1.0));
        final curtainOpacity = (1.0 - exitT).clamp(0.0, 1.0);
        final curtainScale = 1.0 + (exitT * 0.04);

        // Emblem entrance + continuous pour orbit sweep + soft bloom ripple
        final emblemIn =
            PocketCurves.gentleSpring.transform((t / 0.34).clamp(0.0, 1.0));
        final orbitSweep =
            Curves.easeOutCubic.transform(((t - 0.06) / 0.60).clamp(0.0, 1.0));
        final ripple =
            Curves.easeOutCubic.transform(((t - 0.14) / 0.66).clamp(0.0, 1.0));
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
                    child: Transform.scale(
                      scale: curtainScale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.95,
                            colors: bgColors,
                          ),
                        ),
                        child: Center(
                          child: Transform.scale(
                            scale: 0.80 + (0.20 * emblemIn),
                            child: Opacity(
                              opacity: emblemIn.clamp(0.0, 1.0),
                              child: SizedBox(
                                width: 176,
                                height: 176,
                                child: CustomPaint(
                                  painter: _MinimalPourOrbitPainter(
                                    sweep: orbitSweep,
                                    ripple: ripple,
                                    accent: c.brandTerracotta,
                                    track: ringTrack,
                                    isDark: isDark,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 108,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        color: pedestalBg,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: pedestalBorder,
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: c.brandTerracotta.withValues(
                                              alpha: isDark ? 0.18 : 0.12,
                                            ),
                                            blurRadius: 30,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const PocketBrewMark(
                                        size: 76,
                                        backgroundColor: Color(0xFFC05E3A),
                                        foregroundColor: Color(0xFFFFFDF9),
                                        dropColor: Color(0xFFF6E3DA),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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

class _MinimalPourOrbitPainter extends CustomPainter {
  const _MinimalPourOrbitPainter({
    required this.sweep,
    required this.ripple,
    required this.accent,
    required this.track,
    required this.isDark,
  });

  final double sweep;
  final double ripple;
  final Color accent;
  final Color track;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orbitR = size.width / 2 - 18;

    // 1. Soft expanding bloom ripple
    if (ripple > 0.01 && ripple < 0.99) {
      final r = orbitR + (18.0 * ripple);
      final alpha = ((1.0 - ripple) * (isDark ? 0.30 : 0.24)).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = accent.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // 2. Clean hairline ring track
    canvas.drawCircle(
      center,
      orbitR,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 3. Smooth terracotta pour arc
    if (sweep > 0.01) {
      final sweepAngle = 2 * math.pi * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbitR),
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );

      final tipAngle = -math.pi / 2 + sweepAngle;
      final tip = Offset(
        center.dx + orbitR * math.cos(tipAngle),
        center.dy + orbitR * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tip,
        5.0,
        Paint()..color = accent.withValues(alpha: 0.24),
      );
      canvas.drawCircle(
        tip,
        2.5,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MinimalPourOrbitPainter old) =>
      old.sweep != sweep || old.ripple != ripple || old.isDark != isDark;
}
