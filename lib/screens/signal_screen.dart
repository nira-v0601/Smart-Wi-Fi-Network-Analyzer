import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/providers/network_provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';

class SignalScreen extends StatefulWidget {
  const SignalScreen({super.key});

  @override
  State<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends State<SignalScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String getSignalStatus(int rssi) {
    if (rssi >= -50) return "Excellent 🟢";
    if (rssi >= -70) return "Average 🟡";
    return "Poor 🔴";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NetworkProvider>(context);
    final currentRssi = provider.currentRssi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Time Signal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondary.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: _pulseController.value * 0.8 + 0.2),
                      width: 4 + (_pulseController.value * 12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: _pulseController.value * 0.3),
                        blurRadius: 40 * _pulseController.value,
                        spreadRadius: 10 * _pulseController.value,
                      )
                    ]
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentRssi',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppTheme.secondary,
                                fontSize: 64,
                                shadows: [BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.5), blurRadius: 20)],
                              ),
                        ),
                        Text(
                          'dBm',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.secondary.withValues(alpha: 0.7),
                            letterSpacing: 2,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            const Text(
              'SIGNAL QUALITY',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Text(
                getSignalStatus(currentRssi),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
