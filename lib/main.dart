import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/providers/network_provider.dart';
import 'package:smart_wifi_analyzer/screens/main_screen.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:smart_wifi_analyzer/providers/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Smart Wi-Fi Network Analyzer',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(), // Fallback base
          darkTheme: AppTheme.darkTheme,
          home: const MainScreen(),
        );
      },
    );
  }
}
