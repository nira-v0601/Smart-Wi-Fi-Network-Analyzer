import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

  @override
  SignalState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return SignalState();
  }

  void startMonitoring() async {
    final wifiService = ref.read(wifiInfoServiceProvider);
    final ssid = await wifiService.getSSID() ?? 'Unknown';

    state = state.copyWith(
      isMonitoring: true,
      ssid: ssid,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchSignalData();
    });
    
    _fetchSignalData();
  }

  Future<void> _fetchSignalData() async {
    if (!state.isMonitoring) return;
    
    final wifiService = ref.read(wifiInfoServiceProvider);
    final fetchedRssi = await wifiService.getRSSI();

    if (!state.isMonitoring) return;

    final rssi = fetchedRssi ?? (state.currentRssi == 0 ? -100 : state.currentRssi);

    final newSpot = FlSpot(state.dataPointIndex.toDouble(), rssi.toDouble());
    
    var newGraphData = List<FlSpot>.from(state.graphData)..add(newSpot);
    if (newGraphData.length > 30) {
      newGraphData.removeAt(0);
    }
    
    state = state.copyWith(
      currentRssi: rssi,
      graphData: newGraphData,
      dataPointIndex: state.dataPointIndex + 1,
    );
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isMonitoring: false);
  }
}
