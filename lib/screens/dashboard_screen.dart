import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/providers/network_provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NetworkProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.language, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'NEURAL GRID',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
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
      body: provider.isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildMainSignalCard(context, provider),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(child: _buildIpCard(context, provider)),
                       const SizedBox(width: 16),
                       Expanded(child: _buildIspCard(context, provider)),
                     ],
                   ),
                   const SizedBox(height: 16),
                   _buildTopologyCard(context),
                   const SizedBox(height: 80), // For bottom nav
                ],
              ),
      ),
    );
  }

  Widget _buildMainSignalCard(BuildContext context, NetworkProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
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
            provider.wifiName ?? 'Unknown Network',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle)),
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
              _buildStatItem(context, 'Strength', '${provider.currentRssi}', 'dBm', AppTheme.primary),
              _buildStatItem(context, 'Freq', '${provider.frequency}', 'GHz', AppTheme.secondary),
              _buildStatItem(context, 'Speed', '${provider.linkSpeed}', 'Mbps', AppTheme.tertiary),
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

  Widget _buildIpCard(BuildContext context, NetworkProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Text('IP PROTOCOL', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 16),
          Text(provider.wifiIP ?? '0.0.0.0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Static Lease', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildIspCard(BuildContext context, NetworkProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.1)),
      ),
      child: const Column(
        children: [
          Text('ISP INFO', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
          SizedBox(height: 16),
          Text('Starlink', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('LEO Link', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTopologyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Network Topology', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Live visual of connected nodes', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1))
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)), shape: BoxShape.circle)),
                Container(width: 120, height: 120, decoration: BoxDecoration(border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)), shape: BoxShape.circle)),
                Container(width: 16, height: 16, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.primary, blurRadius: 10)])),
              ],
            ),
          )
        ],
      ),
    );
  }
}
