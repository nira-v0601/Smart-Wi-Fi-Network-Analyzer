import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/providers/network_provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((NetworkProvider p) => p.isLoading);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.language, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Smart Wi-Fi Network Analyzer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.surfaceVariant,
              child: Icon(Icons.person, color: AppTheme.onSurfaceVariant),
            ),
          )
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                     'NETWORK DETAILS',
                     style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: AppTheme.cardSpacing),
                   _buildMainWifiCard(context),
                   const SizedBox(height: AppTheme.cardSpacing),
                   _buildIpSubCard(context),
                   const SizedBox(height: AppTheme.cardSpacing),
                   _buildIspSubCard(context),
                   const SizedBox(height: 80), // For bottom nav
                ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
              ),
            ),
    );
  }


  Widget _buildMainWifiCard(BuildContext context) {
    final wifiName = context.select((NetworkProvider p) => p.wifiName) ?? 'N/A';
    final frequency = context.select((NetworkProvider p) => p.frequency).toString();
    final currentRssi = context.select((NetworkProvider p) => p.currentRssi).toString();
    final linkSpeed = context.select((NetworkProvider p) => p.linkSpeed).toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 10)
                  ]
                ),
                child: const Icon(Icons.wifi, color: AppTheme.primary, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT NETWORK',
                      style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wifiName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildWifiPill('Frequency', '$frequency GHz', Icons.speed)),
              const SizedBox(width: 12),
              Expanded(child: _buildWifiPill('Signal', '$currentRssi dBm', Icons.network_check)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildWifiPill('Security', 'WPA3', Icons.security)),
              const SizedBox(width: 12),
              Expanded(child: _buildWifiPill('Link Speed', '$linkSpeed Mbps', Icons.swap_vert)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWifiPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSubCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildIpSubCard(BuildContext context) {
    final wifiIP = context.select((NetworkProvider p) => p.wifiIP) ?? 'N/A';
    final publicIP = context.select((NetworkProvider p) => p.publicIP) ?? 'Detecting...';
    
    return _buildSubCard(
      title: 'IP Information',
      icon: Icons.router,
      color: AppTheme.tertiary,
      children: [
        Row(
          children: [
            Expanded(child: _buildWifiPill('Local IP', wifiIP, Icons.laptop_chromebook)),
            const SizedBox(width: 12),
            Expanded(child: _buildWifiPill('Public IP', publicIP, Icons.public)),
          ],
        ),
      ]
    );
  }

  Widget _buildIspSubCard(BuildContext context) {
    final ispName = context.select((NetworkProvider p) => p.ispName) ?? 'N/A';
    final ispType = context.select((NetworkProvider p) => p.ispType) ?? 'N/A';

    return _buildSubCard(
      title: 'ISP Information',
      icon: Icons.business,
      color: AppTheme.secondary,
      children: [
        Row(
          children: [
            Expanded(child: _buildWifiPill('ISP Name', ispName, Icons.corporate_fare)),
            const SizedBox(width: 12),
            Expanded(child: _buildWifiPill('Connection', ispType, Icons.settings_ethernet)),
          ],
        ),
      ]
    );
  }
}
