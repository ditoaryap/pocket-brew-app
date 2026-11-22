import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/pocket_tokens.dart';
import '../../../domain/models/enums.dart';

enum PourDemoType {
  spiral,
  center,
  pulse,
  osmotic,
  raoSpin;

  static PourDemoType fromPattern(PourPattern pattern) => switch (pattern) {
        PourPattern.spiral => PourDemoType.spiral,
        PourPattern.center => PourDemoType.center,
        PourPattern.pulse => PourDemoType.pulse,
        PourPattern.osmotic => PourDemoType.osmotic,
        PourPattern.swirl => PourDemoType.raoSpin,
      };

  PourPattern get pattern => switch (this) {
        spiral => PourPattern.spiral,
        center => PourPattern.center,
        pulse => PourPattern.pulse,
        osmotic => PourPattern.osmotic,
        raoSpin => PourPattern.swirl,
      };

  String get shortLabel => switch (this) {
        spiral => 'Spiral',
        center => 'Center',
        pulse => 'Pulse',
        osmotic => 'Osmotic',
        raoSpin => 'Swirl',
      };

  String get title => switch (this) {
        spiral => 'Pola Spiral (Melingkar Merata)',
        center => 'Center Pour (Tuang Tengah)',
        pulse => 'Pulse Pour (Tuang Bertahap)',
        osmotic => 'Osmotic Flow (Kubah Kopi)',
        raoSpin => 'Swirl / Rao Spin (Goyang Ringan)',
      };

  String get paceBadge => switch (this) {
        spiral => 'Sedang · ~50–60 ml / 10 dtk',
        center => 'Stabil · ~40–50 ml / 10 dtk',
        pulse => 'Bertahap · 3–5x tuang + jeda',
        osmotic => 'Sangat Pelan · ~25–35 ml / 10 dtk',
        raoSpin => '1–2x putaran halus',
      };

  String get caption => switch (this) {
        spiral =>
          'Mulai dari titik tengah lalu melingkar tenang ke arah luar (maks. 80% radius), lalu kembali ke tengah tanpa menyiram dinding kertas.',
        center =>
          'Aliran air vertikal tipis & konsisten tepat di titik tengah bubuk kopi untuk agitasi lembut dan suhu seduhan stabil.',
        pulse =>
          'Tuang air dalam beberapa gelombang kecil dengan jeda 10–25 detik antar tuangan agar air turun dulu sebelum gelombang berikutnya.',
        osmotic =>
          'Teteskan atau tuang super pelan di tengah seukuran koin agar kubah (dome) kopi tetap utuh — air mengekstrak secara osmosis alami.',
        raoSpin =>
          'Angkat sedikit atau pegang bibir dripper lalu putar lembut 1–2 kali searah jarum jam tepat setelah tuangan selesai.',
      };

  List<String> get howToSteps => switch (this) {
        spiral => const [
            'Posisikan ujung kettle 3–5 cm di atas permukaan air agar aliran tidak memercik.',
            'Mulai tuang di pusat bubuk, gerakkan melingkar pelan keluar hingga ±1 cm sebelum dinding kertas.',
            'Putar balik ke arah tengah dengan kecepatan aliran stabil sampai target gram tercapai.',
          ],
        center => const [
            'Arahkan aliran air tegak lurus tepat di titik tengah permukaan kopi.',
            'Jaga tinggi kettle rendah (3–4 cm) agar aliran halus tanpa menimbulkan banyak gelembung.',
            'Pertahankan tinggi permukaan air tetap stabil hingga mencapai target volume tahap.',
          ],
        pulse => const [
            'Bagi total air menjadi 3–5 tahapan kecil (misalnya per 45–60 ml).',
            'Tuang satu tahap dengan pola spiral lembut, lalu hentikan aliran sejenak.',
            'Tunggu permukaan air turun setengah (10–25 dtk) baru lanjut ke gelombang tuangan berikutnya.',
          ],
        osmotic => const [
            'Gunakan suhu air lebih rendah (83–88°C) dan gilingan agak kasar untuk medium–dark roast.',
            'Basahi tengah kopi perlahan saat bloom sampai terbentuk gundukan kubah kopi.',
            'Tuang sangat pelan hanya di area tengah seukuran koin tanpa meruntuhkan dinding kubah.',
          ],
        raoSpin => const [
            'Begitu aliran air berhenti di tahap bloom atau tuangan terakhir, pegang bagian luar dripper.',
            'Putar dripper dengan gerakan melingkar lembut 1–2 putaran penuh.',
            'Biarkan air menetes turun alami hingga ampas kopi di dasar terlihat datar rata.',
          ],
      };

