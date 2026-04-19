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
                    border: Border.all(
                      color: AppTheme.secondary.withOpacity(_pulseController.value * 0.5 + 0.1),
                      width: 10 + (_pulseController.value * 20),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$currentRssi\ndBm',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.secondary,
                            fontSize: 48,
                          ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            const Text(
              'Signal Quality',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              getSignalStatus(currentRssi),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
