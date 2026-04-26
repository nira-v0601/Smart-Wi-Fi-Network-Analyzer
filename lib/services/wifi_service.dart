import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();
  bool _isScanningLoopActive = false;
  final StreamController<List<WiFiAccessPoint>> _resultsController = StreamController<List<WiFiAccessPoint>>.broadcast();

  WifiService() {
    // Passively listen to OS broadcast intents and forward them
    WiFiScan.instance.onScannedResultsAvailable.listen((results) {
      if (!_resultsController.isClosed) {
        _resultsController.add(results);
      }
    });
  }

  void dispose() {
    _resultsController.close();
  }

  /// Requests necessary hardware permissions for Wi-Fi scanning
  Future<bool> requestPermissions() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  /// Fetches the current connected Wi-Fi SSID
  Future<String?> getWifiName() async {
    String? name = await _networkInfo.getWifiName();
    return (name == null || name.isEmpty || name == '<unknown ssid>') ? null : name;
  }

  /// Fetches the current connected Wi-Fi BSSID
  Future<String?> getWifiBSSID() async {
    return await _networkInfo.getWifiBSSID();
  }

  /// Fetches the current connected Wi-Fi IP address
  Future<String?> getWifiIP() async {
    return await _networkInfo.getWifiIP();
  }

  /// Exposes the real-time stream of scanned Wi-Fi access points
  Stream<List<WiFiAccessPoint>> get scannedResultsStream => _resultsController.stream;

  /// Starts the hardware-safe background polling loop
  void startContinuousScan() {
    if (_isScanningLoopActive) return;
    _isScanningLoopActive = true;
    _runContinuousScan();
  }

  /// Stops the hardware scanning loop
  void stopContinuousScan() {
    _isScanningLoopActive = false;
  }

  /// Internal loop that manages Android OS throttling by waiting 5 seconds between scans
  Future<void> _runContinuousScan() async {
    while (_isScanningLoopActive) {
      try {
        final canScan = await WiFiScan.instance.canStartScan();
        if (canScan == CanStartScan.yes) {
          await WiFiScan.instance.startScan().timeout(
            const Duration(seconds: 3),
            onTimeout: () => false,
          );
        }
        
        // Active Polling Fallback: Actively fetch cached results to patch OS intent drops
        final results = await getCachedResults();
        if (results.isNotEmpty && !_resultsController.isClosed) {
          _resultsController.add(results);
        }
      } catch (_) {}

      // Smart 5-second polling interval to respect Android quotas
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Fetches cached results from the OS, useful when the hardware scanner is throttled
  Future<List<WiFiAccessPoint>> getCachedResults() async {
    try {
      final canGet = await WiFiScan.instance.canGetScannedResults();
      if (canGet == CanGetScannedResults.yes) {
        return await WiFiScan.instance.getScannedResults();
      }
    } catch (_) {}
    return [];
  }
}
