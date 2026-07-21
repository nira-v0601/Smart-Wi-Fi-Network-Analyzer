import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../../speedtest/data/models/speed_result_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
          style: GoogleFonts.rajdhani(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        children: [
          _buildSectionHeader(theme, 'APPEARANCE'),
          _buildCard(
            theme: theme,
            child: ListTile(
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
                      color: theme.scaffoldBackgroundColor,
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
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'SPEED TEST'),
          _buildCard(
            theme: theme,
            child: ListTile(
              leading: Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
              title: Text('Test History', style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('View past speed test results', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpeedTestHistoryScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'NETWORK'),
          _buildCard(
            theme: theme,
            child: ListTile(
              leading: Icon(Icons.wifi_find, color: theme.colorScheme.onSurfaceVariant),
              title: Text('Advanced Network Details', style: TextStyle(color: theme.colorScheme.onSurface)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdvancedNetworkScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'ABOUT'),
          _buildCard(
            theme: theme,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
                  title: Text('App Version', style: TextStyle(color: theme.colorScheme.onSurface)),
                  trailing: Text(
                    'v1.0.0',
                    style: GoogleFonts.rajdhani(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(100)),
                ListTile(
                  leading: Icon(Icons.code, color: theme.colorScheme.onSurfaceVariant),
                  title: Text('Built With', style: TextStyle(color: theme.colorScheme.onSurface)),
                  trailing: Text('Flutter + Gemini', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(100)),
                ListTile(
                  leading: Icon(Icons.developer_mode, color: theme.colorScheme.onSurfaceVariant),
                  title: Text('Developer', style: TextStyle(color: theme.colorScheme.onSurface)),
                  subtitle: Text('GTU BE IT Student', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
      ),
    );
  }

  Widget _buildCard({required ThemeData theme, required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: child,
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

  Future<void> _deleteResult(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _history.removeAt(index);
      });
      final historyList = _history.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('speed_test_history', historyList);
    } catch (_) {
      // Ignore delete errors
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
                    return Dismissible(
                      key: Key(item.testedAt.toIso8601String()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        color: Colors.red.shade800,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteResult(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Test result deleted'),
                            backgroundColor: theme.colorScheme.surface,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpeedTestDetailsScreen(result: item),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
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
                          ),
                        ),
                      ),
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
                const SizedBox(height: 32),
                
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

class SpeedTestDetailsScreen extends StatelessWidget {
  final SpeedResultModel result;

  const SpeedTestDetailsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(result.testedAt);
    final info = result.networkInfo;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Speed Test Details',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(theme, 'TEST RESULTS'),
          _buildRow(context, 'Date', dateStr),
          _buildRow(context, 'Download Speed', '${result.downloadMbps.toStringAsFixed(2)} Mbps'),
          _buildRow(context, 'Upload Speed', '${result.uploadMbps.toStringAsFixed(2)} Mbps'),
          _buildRow(context, 'Ping', '${result.pingMs} ms'),
          _buildRow(context, 'Jitter', '${result.jitterMs} ms'),
          _buildRow(context, 'Packet Loss', '${result.packetLossPercent.toStringAsFixed(1)}%'),
          const SizedBox(height: 32),
          
          if (info != null) ...[
            _buildSectionHeader(theme, 'NETWORK DETAILS'),
            _buildRow(context, 'SSID', info.ssid),
            _buildRow(context, 'BSSID', info.bssid),
            _buildRow(context, 'Frequency', info.frequency),
            _buildRow(context, 'Band', info.band),
            _buildRow(context, 'Security', info.securityType),
            _buildRow(context, 'Wi-Fi Version', info.wifiVersion),
            const SizedBox(height: 32),
            
            _buildSectionHeader(theme, 'IP & GATEWAY'),
            _buildRow(context, 'Local IP', info.localIp),
            _buildRow(context, 'Public IP', info.publicIp),
            _buildRow(context, 'Subnet Mask', info.subnet ?? 'Unknown'),
            _buildRow(context, 'Gateway', info.gateway ?? 'Unknown'),
            _buildRow(context, 'IP Version', info.ipVersion ?? 'Unknown'),
            const SizedBox(height: 32),

            _buildSectionHeader(theme, 'ISP INFO'),
            _buildRow(context, 'ISP Name', info.ispName),
            _buildRow(context, 'ISP Organization', info.ispOrg),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No network details saved for this test.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
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
