import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/di/providers.dart';

part 'signal_view_model.freezed.dart';
part 'signal_view_model.g.dart';

@freezed
class SignalState with _$SignalState {
  factory SignalState({
    @Default(0) int currentRssi,
    @Default([]) List<FlSpot> graphData,
    @Default(0) int dataPointIndex,
    @Default('—') String ssid,
    @Default(false) bool isMonitoring,
  }) = _SignalState;
}

@riverpod
class SignalViewModel extends _$SignalViewModel {
  Timer? _timer;
  StreamSubscription? _connectivitySubscription;

  @override
  SignalState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _connectivitySubscription?.cancel();
    });
    return SignalState();
  }

  void startMonitoring() async {
    final wifiService = ref.read(wifiInfoServiceProvider);
    final ssid = await wifiService.getSSID() ?? 'Not Connected';

    state = state.copyWith(
      isMonitoring: true,
      ssid: ssid,
    );

    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((_) {
      if (state.isMonitoring) _fetchSignalData();
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _fetchSignalData();
    });
    
    _fetchSignalData();
  }

  Future<void> _fetchSignalData() async {
    if (!state.isMonitoring) return;
    
    final wifiService = ref.read(wifiInfoServiceProvider);
    final currentSsid = await wifiService.getSSID() ?? 'Not Connected';
    final fetchedRssi = await wifiService.getRSSI();

    if (!state.isMonitoring) return;

    final rssi = (currentSsid == 'Not Connected' || currentSsid == 'Unknown' || fetchedRssi == null) 
                 ? -100 
                 : fetchedRssi;

    final newSpot = FlSpot(state.dataPointIndex.toDouble(), rssi.toDouble());
    
    var newGraphData = List<FlSpot>.from(state.graphData)..add(newSpot);
    if (newGraphData.length > 30) {
      newGraphData.removeAt(0);
    }
    
    state = state.copyWith(
      currentRssi: rssi,
      graphData: newGraphData,
      dataPointIndex: state.dataPointIndex + 1,
      ssid: currentSsid,
    );
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    state = state.copyWith(isMonitoring: false);
  }
}
