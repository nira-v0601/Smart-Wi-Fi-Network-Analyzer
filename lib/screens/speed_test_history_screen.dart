import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SpeedTestHistoryScreen extends StatefulWidget {
  const SpeedTestHistoryScreen({super.key});

  @override
  State<SpeedTestHistoryScreen> createState() => _SpeedTestHistoryScreenState();
}

class _SpeedTestHistoryScreenState extends State<SpeedTestHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> rawHistory = prefs.getStringList('speed_test_history') ?? [];
      
      List<Map<String, dynamic>> parsedHistory = [];
      for (var item in rawHistory) {
        parsedHistory.add(json.decode(item) as Map<String, dynamic>);
      }
      
      // Sort newest first
      parsedHistory.sort((a, b) {
        DateTime dtA = DateTime.parse(a['timestamp']);
        DateTime dtB = DateTime.parse(b['timestamp']);
        return dtB.compareTo(dtA);
      });

      if (mounted) {
        setState(() {
          _history = parsedHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Test History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    'No history available',
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final dt = DateTime.tryParse(item['timestamp'] ?? '');
                    final dateStr = dt != null ? DateFormat('MMM d, yyyy • h:mm a').format(dt) : 'Unknown Date';
                    final ping = item['ping']?.toStringAsFixed(0) ?? '--';
                    final dl = item['download']?.toStringAsFixed(1) ?? '--';
                    final ul = item['upload']?.toStringAsFixed(1) ?? '--';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetric(Icons.network_ping, 'PING', '$ping ms', AppTheme.primary),
                              _buildMetric(Icons.download, 'DOWN', '$dl Mbps', AppTheme.secondary),
                              _buildMetric(Icons.upload, 'UP', '$ul Mbps', AppTheme.tertiary),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMetric(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}
