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
  final int _linkSpeed = 0;
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
  int get linkSpeed => _linkSpeed;
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
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
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
