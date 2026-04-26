import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/providers/network_provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';

class NetworkInfoScreen extends StatelessWidget {
  const NetworkInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Information'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<NetworkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (provider.wifiName == null || provider.wifiName!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Not connected to Wi-Fi',
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoSection(
                'Connection Details',
                [
                  _buildInfoRow('SSID', provider.wifiName!.replaceAll('"', '')),
                  const Divider(color: AppTheme.onSurfaceVariant, thickness: 0.2, height: 16),
                  _buildInfoRow('BSSID', provider.wifiBSSID ?? 'Unknown'),
                  const Divider(color: AppTheme.onSurfaceVariant, thickness: 0.2, height: 16),
                  _buildInfoRow('IP Address', provider.wifiIP ?? 'Unknown'),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                'Signal Attributes',
                [
                  _buildInfoRow('Frequency Band', '${provider.frequency} GHz'),
                  const Divider(color: AppTheme.onSurfaceVariant, thickness: 0.2, height: 16),
                  _buildInfoRow('Signal Strength (RSSI)', '${provider.currentRssi} dBm'),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                'ISP Information',
                [
                  _buildInfoRow('ISP Name', provider.ispName ?? 'Detecting...'),
                  const Divider(color: AppTheme.onSurfaceVariant, thickness: 0.2, height: 16),
                  _buildInfoRow('Connection Type', provider.ispType ?? 'Detecting...'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
