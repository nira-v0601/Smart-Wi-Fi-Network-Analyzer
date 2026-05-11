import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wifi_analyzer/services/speed_test/bandwidth_engine.dart';
import 'package:smart_wifi_analyzer/services/speed_test/models.dart';
import 'package:smart_wifi_analyzer/services/speed_test/ping_test.dart';

// Maintain original enum names to minimize screen breakage, plus our new mappings
enum SpeedTestStatus { ready, selectingServer, pinging, downloading, uploading, completed, error }

class SpeedTestService {
  final _engine = BandwidthEngine();
  bool _isTesting = false;
  SpeedTestStatus _status = SpeedTestStatus.ready;

  Function(SpeedTestStatus)? onStatusChange;
  Function(double)? onPing;
  Function(PingResult)? onPingDetails;
  Function(double, double)? onDownloadProgress;
  Function(double, double)? onUploadProgress;
  Function(SpeedMetrics)? onCompleted; 
  Function(String)? onError;
  Function(ServerInfo)? onServerSelected;

  SpeedTestService() {
    _engine.onStateChange = (EngineState state) {
      SpeedTestStatus mappedStatus = _mapState(state);
      if (mappedStatus != _status) {
        _status = mappedStatus;
        onStatusChange?.call(_status);
      }
    };
    
    _engine.onServerSelected = (server) {
      onServerSelected?.call(server);
    };

    _engine.onPingComplete = (pingResult) {
      onPing?.call(pingResult.medianPing);
      onPingDetails?.call(pingResult);
    };

    _engine.onDownloadProgress = (progress) {
      onDownloadProgress?.call(progress.transferRateMbps, progress.percent);
    };

    _engine.onUploadProgress = (progress) {
      onUploadProgress?.call(progress.transferRateMbps, progress.percent);
    };

    _engine.onCompleted = (metrics) {
      _saveResultToHistory(metrics);
      _isTesting = false;
      onCompleted?.call(metrics);
    };

    _engine.onError = (errorStr) {
      _isTesting = false;
      onError?.call(errorStr);
    };
  }

  SpeedTestStatus _mapState(EngineState state) {
    switch (state) {
      case EngineState.ready: return SpeedTestStatus.ready;
      case EngineState.selectingServer: return SpeedTestStatus.selectingServer;
      case EngineState.pinging: return SpeedTestStatus.pinging;
      case EngineState.downloading: return SpeedTestStatus.downloading;
      case EngineState.uploading: return SpeedTestStatus.uploading;
      case EngineState.completed: return SpeedTestStatus.completed;
      case EngineState.error: return SpeedTestStatus.error;
    }
  }

  void stop() {
    _isTesting = false;
    _engine.stop();
  }

  Future<void> startTest() async {
    if (_isTesting) return;
    _isTesting = true;
    _status = SpeedTestStatus.selectingServer;
    onStatusChange?.call(_status);
    await _engine.startTest();
  }

  Future<void> _saveResultToHistory(SpeedMetrics metrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('speed_test_history') ?? [];
      final newEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'ping': metrics.ping,
        'jitter': metrics.jitter,
        'packetLoss': metrics.packetLoss,
        'download': metrics.downloadSpeed,
        'upload': metrics.uploadSpeed,
        'server': metrics.server.name,
        'isp': metrics.isp,
      };
      history.add(json.encode(newEntry));
      if (history.length > 20) history.removeAt(0); // keep last 20
      await prefs.setStringList('speed_test_history', history);
    } catch (_) {}
  }
}