  String get tasteEffect => switch (this) {
        spiral => 'Rasa paling seimbang, manis jernih, dan ekstraksi merata.',
        center =>
            'Tekstur bersih (clean), asam lembut, risiko pahit rendah.',
        pulse =>
            'Rasa lebih manis, kompleks, dan body lebih terasa (khas metode 4:6 & Hoffmann).',
        osmotic =>
            'Body tebal, manis pekat, dan sangat rendah pahit/sepat.',
        raoSpin =>
            'Mencegah jalur bocor (channeling) sehingga rasa lebih konsisten & manis bersih.',
      };

  String get bestFor => switch (this) {
        spiral => 'Bloom & tuangan utama harian (Light hingga Medium roast).',
        center =>
            'Tahap finishing atau saat ingin menjaga kestabilan aliran di V60.',
        pulse => 'Metode 4:6 Kasuya, Hoffmann 1-Cup, atau biji Light Roast floral.',
        osmotic => 'Medium-Dark / Dark roast atau biji yang mudah terasa pahit.',
        raoSpin => 'Tepat setelah Bloom & tepat setelah tuangan terakhir.',
      };

  String get watchOut => switch (this) {
        spiral =>
            'Jangan menyiram langsung dinding kertas filter agar air tidak lolos tanpa mengekstrak kopi (bypass).',
        center =>
            'Hindari menuang terlalu tinggi atau deras karena bisa menggali lubang di tengah bubuk.',
        pulse =>
            'Jangan biarkan ampas kopi benar-benar kering terlalu lama antar jeda agar suhu tidak turun drastis.',
        osmotic =>
            'Jangan menuang terlalu cepat — jika kubah kopi pecah, ekstraksi pahit bisa ikut larut.',
        raoSpin =>
            'Jangan diputar terlalu kencang karena bubuk halus (fines) bisa menempel di kertas dan bikin air mampet.',
      };
}

/// Smooth 60fps looping animated top-down pour-over motion graphic covering all 5 pour techniques.
/// 100% offline pure Flutter Canvas (zero external video assets, instant load).
class SpiralPourDiagram extends StatefulWidget {
  const SpiralPourDiagram({
    super.key,
    required this.type,
    required this.isPlaying,
    this.size = 152,
  });

