import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/services.dart';

import '../services/ip_info_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';


part 'providers.g.dart';

class WifiInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();
  static const MethodChannel _channel = MethodChannel('com.example.smart_wifi_analyzer/wifi');

  Future<bool> _requestAndVerifyPermission() async {
    // Request location permission at runtime
    final status = await Permission.location.request();
    if (status.isGranted) return true;

    // If denied, try locationWhenInUse
    final whenInUse = await Permission.locationWhenInUse.request();
    return whenInUse.isGranted;
  }

  Future<String?> getSSID() async {
    final granted = await _requestAndVerifyPermission();
    if (!granted) return null;
    try {
      final name = await _networkInfo.getWifiName();
      // Android wraps SSID in quotes e.g. "\"MyNetwork\"" — strip them
      if (name == null) return null;
      return name.replaceAll('"', '');
    } catch (_) { return null; }
  }

  Future<String?> getBSSID() async {
    final granted = await _requestAndVerifyPermission();
    if (!granted) return null;
    try { return await _networkInfo.getWifiBSSID(); }
    catch (_) { return null; }
  }

  Future<String?> getLocalIP() async {
    try { return await _networkInfo.getWifiIP(); }
    catch (_) { return null; }
  }

  Future<String?> getIPv6() async {
    try { return await _networkInfo.getWifiIPv6(); }
    catch (_) { return null; }
  }

  Future<String?> getGateway() async {
    final granted = await _requestAndVerifyPermission();
    if (!granted) return null;
    try { return await _networkInfo.getWifiGatewayIP(); }
    catch (_) { return null; }
  }

  Future<String?> getSubnet() async {
    try { return await _networkInfo.getWifiSubmask(); }
    catch (_) { return null; }
  }

  Future<int?> getFrequency() async {
    final granted = await _requestAndVerifyPermission();
    if (!granted) return null;
    try {
      final bssid = await getBSSID();
      if (bssid == null || bssid.isEmpty) return null;
      final canGet = await WiFiScan.instance.canGetScannedResults();
      if (canGet == CanGetScannedResults.yes) {
        final results = await WiFiScan.instance.getScannedResults();
        for (var ap in results) {
          if (ap.bssid == bssid) return ap.frequency;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<int?> getLinkSpeed() async {
    return null;
  }

  Future<int?> getRSSI() async {
    final granted = await _requestAndVerifyPermission();
    if (!granted) return null;
    
    // First attempt: Fast native OS API (Android only)
    try {
      final int? rssi = await _channel.invokeMethod('getRssi');
      if (rssi != null && rssi < 0) return rssi;
    } catch (_) {
      // Fallback if not implemented (e.g. iOS) or error
    }

    // Fallback: WiFi scan results
    try {
      final bssid = await getBSSID();
      if (bssid == null || bssid.isEmpty) return null;
      final canGet = await WiFiScan.instance.canGetScannedResults();
      if (canGet == CanGetScannedResults.yes) {
        final results = await WiFiScan.instance.getScannedResults();
        for (var ap in results) {
          if (ap.bssid == bssid) return ap.level;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String> getSecurityType(String? currentBssid, String? currentSsid) async {
    final granted = await _requestAndVerifyPermission();
    if (!granted) return 'WPA2';
    try {
      var canGet = await WiFiScan.instance.canGetScannedResults();
      var results = canGet == CanGetScannedResults.yes 
          ? await WiFiScan.instance.getScannedResults() 
          : <WiFiAccessPoint>[];

      // If results are empty, try triggering a scan
      if (results.isEmpty) {
        final canStart = await WiFiScan.instance.canStartScan();
        if (canStart == CanStartScan.yes) {
          await WiFiScan.instance.startScan();
          await Future.delayed(const Duration(seconds: 2));
          canGet = await WiFiScan.instance.canGetScannedResults();
          if (canGet == CanGetScannedResults.yes) {
            results = await WiFiScan.instance.getScannedResults();
          }
        }
      }
      
      if (results.isEmpty) return 'WPA2';

      // Try to match by BSSID first (most accurate)
      WiFiAccessPoint? matched;
      if (currentBssid != null && currentBssid != '—') {
        for (var ap in results) {
          if (ap.bssid.toLowerCase() == currentBssid.toLowerCase()) {
            matched = ap;
            break;
          }
        }
      }
      // Fallback: match by SSID
      if (matched == null && currentSsid != null && currentSsid != '—') {
        for (var ap in results) {
          if (ap.ssid == currentSsid) {
            matched = ap;
            break;
          }
        }
      }
      matched ??= results.first;

      final caps = matched.capabilities.toUpperCase();
      if (caps.contains('WPA3') || caps.contains('SAE')) return 'WPA3';
      if (caps.contains('WPA2') || caps.contains('RSN')) return 'WPA2';
      if (caps.contains('WPA')) return 'WPA';
      if (caps.contains('WEP')) return 'WEP';
      if (caps.isEmpty || caps == '[ESS]') return 'Open';
      
      return 'WPA2'; // safe default
    } catch (_) {
      return 'WPA2';
    }
  }
}

@riverpod
IpInfoService ipInfoService(IpInfoServiceRef ref) => IpInfoService();

@riverpod
Future<Map<String, dynamic>> ipInfo(IpInfoRef ref) =>
  ref.watch(ipInfoServiceProvider).fetchIpInfo();

@riverpod
WifiInfoService wifiInfoService(WifiInfoServiceRef ref) => WifiInfoService();
