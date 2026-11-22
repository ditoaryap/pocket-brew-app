import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fluid motion constants & spring-inspired curves matching Pocket Brew Motion Spec.
class PocketCurves {
  static const Curve smoothOut = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve gentleSpring = Cubic(0.18, 0.92, 0.28, 1.0);
  static const Curve fastOut = Cubic(0.2, 0.0, 0.0, 1.0);

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration gentle = Duration(milliseconds: 360);
}

/// Lightweight one-shot entrance motion (GPU-composited RepaintBoundary + Opacity + slide).
/// Runs once on mount with zero ongoing tickers so mobile web stays 60fps.
class PocketEntrance extends StatefulWidget {
  const PocketEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offsetY = 10,
    this.duration = const Duration(milliseconds: 260),
  });

  final Widget child;
  final int delayMs;
  final double offsetY;
  final Duration duration;

  @override
  State<PocketEntrance> createState() => _PocketEntranceState();
}

class _PocketEntranceState extends State<PocketEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final totalMs = widget.delayMs + widget.duration.inMilliseconds;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    final start =
        totalMs > 0 ? (widget.delayMs / totalMs).clamp(0.0, 0.85) : 0.0;
    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, 1.0, curve: PocketCurves.smoothOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(curve);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        child: widget.child,
        builder: (context, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.translate(offset: _slide.value, child: child),
        ),
      ),
    );
  }
}

/// Enables smooth drag scrolling with both touch and mouse on web preview.
class PocketScrollBehavior extends MaterialScrollBehavior {
  const PocketScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

/// Tactile press-scale micro-interaction (feels like native iOS/Android hardware feedback).
class PocketTapScale extends StatefulWidget {
  const PocketTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.968,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  @override
  State<PocketTapScale> createState() => _PocketTapScaleState();
}

class _PocketTapScaleState extends State<PocketTapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: PocketCurves.smoothOut,
        child: widget.child,
      ),
    );
  }
}

/// Silky native parallax push/pop transition for GoRouter sub-routes.
/// Incoming page glides cleanly from right (22% -> 0%) while outgoing subtly recedes (-6%).
CustomTransitionPage<T> pocketSlidePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final primary = CurvedAnimation(
        parent: animation,
        curve: PocketCurves.smoothOut,
        reverseCurve: Curves.easeInOutCubic,
      );
      final secondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: PocketCurves.smoothOut,
        reverseCurve: Curves.easeInOutCubic,
      );

      final inSlide = Tween<Offset>(
        begin: const Offset(0.22, 0),
        end: Offset.zero,
      ).animate(primary);
      final outParallax = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.06, 0),
      ).animate(secondary);
      final inFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
          reverseCurve: const Interval(0.25, 1.0, curve: Curves.easeIn),
        ),
      );
      final outFade = Tween<double>(begin: 1.0, end: 0.92).animate(secondary);

      return SlideTransition(
        position: outParallax,
        child: FadeTransition(
          opacity: outFade,
          child: SlideTransition(
            position: inSlide,
            child: FadeTransition(
              opacity: inFade,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// Silky modal slide-up + subtle depth scale-back transition for editor/creation flows.
CustomTransitionPage<T> pocketModalPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final primary = CurvedAnimation(
        parent: animation,
        curve: PocketCurves.smoothOut,
        reverseCurve: Curves.easeInOutCubic,
      );
      final secondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: PocketCurves.smoothOut,
        reverseCurve: Curves.easeInOutCubic,
      );

      final inSlide = Tween<Offset>(
        begin: const Offset(0, 0.14),
        end: Offset.zero,
      ).animate(primary);
      final inFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        ),
      );
      final outScale = Tween<double>(begin: 1.0, end: 0.982).animate(secondary);

      return ScaleTransition(
        scale: outScale,
        child: SlideTransition(
          position: inSlide,
          child: FadeTransition(
            opacity: inFade,
            child: child,
          ),
        ),
      );
    },
  );
}
