import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_wifi_analyzer/services/isp_service.dart';
import 'package:smart_wifi_analyzer/services/wifi_service.dart';

class NetworkProvider extends ChangeNotifier with WidgetsBindingObserver {
  final WifiService _wifiService = WifiService();
  final IspService _ispService = IspService();

  Timer? _pollingTimer;
  Timer? _connectionCheckTimer;
  StreamSubscription? _scanSubscription;

  bool _isAppInForeground = true;

  String? _wifiName;
  String? _wifiBSSID;
  String? _wifiIP;
  int _currentRssi = 0;
  String _frequency = "0";
  String _wifiVersion = "Unknown";
  String _securityProtocol = "Open";
  final List<int> _rssiHistory = [];
  
  String? _ispName;
  String? _ispType;

  String? _publicIP;

  bool _isLoading = false;

  String? get wifiName => _wifiName;
  String? get wifiBSSID => _wifiBSSID;
  String? get wifiIP => _wifiIP;
  int get currentRssi => _currentRssi;
  String get frequency => _frequency;
  String get wifiVersion => _wifiVersion;
  String get securityProtocol => _securityProtocol;
  List<int> get rssiHistory => _rssiHistory;
  String? get ispName => _ispName;
  String? get ispType => _ispType;
  String? get publicIP => _publicIP;
  bool get isLoading => _isLoading;

  NetworkProvider() {
    WidgetsBinding.instance.addObserver(this);
    initNetworkInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _wifiService.stopContinuousScan();
    _wifiService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      initNetworkInfo();
    } else if (state == AppLifecycleState.paused) {
      _isAppInForeground = false;
      _cancelTimers();
      _wifiService.stopContinuousScan();
    }
  }

  void _cancelTimers() {
    _pollingTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _scanSubscription?.cancel();
  }

  Future<void> initNetworkInfo() async {
    _isLoading = true;
    notifyListeners();

    await _wifiService.requestPermissions();

    _wifiName = await _wifiService.getWifiName();
    _wifiBSSID = await _wifiService.getWifiBSSID();
    _wifiIP = await _getLocalIP();
    _fetchPublicIP();

    if (_wifiName == null) {
      _ispName = null;
      _ispType = null;
      _currentRssi = 0;
      _frequency = "0";
      _wifiVersion = "Unknown";
      _securityProtocol = "Open";
    } else {
      _fetchISPInfo();
    }

    _isLoading = false;
    notifyListeners();

    if (_isAppInForeground) {
      _startSignalPolling();
    }
  }

  Future<void> _fetchISPInfo() async {
    if (_ispName != null) return;
    
    final ispData = await _ispService.fetchISPInfo();
    if (ispData != null) {
      _ispName = ispData['name'];
      _ispType = ispData['type'];
      notifyListeners();
    }
  }

  Future<String?> _getLocalIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to get local IP: $e");
    }
    return null;
  }

  Future<void> _fetchPublicIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _publicIP = data['ip'];
      } else {
        _publicIP = "Public IP unavailable";
      }
    } catch (e) {
      _publicIP = "Public IP unavailable";
    }
    notifyListeners();
  }

  String _parseSecurity(String caps) {
    if (caps.isEmpty) return "Unknown";
    final c = caps.toUpperCase();
    if ((c.contains('WPA3') || c.contains('SAE')) && c.contains('WPA2')) {
      return "WPA2/WPA3 Transitional";
    } else if (c.contains('WPA3') || c.contains('SAE')) {
      return "WPA3";
    } else if (c.contains('EAP')) {
      return "Enterprise";
    } else if (c.contains('WPA2') || c.contains('RSN')) {
      return "WPA2";
    } else if (c.contains('WPA')) {
      return "WPA";
    } else if (c.contains('WEP')) {
      return "WEP";
    } else if (c.contains('ESS') && !c.contains('WPA') && !c.contains('WEP') && !c.contains('RSN')) {
      return "Open";
    }
    return "Open";
  }

  String _parseWifiVersion(dynamic standard, int freq) {
    String stdStr = standard.toString().toLowerCase();
    if (stdStr.contains('legacy')) return "Legacy";
    if (stdStr.contains('11n')) return "Wi-Fi 4";
    if (stdStr.contains('11ac')) return "Wi-Fi 5";
    if (stdStr.contains('11ax')) return freq > 5950 ? "Wi-Fi 6E" : "Wi-Fi 6";
    if (stdStr.contains('11be')) return "Wi-Fi 7";
    if (stdStr.contains('11ad')) return "WiGig";

    if (stdStr == '1') return "Legacy";
    if (stdStr == '4') return "Wi-Fi 4";
    if (stdStr == '5') return "Wi-Fi 5";
    if (stdStr == '6') return freq > 5950 ? "Wi-Fi 6E" : "Wi-Fi 6";
    if (stdStr == '8') return "Wi-Fi 7";

    // Fallback logic
    if (freq > 5950) return "Wi-Fi 6E";
    if (freq > 5000) return "Wi-Fi 5";
    if (freq > 0) return "Wi-Fi 4";
    return "Unknown";
  }

  void _startSignalPolling() {
    _scanSubscription?.cancel();
    _scanSubscription = _wifiService.scannedResultsStream.listen((results) {
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
          _wifiVersion = _parseWifiVersion(ap.standard, ap.frequency);
          _securityProtocol = _parseSecurity(ap.capabilities);
          notifyListeners();
          break;
        }
      }
    });

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_wifiName != null && _currentRssi != 0) {
        _rssiHistory.add(_currentRssi);
      } else {
        _rssiHistory.add(-100);
      }
      
      if (_rssiHistory.length > 60) {
        _rssiHistory.removeAt(0);
      }
      notifyListeners();
    });

    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      String? newName = await _wifiService.getWifiName();
      String? newIP = await _getLocalIP();
      
      if (newName != _wifiName || newIP != _wifiIP) {
        _wifiName = newName;
        _wifiIP = newIP;
        _wifiBSSID = await _wifiService.getWifiBSSID();
        _fetchPublicIP();
        
        if (_wifiName == null) {
          _currentRssi = 0;
          _frequency = "0";
          _wifiVersion = "Unknown";
          _securityProtocol = "Open";
          _ispName = null;
          _ispType = null;
          _publicIP = null;
        } else {
          _ispName = null; // Reset to force re-fetch
          _fetchISPInfo();
        }
        notifyListeners();
      }
    });

    _wifiService.startContinuousScan();
  }
}
