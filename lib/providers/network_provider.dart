import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkInfo _networkInfo = NetworkInfo();
  Timer? _pollingTimer;

  String? _wifiName;
  String? _wifiBSSID;
  String? _wifiIP;
  int _currentRssi = -42;
  double _frequency = 5.8;
  int _linkSpeed = 1200;

  String? get wifiName => _wifiName;
  String? get wifiBSSID => _wifiBSSID;
  String? get wifiIP => _wifiIP;
  int get currentRssi => _currentRssi;
  double get frequency => _frequency;
  int get linkSpeed => _linkSpeed;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NetworkProvider() {
    initNetworkInfo();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> initNetworkInfo() async {
    _isLoading = true;
    notifyListeners();

    // Setup permission
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }

    try {
      _wifiName = await _networkInfo.getWifiName();
      _wifiBSSID = await _networkInfo.getWifiBSSID();
      _wifiIP = await _networkInfo.getWifiIP();
    } catch (e) {
      debugPrint("Failed to get network info: $e");
    }

    // fallback mock data if real fails or is null (emulator)
    if (_wifiName == null || _wifiName!.isEmpty || _wifiName == 'AndroidWifi') {
        _wifiName = 'NEON_FLUX_5G';
        _wifiBSSID = '00:14:22:01:23:45';
        _wifiIP = '192.168.1.154';
    }

    _isLoading = false;
    notifyListeners();
    
    _startSignalPolling();
  }

  void _startSignalPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
       final canScan = await WiFiScan.instance.canStartScan();
       if (canScan == CanStartScan.yes) {
         await WiFiScan.instance.startScan();
         final results = await WiFiScan.instance.getScannedResults();
         
         // Find matching network
         bool found = false;
         for (var ap in results) {
           if (ap.bssid == _wifiBSSID || (ap.ssid.isNotEmpty && ap.ssid == _wifiName)) {
             _currentRssi = ap.level;
             _frequency = ap.frequency > 5000 ? 5.8 : 2.4;
             found = true;
             break;
           }
         }
         
         if (found) {
           notifyListeners();
         }
       }
    });
  }
}
