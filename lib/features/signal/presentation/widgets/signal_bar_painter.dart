import 'package:flutter/material.dart';

class SignalBarPainter extends CustomPainter {
  final int currentRssi;
  final Color labelColor;

  SignalBarPainter({required this.currentRssi, required this.labelColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final gradient = const LinearGradient(
      colors: [Colors.red, Colors.yellow, Colors.green],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);

    final paint = Paint()..shader = gradient;
    canvas.drawRRect(rrect, paint);

    // Map -100 to -30 dBm to 0.0 to 1.0
    double percent = (currentRssi - (-100)) / (-30 - (-100));
    percent = percent.clamp(0.0, 1.0);
    
    final xPos = size.width * percent;
    final indicatorPaint = Paint()
      ..color = labelColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(xPos, -4),
      Offset(xPos, size.height + 4),
      indicatorPaint,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$currentRssi',
        style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    double textX = xPos - textPainter.width / 2;
    textX = textX.clamp(0.0, size.width - textPainter.width);
    
    textPainter.paint(canvas, Offset(textX, -16));
  }

  @override
  bool shouldRepaint(covariant SignalBarPainter oldDelegate) {
    return oldDelegate.currentRssi != currentRssi || oldDelegate.labelColor != labelColor;
  }
}
