import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/pocket_theme.dart';
import '../../../app/theme/pocket_tokens.dart';
import '../../motion/pocket_motion.dart';

/// 1:1 FigCraft v7 Dual-Phase Concentric Timer Dial:
/// - Smoothly animates colors between Ready, Pouring (Terracotta), Wait/Swirl (Sage), and Japanese Iced Finish (Glacier Ice).
/// - Renders continuous 60/120fps overall + phase arcs and gentle breathing pulse during 3-2-1 pre-cue.
class DualPhaseTimerRing extends StatelessWidget {
  const DualPhaseTimerRing({
    super.key,
    required this.timeText,
    required this.statusLabel,
    required this.subtitleText,
    this.captionText,
    required this.overallProgress,
    required this.phaseProgress,
    required this.ringColor,
    required this.secondaryArcColor,
    required this.haloColor,
    this.statusTextColor,
    this.subtitleColor,
    this.isPreCuePulse = false,
    this.size = 232,
  });

  final String timeText;
  final String statusLabel;
  final String subtitleText;
  final String? captionText;
  final double overallProgress;
  final double phaseProgress;
  final Color ringColor;
  final Color secondaryArcColor;
  final Color haloColor;
  final Color? statusTextColor;
  final Color? subtitleColor;
  final bool isPreCuePulse;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: ringColor),
      duration: const Duration(milliseconds: 420),
      curve: PocketCurves.smoothOut,
      builder: (context, animRing, _) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: haloColor),
          duration: const Duration(milliseconds: 420),
          curve: PocketCurves.smoothOut,
          builder: (context, animHalo, _) {
            final rc = animRing ?? ringColor;
            final hc = animHalo ?? haloColor;
            return AnimatedScale(
              scale: isPreCuePulse ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: PocketCurves.gentleSpring,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(size),
                      painter: _TimerRingPainter(
                        overallProgress: overallProgress.clamp(0.0, 1.0),
                        phaseProgress: phaseProgress.clamp(0.0, 1.0),
                        ringColor: rc,
                        secondaryArcColor: secondaryArcColor,
                        trackColor: c.borderSubtle,
                        haloColor: hc,
                        centerBg: c.surfaceCard,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: size * 0.13),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: hc,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                statusLabel,
                                style: PocketTheme.ui(
                                  size: 12.5,
                                  weight: 800,
                                  color: statusTextColor ?? rc,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              timeText,
                              style: PocketTheme.mono(
                                size: timeText.length <= 2 ? 54 : 46,
                                weight: FontWeight.w800,
                                color: c.textPrimary,
                                letterSpacing: -1.4,
                                height: 1.04,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              subtitleText,
                              style: PocketTheme.mono(
                                size: 14,
                                weight: FontWeight.w800,
                                color: subtitleColor ?? rc,
                              ),
                            ),
                          ),
                          if (captionText != null &&
                              captionText!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                captionText!,
                                style: PocketTheme.ui(
                                  size: 11.5,
                                  weight: 700,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.overallProgress,
    required this.phaseProgress,
    required this.ringColor,
    required this.secondaryArcColor,
    required this.trackColor,
    required this.haloColor,
    required this.centerBg,
  });

  final double overallProgress;
  final double phaseProgress;
  final Color ringColor;
  final Color secondaryArcColor;
  final Color trackColor;
  final Color haloColor;
  final Color centerBg;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2 - 6;

    // Soft outer breathing halo ring
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = haloColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );

    // Center ceramic surface disk
    canvas.drawCircle(
      center,
      outerR - 16,
      Paint()..color = centerBg,
    );

    // Subtle track
    final arcR = outerR - 12;
    final arcRect = Rect.fromCircle(center: center, radius: arcR);
    canvas.drawCircle(
      center,
      arcR,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.5,
    );

    // Secondary overall progress arc
    if (overallProgress > 0.002) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * overallProgress,
        false,
        Paint()
          ..color = secondaryArcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Active phase sweep highlight arc
    if (phaseProgress > 0.002) {
      final startA = -math.pi / 2 + 2 * math.pi * (overallProgress * 0.35);
      canvas.drawArc(
        arcRect,
        startA,
        2 * math.pi * (phaseProgress * 0.48).clamp(0.06, 0.92),
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.overallProgress != overallProgress ||
      old.phaseProgress != phaseProgress ||
      old.ringColor != ringColor ||
      old.secondaryArcColor != secondaryArcColor ||
      old.trackColor != trackColor ||
      old.centerBg != centerBg ||
      old.haloColor != haloColor;
}
