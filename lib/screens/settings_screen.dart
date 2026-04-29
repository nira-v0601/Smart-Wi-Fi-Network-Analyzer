import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:smart_wifi_analyzer/providers/theme_provider.dart';
import 'package:smart_wifi_analyzer/screens/network_info_screen.dart';
import 'package:smart_wifi_analyzer/screens/speed_test_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final defaultInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = '${defaultInfo.version} (${defaultInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        appVersion = '1.0.0 (1)'; // Default if error mostly for tests
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsGroup(
            'General',
            [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.dark_mode, color: AppTheme.primary),
                ),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  activeThumbColor: AppTheme.primary,
                  activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.history, color: AppTheme.primary),
                ),
                title: const Text('Speed Test History', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpeedTestHistoryScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            'About',
            [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.info, color: AppTheme.tertiary),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NetworkInfoScreen()),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.system_update, color: AppTheme.tertiary),
                ),
                title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(appVersion, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            children: items,
          ),
        )
      ],
    );
  }
}