  final PourDemoType type;
  final bool isPlaying;
  final double size;

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
      duration: const Duration(milliseconds: 4200),
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _PourDiagramPainter(
              type: widget.type,
              t: _ctrl.value,
              accent: c.brandTerracotta,
              sage: c.brandSage,
              honey: c.brandHoney,
              ice: c.brandIce,
            ),
          );
        },
      ),
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
    required this.ice,
  });

  final PourDemoType type;
  final double t;
  final Color accent;
  final Color sage;
  final Color honey;
  final Color ice;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2 - 4;
    final bedR = outerR - 11;

    // Slight gentle swirl wobble on the dripper itself when demonstrating Rao Spin
    canvas.save();
    if (type == PourDemoType.raoSpin) {
      final spinAngle = t * 2 * math.pi * 2;
      final orbitOffset = Offset(
        math.cos(spinAngle) * 3.2,
        math.sin(spinAngle) * 3.2,
      );
      canvas.translate(orbitOffset.dx, orbitOffset.dy);
    }

    // 1. V60 outer ceramic rim
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Subtle V60 spiral ribs inside rim
    for (int i = 0; i < 12; i++) {
      final a = (i / 12.0) * 2 * math.pi;
      final p1 = Offset(
        center.dx + math.cos(a) * (bedR + 1),
        center.dy + math.sin(a) * (bedR + 1),
      );
      final p2 = Offset(
        center.dx + math.cos(a + 0.14) * (outerR - 1.5),
        center.dy + math.sin(a + 0.14) * (outerR - 1.5),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 2. Coffee bed rich radial gradient
    canvas.drawCircle(
      center,
      bedR,
      Paint()
        ..shader = RadialGradient(
          colors: type == PourDemoType.osmotic
              ? const [Color(0xFF5A3B27), Color(0xFF332117), Color(0xFF231710)]
              : const [Color(0xFF4C3323), Color(0xFF2D1E15)],
        ).createShader(Rect.fromCircle(center: center, radius: bedR)),
    );

    // Subtle ground coffee texture dots
    for (int i = 0; i < 18; i++) {
      final a = i * 2.399; // golden angle distribution
      final rr = math.sqrt((i + 1) / 19.0) * (bedR - 6);
      canvas.drawCircle(
        Offset(center.dx + math.cos(a) * rr, center.dy + math.sin(a) * rr),
        1.2,
        Paint()..color = const Color(0xFF7D5840).withValues(alpha: 0.28),
      );
    }

    // 3. Avoid-filter-wall dashed guide ring
    const dashCount = 28;
    final safeR = bedR - 6;
    for (int i = 0; i < dashCount; i += 2) {
      final a0 = (i / dashCount) * 2 * math.pi;
      final a1 = ((i + 0.8) / dashCount) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: safeR),
        a0,
        a1 - a0,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // 4. Technique-specific animated water trajectory & kettle stream
    switch (type) {
      case PourDemoType.spiral:
        _paintSpiral(canvas, center, safeR - 5);
      case PourDemoType.center:
        _paintCenter(canvas, center, safeR - 5);
      case PourDemoType.pulse:
        _paintPulse(canvas, center, safeR - 5);
      case PourDemoType.osmotic:
        _paintOsmotic(canvas, center, safeR - 5);
      case PourDemoType.raoSpin:
        _paintRaoSpin(canvas, center, safeR - 5);
    }

    canvas.restore();
  }

  void _paintKettleStream(Canvas canvas, Offset nozzleTarget, Color streamColor) {
    // Soft glowing water landing splash
    canvas.drawCircle(
      nozzleTarget,
      9.5,
      Paint()..color = streamColor.withValues(alpha: 0.24),
    );
    canvas.drawCircle(
      nozzleTarget,
      5.2,
      Paint()..color = const Color(0xFFFFF4E4),
    );
    canvas.drawCircle(
      nozzleTarget,
      2.7,
      Paint()..color = streamColor,
    );
  }

  void _paintSpiral(Canvas canvas, Offset center, double maxR) {
    // Smooth outward (0..0.5) and inward (0.5..1.0) spiral path
    final path = Path();
    const turns = 2.6;
    const steps = 100;
    final pingPongT = t <= 0.5 ? (t * 2.0) : ((1.0 - t) * 2.0);
    final activeStep = (pingPongT * steps).round();
    Offset dotPos = center;

    for (int i = 0; i <= steps; i++) {
      final frac = i / steps;
      final angle = frac * turns * 2 * math.pi - math.pi / 2;
      final radius = frac * maxR;
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
        ..color = accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Active lit trail
    final activePath = Path();
    for (int i = 0; i <= activeStep; i++) {
      final frac = i / steps;
      final angle = frac * turns * 2 * math.pi - math.pi / 2;
      final radius = frac * maxR;
      final pt = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        activePath.moveTo(pt.dx, pt.dy);
      } else {
        activePath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(
      activePath,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    _paintKettleStream(canvas, dotPos, accent);
  }

  void _paintCenter(Canvas canvas, Offset center, double maxR) {
    // 3 calm concentric water ripples expanding steadily from exact center
    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3.0) % 1.0;
      final rr = 6 + phase * (maxR * 0.85);
      final alpha = (1.0 - phase) * 0.65;
      canvas.drawCircle(
        center,
        rr,
        Paint()
          ..color = ice.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
    // Calm central target ring
    canvas.drawCircle(
      center,
      14,
      Paint()..color = ice.withValues(alpha: 0.16),
    );
    _paintKettleStream(canvas, center, ice);
  }

  void _paintPulse(Canvas canvas, Offset center, double maxR) {
    // 2 cycles per loop: Pouring phase (0..0.55) vs Rest/Drawdown phase (0.55..1.0)
    final cycle = (t * 2.0) % 1.0;
    final isPouring = cycle < 0.55;
    final phaseT = isPouring ? (cycle / 0.55) : ((cycle - 0.55) / 0.45);

    // Rising & falling water bed indicator
    final waterR = isPouring
        ? maxR * (0.45 + 0.48 * phaseT)
        : maxR * (0.93 - 0.48 * phaseT);
    canvas.drawCircle(
      center,
      waterR,
      Paint()
        ..color = (isPouring ? accent : sage).withValues(alpha: 0.20),
    );
    canvas.drawCircle(
      center,
      waterR,
      Paint()
        ..color = (isPouring ? accent : sage).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    if (isPouring) {
      // Gentle small spiral while pouring
      final angle = phaseT * 2.5 * math.pi;
      final r = maxR * 0.36 * phaseT;
      final pt = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      _paintKettleStream(canvas, pt, accent);
    } else {
      // Resting pause ring at center (kettle lifted)
      canvas.drawCircle(
        center,
        7 + (1.0 - phaseT) * 6,
        Paint()
          ..color = sage.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _paintOsmotic(Canvas canvas, Offset center, double maxR) {
    // Intact dark outer dome ring (never disturbed)
    canvas.drawCircle(
      center,
      maxR * 0.78,
      Paint()
        ..color = const Color(0xFF8B6247).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    // Gentle coin-sized center osmotic pulse
    final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final coinR = 11.0 + breathe * 6.0;
    canvas.drawCircle(
      center,
      coinR + 8,
      Paint()..color = honey.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      coinR,
      Paint()
        ..color = honey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Tiny ultra-slow micro-circle inside coin center
    final a = t * 2 * math.pi;
    final pt = Offset(
      center.dx + math.cos(a) * 4.5,
      center.dy + math.sin(a) * 4.5,
    );
    _paintKettleStream(canvas, pt, honey);
  }

  void _paintRaoSpin(Canvas canvas, Offset center, double maxR) {
    // Two smooth rotating swirl vortex arcs around the slurry
    final baseAngle = t * 2 * math.pi * 2;
    final outerRect = Rect.fromCircle(center: center, radius: maxR * 0.82);
    final innerRect = Rect.fromCircle(center: center, radius: maxR * 0.45);

    canvas.drawArc(
      outerRect,
      baseAngle,
      math.pi * 1.15,
      false,
      Paint()
        ..color = sage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      innerRect,
      baseAngle + math.pi * 0.7,
      math.pi * 0.95,
      false,
      Paint()
        ..color = sage.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Directional arrowhead dot at leading edge of outer swirl
    final tipA = baseAngle + math.pi * 1.15;
    final tip = Offset(
      center.dx + math.cos(tipA) * (maxR * 0.82),
      center.dy + math.sin(tipA) * (maxR * 0.82),
    );
    canvas.drawCircle(tip, 6.0, Paint()..color = const Color(0xFFE1EDE5));
    canvas.drawCircle(tip, 3.0, Paint()..color = sage);
  }

  @override
  bool shouldRepaint(covariant _PourDiagramPainter old) =>
      old.t != t || old.type != type;
}
