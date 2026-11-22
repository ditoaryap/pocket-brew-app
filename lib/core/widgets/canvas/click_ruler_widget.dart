import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/pocket_theme.dart';
import '../../../app/theme/pocket_tokens.dart';
import '../../motion/pocket_motion.dart';

/// Interactive smooth-animated Grinder Click Ruler matching FigCraft v7 (`04` & `05`).
/// Shows a crisp 16-click tactile ruler window around the V60 sweet spot (automatically
/// sliding if the user steps outside the default window), wrapped in [RepaintBoundary]
/// so dragging stays lightweight 60fps on mobile web.
class ClickRulerWidget extends StatelessWidget {
  const ClickRulerWidget({
    super.key,
    required this.minClick,
    required this.maxClick,
    required this.zoneMin,
    required this.zoneMax,
    required this.value,
    required this.accentColor,
    required this.tintColor,
    required this.onChanged,
    this.compact = false,
    this.showLeftHalusLabel = true,
  });

  final int minClick;
  final int maxClick;
  final int zoneMin;
  final int zoneMax;
  final int value;
  final Color accentColor;
  final Color tintColor;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool showLeftHalusLabel;

  (int winMin, int winMax) _windowRange() {
    final effMin = math.min(minClick, value).clamp(0, 250);
    final effMax = math.max(maxClick, value).clamp(effMin + 1, 250);
    final totalSpan = effMax - effMin;
    if (totalSpan <= 16) return (effMin, effMax);

    const targetSpan = 15; // 16 ticks (e.g. 15..30 or 14..29) matching FigCraft!
    final zoneCenter = ((zoneMin + zoneMax) / 2.0).round();
    int start = (zoneCenter - 8).clamp(effMin, effMax - targetSpan);
    int end = start + targetSpan;

    // Keep current value comfortably inside the visible ruler window (even if custom outside default!)
    if (value < start) {
      start = value.clamp(effMin, effMax - targetSpan);
      end = start + targetSpan;
    } else if (value > end) {
      end = value.clamp(effMin + targetSpan, effMax);
      start = end - targetSpan;
    }
    return (start, end);
  }

