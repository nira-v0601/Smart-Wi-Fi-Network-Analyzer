import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:smart_wifi_analyzer/providers/theme_provider.dart';

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
                leading: const Icon(Icons.dark_mode, color: AppTheme.primary),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  activeTrackColor: AppTheme.secondary,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history, color: AppTheme.primary),
                title: const Text('Signal History'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info, color: AppTheme.tertiary),
                title: const Text('View Network Info'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.system_update, color: AppTheme.tertiary),
                title: const Text('App Version'),
                trailing: Text(appVersion, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
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
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
        )
      ],
    );
  }
}
