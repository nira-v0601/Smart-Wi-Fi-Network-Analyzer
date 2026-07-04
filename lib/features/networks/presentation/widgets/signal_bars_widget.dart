import 'package:flutter/material.dart';
import '../../../../core/theme/signal_colors.dart';

class SignalBarsWidget extends StatelessWidget {
  final int rssi;

  const SignalBarsWidget({super.key, required this.rssi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _SignalBarsPainter(
          rssi: rssi,
          inactiveColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _SignalBarsPainter extends CustomPainter {
  final int rssi;
  final Color inactiveColor;

  _SignalBarsPainter({required this.rssi, required this.inactiveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final activeColor = SignalColors.fromRssi(rssi);

    int activeBars = 1;
    if (rssi >= -50) {
      activeBars = 4;
    } else if (rssi >= -60) {
      activeBars = 3;
    } else if (rssi >= -70) {
      activeBars = 2;
    }

    final barWidth = (size.width - 6) / 4; 
    
    for (int i = 0; i < 4; i++) {
      final isLit = i < activeBars;
      final paint = Paint()
        ..color = isLit ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;
      
      final barHeight = size.height * ((i + 1) / 4);
      final top = size.height - barHeight;
      final left = i * (barWidth + 2);
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(1),
      );
      
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalBarsPainter oldDelegate) {
    return oldDelegate.rssi != rssi || oldDelegate.inactiveColor != inactiveColor;
  }
}
