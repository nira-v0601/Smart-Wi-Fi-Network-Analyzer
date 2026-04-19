import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';

class NetworksScreen extends StatefulWidget {
  const NetworksScreen({super.key});

  @override
  State<NetworksScreen> createState() => _NetworksScreenState();
}

class _NetworksScreenState extends State<NetworksScreen> {
  List<WiFiAccessPoint> accessPoints = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      isScanning = true;
    });

    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();
      setState(() {
        accessPoints = results;
        isScanning = false;
      });
    } else {
      // Mock data if running on emulator or lacks permissions
      setState(() {
        isScanning = false;
        accessPoints = []; // Leave empty or handle fallback
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Networks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startScan,
          )
        ],
      ),
      body: isScanning
          ? const Center(child: CircularProgressIndicator())
          : accessPoints.isEmpty
              ? _buildMockList() // Fallback for emulator mostly
              : ListView.builder(
                  itemCount: accessPoints.length,
                  itemBuilder: (context, index) {
                    final ap = accessPoints[index];
                    return _buildNetworkTile(
                      ap.ssid.isNotEmpty ? ap.ssid : 'Hidden Network',
                      ap.level, 
                      ap.capabilities
                    );
                  },
                ),
    );
  }

  Widget _buildMockList() {
    return ListView(
      children: [
        _buildNetworkTile('NEON_FLUX_5G', -42, '[WPA3-ENTERPRISE]'),
        _buildNetworkTile('Cyber_Mesh_2.4', -65, '[WPA2-PSK]'),
        _buildNetworkTile('Guest_Link', -80, '[OPEN]'),
      ],
    );
  }

  Widget _buildNetworkTile(String name, int rssi, String capability) {
    Color signalColor = AppTheme.secondary;
    if (rssi < -70) {
      signalColor = AppTheme.error;
    } else if (rssi < -50) {
      signalColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: signalColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  capability,
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$rssi dBm',
            style: TextStyle(color: signalColor, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
