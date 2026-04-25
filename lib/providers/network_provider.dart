import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkInfo _networkInfo = NetworkInfo();
  Timer? _pollingTimer;
  StreamSubscription<List<WiFiAccessPoint>>? _scanSubscription;

  String? _wifiName;
  String? _wifiBSSID;
  String? _wifiIP;
  int _currentRssi = 0;
  String _frequency = "0";
  int _linkSpeed = 0;
  final List<int> _rssiHistory = List.filled(60, 0);
  
  String? _ispName;
  String? _ispType;

  String? get wifiName => _wifiName;
  String? get wifiBSSID => _wifiBSSID;
  String? get wifiIP => _wifiIP;
  int get currentRssi => _currentRssi;
  String get frequency => _frequency;
  int get linkSpeed => _linkSpeed;
  List<int> get rssiHistory => _rssiHistory;
  String? get ispName => _ispName;
  String? get ispType => _ispType;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NetworkProvider() {
    initNetworkInfo();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scanSubscription?.cancel();
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

    if (_wifiName == null || _wifiName!.isEmpty || _wifiName == '<unknown ssid>') {
        _wifiName = null;
        _wifiBSSID = null;
        _wifiIP = null;
        _ispName = null;
        _ispType = null;
    } else {
        _fetchISPInfo();
    }

    _isLoading = false;
    notifyListeners();
    
    _startSignalPolling();
  }

  Future<void> _fetchISPInfo() async {
    if (_ispName != null) return; // already fetched
    try {
      final response = await http.get(Uri.parse('https://ipwhois.app/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _ispName = data['isp'];
          _ispType = data['type'] ?? 'Broadband';
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch ISP: $e");
    }
  }

  void _startSignalPolling() {
    // Listen to results stream for real-time updates
    _scanSubscription?.cancel();
    _scanSubscription = WiFiScan.instance.onScannedResultsAvailable.listen((results) {
      if (_wifiName == null) return;
      
      String cleanWifiName = _wifiName!.replaceAll('"', '');
      String? cleanBSSID = _wifiBSSID?.toLowerCase();

      for (var ap in results) {
        if ((cleanBSSID != null && ap.bssid.toLowerCase() == cleanBSSID) || 
            (ap.ssid.isNotEmpty && ap.ssid == cleanWifiName)) {
          _currentRssi = ap.level;
          if (ap.frequency < 3000) {
            _frequency = "2.4";
          } else if (ap.frequency < 5950) {
            _frequency = "5";
          } else {
            _frequency = "6";
          }
          break;
        }
      }
    });

    // High-frequency UI loop for the live graph (100ms)
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_wifiName != null && _currentRssi != 0) {
        _rssiHistory.add(_currentRssi);
      } else {
        _rssiHistory.add(0);
      }
      
      if (_rssiHistory.length > 60) {
        _rssiHistory.removeAt(0);
      }
      notifyListeners();
    });

    // Hardware-safe continuous scan loop
    _runContinuousScan();
  }

  Future<void> _runContinuousScan() async {
    while (true) {
      if (_pollingTimer == null || !_pollingTimer!.isActive) break;

      try {
        String? newName = await _networkInfo.getWifiName();
        String? newBSSID = await _networkInfo.getWifiBSSID();
        String? newIP = await _networkInfo.getWifiIP();

        if (newName == null || newName.isEmpty || newName == '<unknown ssid>') {
          newName = null;
          newBSSID = null;
          newIP = null;
        }

        bool connectionChanged = (_wifiName != newName || _wifiIP != newIP);
        _wifiName = newName;
        _wifiBSSID = newBSSID;
        _wifiIP = newIP;

        if (_wifiName == null) {
          _currentRssi = 0;
          _frequency = "0";
          _linkSpeed = 0;
          _ispName = null;
          _ispType = null;
        } else if (connectionChanged) {
          _fetchISPInfo();
        }

        // Only scan for signal if connected
        if (_wifiName != null) {
          final canScan = await WiFiScan.instance.canStartScan();
          if (canScan == CanStartScan.yes) {
            // Timeout prevents the loop from hanging on older Android versions
            await WiFiScan.instance.startScan().timeout(
              const Duration(seconds: 3),
              onTimeout: () => false,
            );
          }
          
          // Even if startScan is throttled, try to read cached results
          final canGet = await WiFiScan.instance.canGetScannedResults();
          if (canGet == CanGetScannedResults.yes) {
            final results = await WiFiScan.instance.getScannedResults();
            String cleanWifiName = _wifiName!.replaceAll('"', '');
            String? cleanBSSID = _wifiBSSID?.toLowerCase();

            for (var ap in results) {
              if ((cleanBSSID != null && ap.bssid.toLowerCase() == cleanBSSID) || 
                  (ap.ssid.isNotEmpty && ap.ssid == cleanWifiName)) {
                _currentRssi = ap.level;
                if (ap.frequency < 3000) {
                  _frequency = "2.4";
                } else if (ap.frequency < 5950) {
                  _frequency = "5";
                } else {
                  _frequency = "6";
                }
                break;
              }
            }
          }
        }
      } catch (_) {}

      // Fast 1 second polling interval. Will be throttled by Android if Developer Options aren't toggled, 
      // but the cached results logic ensures it doesn't drop to 0.
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }
}
