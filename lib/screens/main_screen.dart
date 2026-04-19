import 'package:flutter/material.dart';
import 'package:smart_wifi_analyzer/screens/dashboard_screen.dart';
import 'package:smart_wifi_analyzer/screens/signal_screen.dart';
import 'package:smart_wifi_analyzer/screens/networks_screen.dart';
import 'package:smart_wifi_analyzer/screens/speed_test_screen.dart';
import 'package:smart_wifi_analyzer/screens/settings_screen.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SignalScreen(),
    const NetworksScreen(),
    const SpeedTestScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow.withOpacity(0.9),
          border: Border(top: BorderSide(color: AppTheme.primary.withOpacity(0.1))),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.5),
               blurRadius: 50,
               offset: const Offset(0, -10),
             ),
          ]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppTheme.secondary,
            unselectedItemColor: AppTheme.onSurfaceVariant.withOpacity(0.7),
            showUnselectedLabels: true,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wifi_tethering),
                label: 'Signal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.hub),
                label: 'Networks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.speed),
                label: 'Speed Test',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.radar, color: Colors.white),
      ) : null,
    );
  }
}
