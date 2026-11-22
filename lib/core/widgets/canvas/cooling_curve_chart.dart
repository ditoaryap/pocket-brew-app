import 'package:flutter/material.dart';
import '../../../app/theme/pocket_theme.dart';
import '../../../app/theme/pocket_tokens.dart';

/// 1:1 FigCraft v7 Cooling Curve (`Kapan Enaknya Dicicipi?`):
/// Clean gentle slope through green 55-65°C Sweet Spot highlight band.
class CoolingCurveChart extends StatelessWidget {
  const CoolingCurveChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 82,
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surfaceElevated.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomPaint(
        painter: _CoolingCurvePainter(
          sage: c.brandSage,
          sageTint: c.tintSage,
          terracotta: c.brandTerracotta,
          textTertiary: c.textTertiary,
        ),
      ),
    );
  }
}

class _CoolingCurvePainter extends CustomPainter {
  const _CoolingCurvePainter({
    required this.sage,
    required this.sageTint,
    required this.terracotta,
    required this.textTertiary,
  });

  final Color sage;
  final Color sageTint;
  final Color terracotta;
  final Color textTertiary;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sweet Spot band in the middle
    canvas.drawRect(
      Rect.fromLTRB(w * 0.34, 0, w * 0.68, h),
      Paint()..color = sageTint,
    );

    // Gentle cooling descent curve (matching FigCraft Screen 10)
    final path = Path()
      ..moveTo(14, h * 0.32)
      ..cubicTo(w * 0.32, h * 0.34, w * 0.56, h * 0.64, w - 14, h * 0.76);

    canvas.drawPath(
      path,
      Paint()
        ..color = terracotta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Green Sweet Spot dot at ~60°C
    final dot = Offset(w * 0.51, h * 0.52);
    canvas.drawCircle(dot, 5.2, Paint()..color = Colors.white);
    canvas.drawCircle(dot, 3.6, Paint()..color = sage);

    _drawText(canvas, '90°C\nTerlalu panas', 10, h * 0.44, textTertiary, false);
    _drawText(
        canvas, '60°C · Manis & buah', w * 0.36, 10, sage, true);
    _drawText(
        canvas, '35°C\nAsam naik', w - 66, h * 0.34, textTertiary, false);
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
    bool bold,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: PocketTheme.ui(
          size: 9.5,
          weight: bold ? 800 : 600,
          color: color,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _CoolingCurvePainter old) =>
      old.sage != sage ||
      old.sageTint != sageTint ||
      old.terracotta != terracotta ||
      old.textTertiary != textTertiary;
}
