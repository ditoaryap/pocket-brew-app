import 'package:flutter/material.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';

/// Circular Pocket Brew brand mark (V60 Cone + Rib + Pocket Cradle + Coffee Drop)
/// matching FigCraft v7 (`01`, `02`).
class PocketBrewMark extends StatelessWidget {
  const PocketBrewMark({
    super.key,
    this.size = 34,
    this.backgroundColor,
    this.foregroundColor,
    this.dropColor,
    this.circular = true,
  });

  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? dropColor;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = backgroundColor ?? const Color(0xFFB85835);
    final fg = foregroundColor ?? const Color(0xFFFFFDF9);
    final drop = dropColor ?? const Color(0xFFF5E2D9);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(size * 0.28),
        boxShadow: c.isDark
            ? null
            : [
                BoxShadow(
                  color: bg.withValues(alpha: 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: CustomPaint(
        painter: _PocketLogoPainter(color: fg, dropColor: drop),
      ),
    );
  }
}

class PocketBrewWordmark extends StatelessWidget {
  const PocketBrewWordmark({super.key, this.markSize = 30, this.fontSize = 19});

  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PocketBrewMark(size: markSize),
        const SizedBox(width: 9),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'pocket brew',
              style: PocketTheme.ui(
                size: fontSize,
                weight: 700,
                letterSpacing: -fontSize * 0.015,
                color: c.textPrimary,
              ),
            ),
            Text(
              '.',
              style: PocketTheme.ui(
                size: fontSize + 2,
                weight: 800,
                color: c.brandTerracotta,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PocketLogoPainter extends CustomPainter {
  const _PocketLogoPainter({required this.color, required this.dropColor});
  final Color color;
  final Color dropColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.068
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // V60 Dripper Cone
    final cone = Path()
      ..moveTo(w * 0.24, h * 0.25)
      ..lineTo(w * 0.76, h * 0.25)
      ..lineTo(w * 0.56, h * 0.57)
      ..lineTo(w * 0.44, h * 0.57)
      ..close();
    canvas.drawPath(cone, stroke);

    // Subtle V60 diagonal rib inside cone
    canvas.drawLine(
      Offset(w * 0.38, h * 0.27),
      Offset(w * 0.48, h * 0.54),
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.044
        ..strokeCap = StrokeCap.round,
    );

    // Pocket Cradle curve underneath cone
    final cradle = Path()
      ..moveTo(w * 0.28, h * 0.65)
      ..quadraticBezierTo(w * 0.50, h * 0.85, w * 0.72, h * 0.65);
    canvas.drawPath(cradle, stroke);

    // Warm terracotta-tint coffee droplet at center (FigCraft #F5E2D9)
    final dropFill = Paint()
      ..color = dropColor
      ..style = PaintingStyle.fill;
    final drop = Path()
      ..moveTo(w * 0.50, h * 0.61)
      ..quadraticBezierTo(w * 0.565, h * 0.70, w * 0.50, h * 0.75)
      ..quadraticBezierTo(w * 0.435, h * 0.70, w * 0.50, h * 0.61)
      ..close();
    canvas.drawPath(drop, dropFill);
  }

  @override
  bool shouldRepaint(covariant _PocketLogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dropColor != dropColor;
}
