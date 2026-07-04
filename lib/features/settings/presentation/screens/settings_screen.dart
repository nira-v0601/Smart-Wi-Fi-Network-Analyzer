import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../../speedtest/data/models/speed_result_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        children: [
          _buildSectionHeader(theme, 'APPEARANCE'),
          ListTile(
            leading: Icon(Icons.palette, color: theme.colorScheme.onSurfaceVariant),
            title: Text('Dark Mode', style: TextStyle(color: theme.colorScheme.onSurface)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App theme', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDark ? 'Dark mode is ON' : 'Light mode is ON',
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                ref.read(themeNotifierProvider.notifier).toggleTheme(val);
              },
              activeTrackColor: theme.colorScheme.primary.withAlpha(100),
              activeThumbColor: theme.colorScheme.primary.withAlpha(150),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'SPEED TEST'),
          ListTile(
            leading: Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
            title: Text('Test History', style: TextStyle(color: theme.colorScheme.onSurface)),
            subtitle: Text('View past speed test results', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpeedTestHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'NETWORK'),
          ListTile(
            leading: Icon(Icons.wifi_find, color: theme.colorScheme.onSurfaceVariant),
            title: Text('Advanced Network Details', style: TextStyle(color: theme.colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdvancedNetworkScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'ABOUT'),
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
            title: Text('App Version', style: TextStyle(color: theme.colorScheme.onSurface)),
            trailing: Text(
              'v1.0.0',
              style: GoogleFonts.rajdhani(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.code, color: theme.colorScheme.onSurfaceVariant),
            title: Text('Built With', style: TextStyle(color: theme.colorScheme.onSurface)),
            trailing: Text('Flutter + Gemini', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.developer_mode, color: theme.colorScheme.onSurfaceVariant),
            title: Text('Developer', style: TextStyle(color: theme.colorScheme.onSurface)),
            subtitle: Text('GTU BE IT Student', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.rajdhani(
            color: theme.colorScheme.primary,
            fontSize: 13,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: theme.colorScheme.outline, thickness: 1),
        const SizedBox(height: 8),
      ],
    );
  }
}

class SpeedTestHistoryScreen extends StatefulWidget {
  const SpeedTestHistoryScreen({super.key});

  @override
  State<SpeedTestHistoryScreen> createState() => _SpeedTestHistoryScreenState();
}

class _SpeedTestHistoryScreenState extends State<SpeedTestHistoryScreen> {
  List<SpeedResultModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('speed_test_history') ?? [];
      final parsed = historyList.map((e) => SpeedResultModel.fromJson(jsonDecode(e))).toList();
      setState(() {
        _history = parsed;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Speed Test History',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _history.isEmpty
              ? Center(
                  child: Text(
                    'No test history yet',
                    style: GoogleFonts.rajdhani(fontSize: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _history.length,
                  separatorBuilder: (context, index) => Divider(color: theme.colorScheme.outline, height: 24),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(item.testedAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStat(context, '↓', item.downloadMbps, const Color(0xFF00E5FF)),
                            _buildStat(context, '↑', item.uploadMbps, const Color(0xFF00FF88)),
                            _buildStat(context, 'Ping', item.pingMs.toDouble(), const Color(0xFFFFD600), isPing: true),
                          ],
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildStat(BuildContext context, String icon, double value, Color color, {bool isPing = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          icon,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          isPing ? value.toInt().toString() : value.toStringAsFixed(1),
          style: GoogleFonts.rajdhani(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isPing ? 'ms' : 'Mbps',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class AdvancedNetworkScreen extends ConsumerWidget {
  const AdvancedNetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final info = dashboardState.networkInfo;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Advanced Details',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: info == null
          ? Center(
              child: Text(
                'No network information available',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader(theme, 'CONNECTION'),
                _buildRow(context, 'SSID', info.ssid),
                _buildRow(context, 'BSSID', info.bssid),
                _buildRow(context, 'Frequency', info.frequency),
                _buildRow(context, 'Band', info.band),
                _buildRow(context, 'Security', info.securityType),
                _buildRow(context, 'Wi-Fi Version', info.wifiVersion),
                const SizedBox(height: 24),
                
                _buildSectionHeader(theme, 'IP & NETWORK'),
                _buildRow(context, 'Local IP', info.localIp),
                _buildRow(context, 'Public IP', info.publicIp),
                _buildRow(context, 'Subnet Mask', info.subnet ?? 'Unknown'),
                _buildRow(context, 'Gateway', info.gateway ?? 'Unknown'),
                _buildRow(context, 'IP Version', info.ipVersion ?? 'Unknown'),
                const SizedBox(height: 24),

                _buildSectionHeader(theme, 'ISP INFO'),
                _buildRow(context, 'ISP Name', info.ispName),
                _buildRow(context, 'ISP Organization', info.ispOrg),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.rajdhani(
            color: theme.colorScheme.primary,
            fontSize: 13,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: theme.colorScheme.outline, thickness: 1),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
