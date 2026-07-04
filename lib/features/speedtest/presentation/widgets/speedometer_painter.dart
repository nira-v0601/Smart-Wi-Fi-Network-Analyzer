import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeedometerPainter extends CustomPainter {
  final double percent;
  final Color activeColor;
  final bool useGradient;
  final Color backgroundColor;

  SpeedometerPainter({
    required this.percent,
    required this.activeColor,
    required this.backgroundColor,
    this.useGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 15.0; // padding for glow

    final startAngle = math.pi * 3 / 4;
    final sweepAngle = math.pi * 3 / 2;

    // Draw background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (percent <= 0) return;

    // Draw foreground arc
    final fgPaint = Paint()
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (useGradient) {
      fgPaint.shader = const SweepGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF00FF88)],
        stops: [0.0, 1.0],
        startAngle: math.pi * 3 / 4,
        endAngle: math.pi * 3 / 4 + math.pi * 3 / 2,
        transform: GradientRotation(0),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      fgPaint.color = activeColor;
    }

    final activeSweep = sweepAngle * percent.clamp(0.0, 1.0);

    // Draw glow
    final glowPaint = Paint()
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = (useGradient ? const Color(0xFF00E5FF) : activeColor).withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      glowPaint,
    );

    // Draw actual arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.percent != percent ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.useGradient != useGradient;
  }
}
