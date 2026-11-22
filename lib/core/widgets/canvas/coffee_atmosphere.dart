import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/pocket_theme.dart';
import '../../../app/theme/pocket_tokens.dart';
import '../../motion/pocket_motion.dart';

/// Lightweight GPU-composited ambient backdrop for Beranda:
/// - Hot V60: organic rising coffee aroma wisps in soft terracotta/crema.
/// - Japanese Iced: drifting translucent ice crystal facets & cool mist rings.
/// Automatically pauses when off-screen (via TickerMode) or when Reduce Motion is enabled,
/// and stays deterministic in widget tests so pumpAndSettle() never hangs.
class BrewAtmosphereBackdrop extends StatefulWidget {
  const BrewAtmosphereBackdrop({
    super.key,
    required this.isIced,
    required this.child,
    this.borderRadius = 26,
  });

  final bool isIced;
  final Widget child;
  final double borderRadius;

  @override
  State<BrewAtmosphereBackdrop> createState() => _BrewAtmosphereBackdropState();
}

class _BrewAtmosphereBackdropState extends State<BrewAtmosphereBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _ambientCtrl;
  late final AnimationController _modeCtrl;

  bool get _allowContinuousMotion =>
      WidgetsBinding.instance is WidgetsFlutterBinding;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
      value: 0.35,
    );
    _modeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.isIced ? 1.0 : 0.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (_allowContinuousMotion && !disableMotion) {
      if (!_ambientCtrl.isAnimating) {
        _ambientCtrl.repeat();
      }
    } else if (_ambientCtrl.isAnimating) {
      _ambientCtrl.stop();
    }
  }

  @override
  void didUpdateWidget(covariant BrewAtmosphereBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isIced != widget.isIced) {
      _modeCtrl.animateTo(
        widget.isIced ? 1.0 : 0.0,
        curve: PocketCurves.smoothOut,
      );
    }
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _modeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_ambientCtrl, _modeCtrl]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _BrewAtmospherePainter(
                      phase: _ambientCtrl.value,
                      icedT: _modeCtrl.value,
                      hotAccent: c.brandTerracotta,
                      hotSoft: c.brandHoney,
                      icedAccent: c.brandIce,
                      isDark: c.isDark,
                    ),
                  );
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _BrewAtmospherePainter extends CustomPainter {
  const _BrewAtmospherePainter({
    required this.phase,
    required this.icedT,
    required this.hotAccent,
    required this.hotSoft,
    required this.icedAccent,
    required this.isDark,
  });

  final double phase;
  final double icedT;
  final Color hotAccent;
  final Color hotSoft;
  final Color icedAccent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final hotWeight = (1.0 - icedT).clamp(0.0, 1.0);
    final icedWeight = icedT.clamp(0.0, 1.0);
    final glowColor = Color.lerp(hotAccent, icedAccent, icedT)!;

    // 1. Soft top-right ambient radial glow that shifts warmly between Hot & Iced
    final glowCenter = Offset(size.width * 0.88, size.height * 0.14);
    final glowRadius = size.width * 0.65;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glowColor.withValues(alpha: isDark ? 0.16 : 0.11),
            glowColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    // 2. Hot V60: 3 graceful sinusoidal rising coffee aroma wisps on right flank
    if (hotWeight > 0.02) {
      final t = phase * 2 * math.pi;
      for (int i = 0; i < 3; i++) {
        final baseX = size.width * (0.74 + i * 0.085);
        final path = Path();
        const steps = 16;
        final topY = size.height * 0.06;
        final botY = size.height * 0.62;
        for (int s = 0; s <= steps; s++) {
          final frac = s / steps;
          final y = botY - (botY - topY) * frac;
          final sway =
              math.sin(frac * 3.8 - t + i * 1.65) * (6.5 + i * 2.2) * frac;
          final x = baseX + sway;
          if (s == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        final strokeAlpha =
            (isDark ? 0.14 : 0.11) * hotWeight * (1.0 - i * 0.18);
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(hotAccent, hotSoft, i * 0.35)!
                .withValues(alpha: strokeAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0 - i * 0.3
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // 3. Japanese Iced: crisp floating diamond ice facets & soft frost rings
    if (icedWeight > 0.02) {
      final t = phase * 2 * math.pi;
      final crystals = [
        (0.76, 0.16, 11.0, 0.0),
        (0.89, 0.28, 15.0, 1.9),
        (0.81, 0.44, 8.5, 3.6),
        (0.93, 0.11, 7.0, 4.9),
      ];
      for (final (fx, fy, radius, seed) in crystals) {
        final cx = size.width * fx + math.cos(t + seed) * 3.5;
        final cy = size.height * fy + math.sin(t + seed) * 5.0;
        final rot = (phase * 0.5 + seed * 0.15) * math.pi;
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(rot);

        final diamond = Path()
          ..moveTo(0, -radius)
          ..lineTo(radius * 0.72, 0)
          ..lineTo(0, radius)
          ..lineTo(-radius * 0.72, 0)
          ..close();

        canvas.drawPath(
          diamond,
          Paint()
            ..color = icedAccent.withValues(
              alpha: (isDark ? 0.14 : 0.11) * icedWeight,
            )
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          diamond,
          Paint()
            ..color = icedAccent.withValues(
              alpha: (isDark ? 0.28 : 0.22) * icedWeight,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrewAtmospherePainter old) =>
      old.phase != phase || old.icedT != icedT || old.isDark != isDark;
}

/// Sleek one-shot animated stock level bar (zero ongoing tickers).
class AnimatedCoffeeStockBar extends StatelessWidget {
  const AnimatedCoffeeStockBar({
    super.key,
    required this.fraction,
    required this.fillColor,
    required this.trackColor,
    this.height = 7,
  });

  final double fraction;
  final Color fillColor;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final target = fraction.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: target),
      duration: const Duration(milliseconds: 520),
      curve: PocketCurves.smoothOut,
      builder: (context, val, _) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
          ),
          clipBehavior: Clip.antiAlias,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: val <= 0.005 ? 0.0 : val.clamp(0.03, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    fillColor.withValues(alpha: 0.84),
                    fillColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Distinct, unmistakable Japanese Iced Hot-Water vs Ice-Cube Split Visualizer.
/// Renders a smooth animated dual bar showing exact Hot Water (Terracotta) and
/// Ice Cube (Glacier Ice) proportions + clear legend for Riwayat, Detail & Belajar Seduh.
class AnimatedWaterIceSplitBar extends StatelessWidget {
  const AnimatedWaterIceSplitBar({
    super.key,
    required this.hotWaterLabel,
    required this.iceLabel,
    required this.hotFraction,
    this.methodBadge,
    this.totalLabel,
    this.compact = false,
  });

  final String hotWaterLabel;
  final String iceLabel;
  final double hotFraction;
  final String? methodBadge;
  final String? totalLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final clampedHot = hotFraction.clamp(0.25, 0.88);
    final hotPct = (clampedHot * 100).round();
    final icePct = 100 - hotPct;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 13),
      decoration: BoxDecoration(
        color: c.tintIce.withValues(alpha: c.isDark ? 0.55 : 0.72),
        borderRadius: BorderRadius.circular(compact ? 13 : 16),
        border: Border.all(
          color: c.brandIce.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c.brandTerracotta,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Air Panas $hotWaterLabel ($hotPct%)',
                        style: PocketTheme.mono(
                          size: compact ? 10.8 : 11.8,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c.brandIce,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Es $iceLabel ($icePct%)',
                        style: PocketTheme.mono(
                          size: compact ? 10.8 : 11.8,
                          weight: FontWeight.w800,
                          color: c.brandIce,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.5, end: clampedHot),
            duration: const Duration(milliseconds: 460),
            curve: PocketCurves.smoothOut,
            builder: (context, val, _) {
              final hotFlex = (val * 1000).round().clamp(150, 850);
              final iceFlex = (1000 - hotFlex).clamp(150, 850);
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: compact ? 7 : 9,
                  child: Row(
                    children: [
                      Expanded(
                        flex: hotFlex,
                        child: Container(color: c.brandTerracotta),
                      ),
                      const SizedBox(width: 2.5),
                      Expanded(
                        flex: iceFlex,
                        child: Container(color: c.brandIce),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (methodBadge != null || totalLabel != null) ...[
            SizedBox(height: compact ? 6 : 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (methodBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceCard.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Teknik: $methodBadge',
                      style: PocketTheme.ui(
                        size: compact ? 10.5 : 11.2,
                        weight: 700,
                        color: c.brandIce,
                      ),
                    ),
                  ),
                if (totalLabel != null)
                  Text(
                    'Total hasil: $totalLabel',
                    style: PocketTheme.mono(
                      size: compact ? 10.5 : 11.2,
                      weight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated sensory bar gauge for Brew Log Detail (Asam, Manis, Pahit, Body).
class AnimatedFlavorGauge extends StatelessWidget {
  const AnimatedFlavorGauge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.delayMs = 0,
  });

  final String label;
  final double value;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final frac = (value / 5.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PocketTheme.ui(
                  size: 12.2,
                  weight: 700,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${value.toStringAsFixed(1)}/5',
              style: PocketTheme.mono(
                size: 11.2,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: frac),
          duration: Duration(milliseconds: 480 + delayMs),
          curve: PocketCurves.smoothOut,
          builder: (context, v, _) {
            return Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
              ),
              clipBehavior: Clip.antiAlias,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v <= 0.01 ? 0.0 : v,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
