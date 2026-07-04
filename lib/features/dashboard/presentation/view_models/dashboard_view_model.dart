import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/providers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/network_info_model.dart';

part 'dashboard_view_model.freezed.dart';
part 'dashboard_view_model.g.dart';

@freezed
class DashboardState with _$DashboardState {
  factory DashboardState({
    @Default(null) NetworkInfoModel? networkInfo,
    @Default(true) bool isLoading,
    String? error,
  }) = _DashboardState;
}

@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  StreamSubscription? _connectivitySubscription;

  @override
  DashboardState build() {
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!state.isLoading) {
        load();
      }
    });

    return DashboardState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final wifiService = ref.read(wifiInfoServiceProvider);
      final ipService = ref.read(ipInfoServiceProvider);

      // STEP 1: Request permissions FIRST — before any wifi call
      final permGranted = await Permission.location.request();
      if (!permGranted.isGranted) {
        await Permission.locationWhenInUse.request();
      }

      // STEP 2: Small delay to let permission take effect
      await Future.delayed(const Duration(milliseconds: 500));

      // STEP 3: Fetch all wifi data in parallel
      final results = await Future.wait([
        wifiService.getSSID(),           // [0]
        wifiService.getBSSID(),          // [1]
        wifiService.getLocalIP(),        // [2]
        wifiService.getGateway(),        // [3]
        wifiService.getSubnet(),         // [4]
        wifiService.getIPv6(),           // [5]
      ]);

      final ssid      = results[0] ?? 'Not Connected';
      final bssid     = results[1] ?? '—';
      final localIp   = results[2] ?? '—';
      final rawGateway = results[3] as String?;
      final localIpVal = results[2] ?? '—';
      // Derive gateway from local IP: replace last octet with .1
      // e.g. 192.168.1.11 → 192.168.1.1
      String gateway = '—';
      if (rawGateway != null && rawGateway.isNotEmpty) {
        gateway = rawGateway;
      } else if (localIpVal != '—' && localIpVal.contains('.')) {
        final parts = localIpVal.split('.');
        if (parts.length == 4) {
          gateway = '${parts[0]}.${parts[1]}.${parts[2]}.1';
        }
      }
      final subnet    = results[4] ?? '—';
      final ipv6      = results[5];

      // STEP 4: Fetch real RSSI and frequency separately
      final rssi       = await wifiService.getRSSI() ?? -99;
      final freqMHz    = await wifiService.getFrequency();
      
      // STEP 5: Derive band and WiFi version from frequency
      String band;
      String wifiVersion;
      if (freqMHz != null) {
        if (freqMHz >= 5945) {
          band = '6 GHz';
          wifiVersion = 'Wi-Fi 6E (802.11ax)';
        } else if (freqMHz >= 5000) {
          band = '5 GHz';
          wifiVersion = 'Wi-Fi 5 (802.11ac)';
        } else {
          band = '2.4 GHz';
          wifiVersion = 'Wi-Fi 4 (802.11n)';
        }
      } else {
        band = '—';
        wifiVersion = '—';
      }

      // STEP 6: Fetch IP info (Public IP + ISP) with timeout
      final ipInfo = await ipService.fetchIpInfo();
      final publicIp  = ipInfo['ip'] ?? 'Unavailable';
      final org       = ipInfo['org'] ?? 'Unavailable';
      final ispName   = ipService.parseIspName(org);
      final ipVersion = ipInfo['version'] ?? (ipv6 != null ? 'IPv6' : 'IPv4');

      // STEP 7: Build the model with real data
      final networkInfo = NetworkInfoModel(
        ssid:        ssid,
        bssid:       bssid,
        localIp:     localIp,
        publicIp:    publicIp,
        frequency:   freqMHz != null ? '$freqMHz MHz' : '—',
        band:        band,
        securityType: await wifiService.getSecurityType(bssid, ssid),
        wifiVersion: wifiVersion,
        rssi:        rssi,
        ispName:     ispName,
        ispOrg:      org,
        ipVersion:   ipVersion,
        subnet:      subnet,
        gateway:     gateway,
      );

      state = state.copyWith(
        networkInfo: networkInfo,
        isLoading:   false,
        error:       null,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     'Failed to load network info: ${e.toString()}',
      );
    }
  }
  // ── Fast refresh: RSSI + SSID only (no HTTP, pure device API) ──
  Future<void> refreshSignal() async {
    try {
      final wifiService = ref.read(wifiInfoServiceProvider);
      final currentSsid = await wifiService.getSSID() ?? 'Not Connected';

      // If the SSID changed from what we had, trigger full reload
      if (state.networkInfo != null && currentSsid != state.networkInfo!.ssid) {
        load();
        return;
      }

      final rssi = await wifiService.getRSSI() ?? state.networkInfo?.rssi ?? -99;

      // Always update state — no equality check
      // UI will only visually change if value is different (Flutter handles this)
      if (state.networkInfo != null) {
        state = state.copyWith(
          networkInfo: state.networkInfo!.copyWith(
            rssi: rssi,
            ssid: currentSsid,
          ),
        );
      }
    } catch (_) {
      // Silent fail — never show error for background refresh
    }
  }

  // ── Medium refresh: local network info only (no HTTP) ──
  Future<void> refreshNetworkInfo() async {
    try {
      final wifiService = ref.read(wifiInfoServiceProvider);
      final localIp = await wifiService.getLocalIP() 
                      ?? state.networkInfo?.localIp ?? '—';
      final rawGateway = await wifiService.getGateway();
      final currentLocalIp = await wifiService.getLocalIP() 
                             ?? state.networkInfo?.localIp ?? '—';
      String gateway;
      if (rawGateway != null && rawGateway.isNotEmpty) {
        gateway = rawGateway;
      } else if (currentLocalIp.contains('.')) {
        final parts = currentLocalIp.split('.');
        gateway = parts.length == 4
            ? '${parts[0]}.${parts[1]}.${parts[2]}.1'
            : state.networkInfo?.gateway ?? '—';
      } else {
        gateway = state.networkInfo?.gateway ?? '—';
      }
      final subnet  = await wifiService.getSubnet()  
                      ?? state.networkInfo?.subnet  ?? '—';
      final freqMHz = await wifiService.getFrequency();

      String band        = state.networkInfo?.band        ?? '—';
      String wifiVersion = state.networkInfo?.wifiVersion ?? '—';

      if (freqMHz != null) {
        if (freqMHz >= 5945) {
          band = '6 GHz';
          wifiVersion = 'Wi-Fi 6E (802.11ax)';
        } else if (freqMHz >= 5000) {
          band = '5 GHz';
          wifiVersion = 'Wi-Fi 5 (802.11ac)';
        } else {
          band = '2.4 GHz';
          wifiVersion = 'Wi-Fi 4 (802.11n)';
        }
      }
      
      final securityType = await wifiService.getSecurityType(
        state.networkInfo?.bssid,
        state.networkInfo?.ssid,
      );

      if (state.networkInfo != null) {
        state = state.copyWith(
          networkInfo: state.networkInfo!.copyWith(
            localIp:     localIp,
            gateway:     gateway,
            subnet:      subnet,
            frequency:   freqMHz != null ? '$freqMHz MHz' 
                         : state.networkInfo!.frequency,
            band:        band,
            wifiVersion: wifiVersion,
            securityType: securityType,
          ),
        );
      }
    } catch (_) {
      // Silent fail — never show error for background refresh
    }
  }

  // ── Slow refresh: Public IP + ISP (HTTP call) ──
  Future<void> refreshPublicIp() async {
    try {
      if (state.networkInfo == null) return;
      
      final ipService = ref.read(ipInfoServiceProvider);
      final ipInfo = await ipService.fetchIpInfo();
      final publicIp  = ipInfo['ip'] ?? 'Unavailable';
      final org       = ipInfo['org'] ?? 'Unavailable';
      final ispName   = ipService.parseIspName(org);
      
      if (state.networkInfo!.publicIp != publicIp || state.networkInfo!.ispOrg != org) {
        final wifiService = ref.read(wifiInfoServiceProvider);
        final ipv6      = await wifiService.getIPv6();
        final ipVersion = ipInfo['version'] ?? (ipv6 != null ? 'IPv6' : 'IPv4');

        state = state.copyWith(
          networkInfo: state.networkInfo!.copyWith(
            publicIp: publicIp,
            ispName: ispName,
            ispOrg: org,
            ipVersion: ipVersion,
          ),
        );
      }
    } catch (_) {
      // Silent fail
    }
  }
}
