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
        accessPoints = results..sort((a, b) => b.level.compareTo(a.level));
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
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
                  ap.capabilities,
                  ap.frequency,
                );
              },
            ),
    );
  }

  Widget _buildMockList() {
    return ListView(
      children: [
        _buildNetworkTile('NEON_FLUX_5G', -42, '[WPA3-ENTERPRISE]', 5200),
        _buildNetworkTile('Cyber_Mesh_2.4', -65, '[WPA2-PSK]', 2412),
        _buildNetworkTile('Guest_Link', -80, '[OPEN]', 2462),
      ],
    );
  }

  Widget _buildNetworkTile(String name, int rssi, String capability, int freq) {
    Color signalColor = AppTheme.secondary;
    if (rssi < -70) {
      signalColor = AppTheme.error;
    } else if (rssi < -50) {
      signalColor = Colors.yellowAccent;
    } else {
      signalColor = Colors.greenAccent;
    }

    int channel = 0;
    if (freq >= 2412 && freq <= 2484) {
      channel = ((freq - 2412) / 5).round() + 1;
    } else if (freq >= 5170 && freq <= 5825) {
      channel = ((freq - 5170) / 5).round() + 34;
    }

    String freqBand = freq > 5000 ? '5 GHz' : '2.4 GHz';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.padding, vertical: 8),
      padding: const EdgeInsets.all(AppTheme.padding),
      decoration: AppTheme.cardDecoration(signalColor),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: signalColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: signalColor.withValues(alpha: 0.2), blurRadius: 8),
              ],
            ),
            child: Icon(Icons.wifi, color: signalColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$capability • Ch $channel • $freqBand',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: signalColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$rssi dBm',
                  style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              _buildSignalBars(rssi, signalColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBars(int rssi, Color color) {
    int activeBars = 1;
    if (rssi >= -50) {
      activeBars = 4;
    } else if (rssi >= -60) {
      activeBars = 3;
    } else if (rssi >= -70) {
      activeBars = 2;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        bool isActive = index < activeBars;
        return Container(
          margin: const EdgeInsets.only(left: 3),
          width: 4,
          height: 6.0 + (index * 4),
          decoration: BoxDecoration(
            color: isActive ? color : AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
