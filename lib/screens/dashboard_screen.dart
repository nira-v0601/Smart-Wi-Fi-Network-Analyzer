import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/providers/network_provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';

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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                     'NETWORK OVERVIEW',
                     style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 16),
                   _buildMainSignalCard(context),
                   const SizedBox(height: 24),
                   const Text(
                     'CONNECTION DETAILS',
                     style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(child: _buildIpCard(context)),
                       const SizedBox(width: 16),
                       Expanded(child: _buildIspCard(context)),
                     ],
                   ),
                   const SizedBox(height: 80), // For bottom nav
                ],
              ),
      ),
    );
  }

  Widget _buildMainSignalCard(BuildContext context) {
    final wifiName = context.select((NetworkProvider p) => p.wifiName);
    final currentRssi = context.select((NetworkProvider p) => p.currentRssi);
    final frequency = context.select((NetworkProvider p) => p.frequency);
    final linkSpeed = context.select((NetworkProvider p) => p.linkSpeed);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceContainerLow,
            AppTheme.surfaceContainerLow.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONNECTED NETWORK',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wifiName ?? 'Wi-Fi is off/not connected',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withValues(alpha: 0.2),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8, 
                      decoration: BoxDecoration(
                        color: AppTheme.secondary, 
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.secondary, blurRadius: 4)],
                      )
                    ),
                    const SizedBox(width: 8),
                    const Text('ACTIVE', style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('WPA3', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(context, 'Strength', wifiName != null ? currentRssi.toString() : 'N/A', wifiName != null ? 'dBm' : '', AppTheme.primary),
              _buildStatItem(context, 'Freq', wifiName != null ? frequency.toString() : 'N/A', wifiName != null ? 'GHz' : '', AppTheme.secondary),
              _buildStatItem(context, 'Speed', wifiName != null && linkSpeed > 0 ? linkSpeed.toString() : 'N/A', wifiName != null && linkSpeed > 0 ? 'Mbps' : '', AppTheme.tertiary),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildIpCard(BuildContext context) {
    final wifiIP = context.select((NetworkProvider p) => p.wifiIP);
    final publicIP = context.select((NetworkProvider p) => p.publicIP);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AppTheme.tertiary.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.tertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.router, color: AppTheme.tertiary, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('LOCAL IP (LAN)', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(wifiIP ?? 'Not Connected', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('PUBLIC IP (INTERNET)', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(publicIP ?? 'Detecting...', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildIspCard(BuildContext context) {
    final wifiName = context.select((NetworkProvider p) => p.wifiName);
    final ispName = context.select((NetworkProvider p) => p.ispName);
    final ispType = context.select((NetworkProvider p) => p.ispType);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.public, color: AppTheme.secondary, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('ISP INFO', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(ispName ?? (wifiName != null ? 'Local ISP' : 'N/A'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(ispType ?? (wifiName != null ? 'Broadband' : 'Unknown'), style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
