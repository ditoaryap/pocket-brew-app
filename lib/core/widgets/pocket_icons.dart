import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PocketIconType {
  home,
  bean,
  v60,
  log,
  burrGear,
  flame,
  snowflake,
  sliders,
  book,
  recipe,
  edit,
  timer,
  plus,
  minus,
  chevronRight,
  compass,
  star,
  starFilled,
  play,
  check,
  warning,
  filterPaper,
  backArrow,
}

/// Crisp bespoke 1.85px rounded-stroke vector icons matching Pocket Brew FigCraft v7 icon library.
class PocketIcon extends StatelessWidget {
  const PocketIcon(
    this.type, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.85,
  });

  final PocketIconType type;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF1F1915);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PocketIconPainter(
          type: type,
          color: c,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _PocketIconPainter extends CustomPainter {
  const _PocketIconPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  final PocketIconType type;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset pt(double x, double y) => Offset(x * s, y * s);

    switch (type) {
      case PocketIconType.home:
        final house = Path()
          ..moveTo(4 * s, 10.5 * s)
          ..lineTo(12 * s, 4 * s)
          ..lineTo(20 * s, 10.5 * s)
          ..lineTo(20 * s, 19.2 * s)
          ..quadraticBezierTo(20 * s, 20.5 * s, 18.7 * s, 20.5 * s)
          ..lineTo(5.3 * s, 20.5 * s)
          ..quadraticBezierTo(4 * s, 20.5 * s, 4 * s, 19.2 * s)
          ..close();
        canvas.drawPath(house, p);
        final door = Path()
          ..moveTo(9.5 * s, 20.5 * s)
          ..lineTo(9.5 * s, 14.5 * s)
          ..quadraticBezierTo(12 * s, 13 * s, 14.5 * s, 14.5 * s)
          ..lineTo(14.5 * s, 20.5 * s);
        canvas.drawPath(door, p);

      case PocketIconType.bean:
        canvas.drawOval(
          Rect.fromCenter(center: pt(12, 12), width: 14 * s, height: 18 * s),
          p,
        );
        final crease = Path()
          ..moveTo(12 * s, 3.3 * s)
          ..cubicTo(14.5 * s, 8.5 * s, 9.5 * s, 15.5 * s, 12 * s, 20.7 * s);
        canvas.drawPath(crease, p);

      case PocketIconType.v60:
        final cone = Path()
          ..moveTo(4.5 * s, 5 * s)
          ..lineTo(19.5 * s, 5 * s)
          ..lineTo(14.3 * s, 15 * s)
          ..lineTo(9.7 * s, 15 * s)
          ..close();
        canvas.drawPath(cone, p);
        canvas.drawLine(pt(6.5, 19), pt(17.5, 19), p);
        canvas.drawLine(pt(10.5, 15), pt(10.5, 19), p);
        canvas.drawLine(pt(13.5, 15), pt(13.5, 19), p);

      case PocketIconType.log:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTRB(5 * s, 3.5 * s, 19 * s, 20.5 * s),
          Radius.circular(3 * s),
        );
        canvas.drawRRect(rect, p);
        canvas.drawLine(pt(8.5, 8.5), pt(15.5, 8.5), p);
        canvas.drawLine(pt(8.5, 12.2), pt(15.5, 12.2), p);
        canvas.drawLine(pt(8.5, 15.9), pt(13.0, 15.9), p);

      case PocketIconType.burrGear:
        canvas.drawCircle(pt(12, 12), 3.6 * s, p);
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            Offset((12 + math.cos(a) * 6.3) * s, (12 + math.sin(a) * 6.3) * s),
            Offset((12 + math.cos(a) * 9.2) * s, (12 + math.sin(a) * 9.2) * s),
            p,
          );
        }

      case PocketIconType.flame:
        final drop = Path()
          ..moveTo(12 * s, 3.5 * s)
          ..cubicTo(16.8 * s, 9 * s, 18.5 * s, 12.6 * s, 18.5 * s, 15.2 * s)
          ..arcToPoint(
            pt(5.5, 15.2),
            radius: Radius.circular(6.5 * s),
          )
          ..cubicTo(5.5 * s, 12.6 * s, 7.2 * s, 9 * s, 12 * s, 3.5 * s)
          ..close();
        canvas.drawPath(drop, p);
        final inner = Path()
          ..moveTo(12 * s, 11.2 * s)
          ..cubicTo(14.1 * s, 13.6 * s, 14.7 * s, 15.1 * s, 14.7 * s, 16.2 * s)
          ..arcToPoint(
            pt(9.3, 16.2),
            radius: Radius.circular(2.7 * s),
          )
          ..cubicTo(9.3 * s, 15.1 * s, 9.9 * s, 13.6 * s, 12 * s, 11.2 * s)
          ..close();
        canvas.drawPath(inner, p..strokeWidth = strokeWidth * 0.85);

      case PocketIconType.snowflake:
        for (int i = 0; i < 3; i++) {
          final a = i * math.pi / 3;
          final dx = math.cos(a);
          final dy = math.sin(a);
          canvas.drawLine(
            Offset((12 - dx * 8.2) * s, (12 - dy * 8.2) * s),
            Offset((12 + dx * 8.2) * s, (12 + dy * 8.2) * s),
            p,
          );
          // Small crystalline V-ticks on tips
          for (final dir in [-1.0, 1.0]) {
            final bx = 12 + dx * 5.6 * dir;
            final by = 12 + dy * 5.6 * dir;
            for (final sign in [-1.0, 1.0]) {
              final branchA = a + (dir > 0 ? 0 : math.pi) + sign * 0.65;
              canvas.drawLine(
                Offset(bx * s, by * s),
                Offset(
                  (bx + math.cos(branchA) * 2.4) * s,
                  (by + math.sin(branchA) * 2.4) * s,
                ),
                p..strokeWidth = strokeWidth * 0.85,
              );
            }
          }
        }
        canvas.drawCircle(pt(12, 12), 1.9 * s, fill);

      case PocketIconType.sliders:
        canvas.drawLine(pt(4, 7), pt(20, 7), p);
        canvas.drawLine(pt(4, 12), pt(20, 12), p);
        canvas.drawLine(pt(4, 17), pt(20, 17), p);
        canvas.drawCircle(pt(9, 7), 2 * s, fill);
        canvas.drawCircle(pt(15, 12), 2 * s, fill);
        canvas.drawCircle(pt(10, 17), 2 * s, fill);

      case PocketIconType.book:
        final r = RRect.fromRectAndRadius(
          Rect.fromLTRB(4.5 * s, 4 * s, 19.5 * s, 20 * s),
          Radius.circular(2.6 * s),
        );
        canvas.drawRRect(r, p);
        canvas.drawLine(pt(12, 4.5), pt(12, 19.5), p);
        canvas.drawLine(pt(7.2, 9), pt(9.8, 9), p);
        canvas.drawLine(pt(14.2, 9), pt(16.8, 9), p);

      case PocketIconType.recipe:
        final card = RRect.fromRectAndRadius(
          Rect.fromLTRB(5 * s, 4 * s, 19 * s, 20 * s),
          Radius.circular(3 * s),
        );
        canvas.drawRRect(card, p);
        canvas.drawLine(pt(8.5, 9), pt(15.5, 9), p);
        canvas.drawLine(pt(8.5, 12.8), pt(15.5, 12.8), p);
        canvas.drawLine(pt(8.5, 16.4), pt(12.8, 16.4), p);

      case PocketIconType.edit:
        final pen = Path()
          ..moveTo(15.2 * s, 4.8 * s)
          ..lineTo(19.2 * s, 8.8 * s)
          ..lineTo(9.2 * s, 18.8 * s)
          ..lineTo(4.6 * s, 19.4 * s)
          ..lineTo(5.2 * s, 14.8 * s)
          ..close();
        canvas.drawPath(pen, p);
        canvas.drawLine(pt(13.2, 6.8), pt(17.2, 10.8), p);

      case PocketIconType.timer:
        canvas.drawLine(pt(9.5, 3.5), pt(14.5, 3.5), p);
        canvas.drawLine(pt(12, 3.5), pt(12, 6.2), p);
        canvas.drawCircle(pt(12, 13.5), 7.2 * s, p);
        canvas.drawLine(pt(12, 13.5), pt(15.2, 10.6), p);
        canvas.drawCircle(pt(12, 13.5), 1.2 * s, fill);

      case PocketIconType.plus:
        canvas.drawLine(pt(12, 5.5), pt(12, 18.5), p);
        canvas.drawLine(pt(5.5, 12), pt(18.5, 12), p);

      case PocketIconType.minus:
        canvas.drawLine(pt(5.5, 12), pt(18.5, 12), p);

      case PocketIconType.chevronRight:
        final chev = Path()
          ..moveTo(9.5 * s, 6.5 * s)
          ..lineTo(15 * s, 12 * s)
          ..lineTo(9.5 * s, 17.5 * s);
        canvas.drawPath(chev, p);

      case PocketIconType.compass:
        canvas.drawCircle(pt(12, 12), 8.5 * s, p);
        final needle = Path()
          ..moveTo(15.5 * s, 8.5 * s)
          ..lineTo(13.2 * s, 13.2 * s)
          ..lineTo(8.5 * s, 15.5 * s)
          ..lineTo(10.8 * s, 10.8 * s)
          ..close();
        canvas.drawPath(needle, p);

      case PocketIconType.star:
      case PocketIconType.starFilled:
        final star = Path();
        for (int i = 0; i < 10; i++) {
          final r = i.isEven ? 8.5 * s : 3.8 * s;
          final a = -math.pi / 2 + i * math.pi / 5;
          final o = Offset(12 * s + math.cos(a) * r, 12 * s + math.sin(a) * r);
          if (i == 0) {
            star.moveTo(o.dx, o.dy);
          } else {
            star.lineTo(o.dx, o.dy);
          }
        }
        star.close();
        canvas.drawPath(
          star,
          type == PocketIconType.starFilled ? fill : p,
        );

      case PocketIconType.play:
        final tri = Path()
          ..moveTo(8 * s, 5.5 * s)
          ..lineTo(18.5 * s, 12 * s)
          ..lineTo(8 * s, 18.5 * s)
          ..close();
        canvas.drawPath(tri, fill);

      case PocketIconType.check:
        final ck = Path()
          ..moveTo(5 * s, 12.5 * s)
          ..lineTo(9.8 * s, 17.2 * s)
          ..lineTo(19 * s, 7.2 * s);
        canvas.drawPath(ck, p);

      case PocketIconType.warning:
        final tri = Path()
          ..moveTo(12 * s, 4 * s)
          ..lineTo(20 * s, 19 * s)
          ..lineTo(4 * s, 19 * s)
          ..close();
        canvas.drawPath(tri, p);
        canvas.drawLine(pt(12, 10), pt(12, 14), p);
        canvas.drawCircle(pt(12, 16.5), 1 * s, fill);

      case PocketIconType.filterPaper:
        final f = Path()
          ..moveTo(4.5 * s, 6 * s)
          ..lineTo(19.5 * s, 6 * s)
          ..lineTo(12 * s, 19 * s)
          ..close();
        canvas.drawPath(f, p);
        canvas.drawLine(pt(8, 10.5), pt(16, 10.5), p);

      case PocketIconType.backArrow:
        canvas.drawLine(pt(19, 12), pt(5.5, 12), p);
        final head = Path()
          ..moveTo(11 * s, 6.5 * s)
          ..lineTo(5.5 * s, 12 * s)
          ..lineTo(11 * s, 17.5 * s);
        canvas.drawPath(head, p);
    }
  }

  @override
  bool shouldRepaint(covariant _PocketIconPainter old) =>
      old.type != type || old.color != color || old.strokeWidth != strokeWidth;
}
