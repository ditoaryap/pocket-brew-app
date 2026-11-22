import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/pocket_tokens.dart';

enum PourDemoType {
  spiral,
  centerOsmotic,
  raoSpin;

  String get title => switch (this) {
        spiral => 'Pola Spiral V60',
        centerOsmotic => 'Center / Osmotic',
        raoSpin => 'Rao Spin (Swirl)',
      };

  String get caption => switch (this) {
        spiral =>
          'Mulai dari titik tengah lalu melingkar tenang tanpa mengenai dinding kertas filter.',
        centerOsmotic =>
          'Tuang tipis tepat di pusat kubah kopi untuk body tebal & rendah pahit.',
        raoSpin =>
          'Putar dripper lembut 1–2 kali setelah tuangan agar bubuk di dinding turun rata.',
      };
}

/// Animated top-down V60 pouring diagram (pure Flutter Canvas — 60/120fps & Shorebird safe).
class SpiralPourDiagram extends StatefulWidget {
  const SpiralPourDiagram({
    super.key,
    required this.type,
    required this.isPlaying,
  });

  final PourDemoType type;
  final bool isPlaying;

  @override
  State<SpiralPourDiagram> createState() => _SpiralPourDiagramState();
}

class _SpiralPourDiagramState extends State<SpiralPourDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant SpiralPourDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(124, 124),
          painter: _PourDiagramPainter(
            type: widget.type,
            t: _ctrl.value,
            accent: c.brandTerracotta,
            sage: c.brandSage,
            honey: c.brandHoney,
          ),
        );
      },
    );
  }
}

class _PourDiagramPainter extends CustomPainter {
  const _PourDiagramPainter({
    required this.type,
    required this.t,
    required this.accent,
    required this.sage,
    required this.honey,
  });

  final PourDemoType type;
  final double t;
  final Color accent;
  final Color sage;
  final Color honey;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 4;

    // Dripper rim & coffee bed
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      r - 8,
      Paint()..color = const Color(0xFF3A2A20),
    );
    // Avoid-wall dashed warning guide
    canvas.drawCircle(
      center,
      r - 12,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (type == PourDemoType.spiral) {
      final path = Path();
      const turns = 2.6;
      const steps = 90;
      Offset dotPos = center;
      final activeStep = (t * steps).round();
      for (int i = 0; i <= steps; i++) {
        final frac = i / steps;
        final angle = frac * turns * 2 * math.pi;
        final radius = frac * (r - 18);
        final pt = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
        if (i == activeStep) dotPos = pt;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(dotPos, 5.5, Paint()..color = const Color(0xFFF5E9D2));
      canvas.drawCircle(dotPos, 3.0, Paint()..color = accent);
    } else if (type == PourDemoType.centerOsmotic) {
      final pulseR = 10 + math.sin(t * 2 * math.pi) * 6;
      canvas.drawCircle(
        center,
        pulseR + 10,
        Paint()
          ..color = honey.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        pulseR,
        Paint()
          ..color = honey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFF5E9D2));
    } else {
      // Rao Spin circular swirl arrow around perimeter
      final start = t * 2 * math.pi;
      final rect = Rect.fromCircle(center: center, radius: r - 18);
      canvas.drawArc(
        rect,
        start,
        math.pi * 1.2,
        false,
        Paint()
          ..color = sage
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      final tipAngle = start + math.pi * 1.2;
      final tip = Offset(
        center.dx + math.cos(tipAngle) * (r - 18),
        center.dy + math.sin(tipAngle) * (r - 18),
      );
      canvas.drawCircle(tip, 5, Paint()..color = const Color(0xFFE1EDE5));
    }
  }

  @override
  bool shouldRepaint(covariant _PourDiagramPainter old) =>
      old.t != t || old.type != type;
}