  void _updateFromDx(double dx, double width, int winMin, int winMax) {
    if (width <= 0) return;
    const hPad = 14.0;
    final usableW = (width - hPad * 2).clamp(1.0, width);
    final frac = ((dx - hPad) / usableW).clamp(0.0, 1.0);
    final next = (winMin + frac * (winMax - winMin)).round().clamp(0, 250);
    if (next != value) {
      HapticFeedback.selectionClick();
      onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (winMin, winMax) = _windowRange();
    final rulerHeight = compact ? 38.0 : 42.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _updateFromDx(d.localPosition.dx, w, winMin, winMax),
          onHorizontalDragUpdate: (d) =>
              _updateFromDx(d.localPosition.dx, w, winMin, winMax),
          child: AnimatedContainer(
            duration: PocketCurves.normal,
            curve: PocketCurves.smoothOut,
            height: rulerHeight,
            decoration: BoxDecoration(
              color: c.isDark ? c.surfaceElevated : c.surfaceCanvas,
              borderRadius: BorderRadius.circular(compact ? 11 : 12),
            ),
            child: RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: value.toDouble()),
                duration: const Duration(milliseconds: 200),
                curve: PocketCurves.smoothOut,
                builder: (context, animatedVal, _) {
                  return CustomPaint(
                    size: Size(w, rulerHeight),
                    painter: _ClickRulerPainter(
                      winMin: winMin,
                      winMax: winMax,
                      zoneMin: zoneMin,
                      zoneMax: zoneMax,
                      animatedValue: animatedVal,
                      displayValue: value,
                      accentColor: accentColor,
                      tintColor: tintColor,
                      tickColor: c.borderStrong,
                      labelColor: c.textTertiary,
                      compact: compact,
                      showLeftHalusLabel: showLeftHalusLabel,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClickRulerPainter extends CustomPainter {
  _ClickRulerPainter({
    required this.winMin,
    required this.winMax,
    required this.zoneMin,
    required this.zoneMax,
    required this.animatedValue,
    required this.displayValue,
    required this.accentColor,
    required this.tintColor,
    required this.tickColor,
    required this.labelColor,
    required this.compact,
    required this.showLeftHalusLabel,
  });

  final int winMin;
  final int winMax;
  final int zoneMin;
  final int zoneMax;
  final double animatedValue;
  final int displayValue;
  final Color accentColor;
  final Color tintColor;
  final Color tickColor;
  final Color labelColor;
  final bool compact;
  final bool showLeftHalusLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const hPad = 14.0;
    final trackW = math.max(1.0, size.width - hPad * 2);
    final span = math.max(1, winMax - winMin);

    double xOf(double click) =>
        hPad + ((click - winMin) / span).clamp(0.0, 1.0) * trackW;

    final barCenterY = compact ? 12.0 : 13.5;

    // Recommended sweet-spot zone highlight pill
    final zLeft = xOf(zoneMin.toDouble());
    final zRight = xOf(zoneMax.toDouble());
    final zoneH = compact ? 14.0 : 16.0;
    if (zRight > zLeft) {
      final zoneRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          (zLeft - 6).clamp(6.0, size.width - 6),
          barCenterY - zoneH / 2,
          (zRight + 6).clamp(6.0, size.width - 6),
          barCenterY + zoneH / 2,
        ),
        Radius.circular(compact ? 5 : 6),
      );
      canvas.drawRRect(zoneRect, Paint()..color = tintColor);
    }

    // Crisp uniform rounded tick bars (major every 5 ticks, minor 8px)
    final tickPaint = Paint()
      ..color = tickColor
      ..style = PaintingStyle.fill;

    for (int cl = winMin; cl <= winMax; cl++) {
      if (cl == displayValue) continue;
      final x = xOf(cl.toDouble());
      final isMajor = !compact && cl % 5 == 0;
      final h = isMajor ? 13.0 : 8.0;
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, barCenterY), width: 2.0, height: h),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(r, tickPaint);
    }

    // Smoothly gliding active indicator needle (4px wide rounded pill)
    final activeX = xOf(animatedValue);
    final needleH = compact ? 17.0 : 20.0;
    final needle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(activeX, barCenterY),
        width: 4.0,
        height: needleH,
      ),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(needle, Paint()..color = accentColor);

    // Accurately measured bottom labels (zero overlap, crisp alignment)
    final fontSize = compact ? 9.0 : 9.5;
    final labelY = size.height - (compact ? 14.0 : 15.0);

    final leftText = showLeftHalusLabel ? '$winMin Halus' : '$winMin';
    final leftTp = _layoutLabel(leftText, labelColor, fontSize, false);
    leftTp.paint(canvas, Offset(hPad - 2, labelY));

    final rightTp = _layoutLabel('$winMax Kasar', labelColor, fontSize, false);
    final rightX = size.width - (hPad - 2) - rightTp.width;
    rightTp.paint(canvas, Offset(rightX, labelY));

    final valTp = _layoutLabel('$displayValue', accentColor, fontSize, true);
    final minValX = (hPad - 2) + leftTp.width + 6;
    final maxValX = rightX - valTp.width - 6;
    if (maxValX >= minValX) {
      final centeredX = (activeX - valTp.width / 2).clamp(minValX, maxValX);
      valTp.paint(canvas, Offset(centeredX, labelY));
    }
  }

  TextPainter _layoutLabel(
    String text,
    Color color,
    double size,
    bool bold,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: PocketTheme.mono(
          size: size,
          weight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _ClickRulerPainter old) =>
      old.animatedValue != animatedValue ||
      old.displayValue != displayValue ||
      old.accentColor != accentColor ||
      old.tintColor != tintColor ||
      old.winMin != winMin ||
      old.winMax != winMax ||
      old.zoneMin != zoneMin ||
      old.zoneMax != zoneMax ||
      old.compact != compact;
}
