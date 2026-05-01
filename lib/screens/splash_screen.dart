import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_wifi_analyzer/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // using Theme.of(context).colorScheme.background is deprecated, use surface
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_rounded,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .then()
            .shimmer(duration: 1000.ms, color: Colors.white54),
            const SizedBox(height: 24),
            Text(
              'Smart Wi-Fi Network Analyzer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                // fallback to onSurface if onBackground is deprecated
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 300.ms)
            .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
