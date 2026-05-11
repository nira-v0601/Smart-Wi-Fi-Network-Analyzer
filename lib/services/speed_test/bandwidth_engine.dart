import 'dart:async';
import 'package:smart_wifi_analyzer/services/speed_test/models.dart';
import 'package:smart_wifi_analyzer/services/speed_test/server_selection.dart';
import 'package:smart_wifi_analyzer/services/speed_test/ping_test.dart';
import 'package:smart_wifi_analyzer/services/speed_test/download_test.dart';
import 'package:smart_wifi_analyzer/services/speed_test/upload_test.dart';

enum EngineState {
  ready,
  selectingServer,
  pinging,
  downloading,
  uploading,
  completed,
  error
}

class BandwidthEngine {
  EngineState _state = EngineState.ready;
  bool _isTesting = false;

  Function(EngineState)? onStateChange;
  Function(PingResult)? onPingComplete;
  Function(ProgressData)? onDownloadProgress;
  Function(ProgressData)? onUploadProgress;
  Function(SpeedMetrics)? onCompleted;
  Function(String)? onError;
  Function(ServerInfo)? onServerSelected;

  void stop() {
    _isTesting = false;
    _updateState(EngineState.ready);
  }

  void _updateState(EngineState state) {
    if (state != _state) {
      _state = state;
      onStateChange?.call(_state);
    }
  }

  Future<void> startTest() async {
    if (_isTesting) return;
    _isTesting = true;

    try {
      // 1. Server Selection
      _updateState(EngineState.selectingServer);
      final server = await ServerSelection.findBestServer();
      if (!_isTesting) return;
      onServerSelected?.call(server);

      // 2. Ping Test
      _updateState(EngineState.pinging);
      final pingResult = await PingTest.measurePing(server.host);
      if (!_isTesting) return;
      onPingComplete?.call(pingResult);

      // 3. Download Test
      _updateState(EngineState.downloading);
      double finalDownload = 0;
      await DownloadTest.runTest(
        server.url,
        (speed, percent) {
          if (_isTesting) {
            onDownloadProgress?.call(ProgressData(transferRateMbps: speed, percent: percent));
          }
        },
        (speed) {
          finalDownload = speed;
        },
      );
      if (!_isTesting) return;

      // 4. Upload Test
      _updateState(EngineState.uploading);
      double finalUpload = 0;
      await UploadTest.runTest(
        server.url, // Using same endpoint for POST upload
        (speed, percent) {
          if (_isTesting) {
            onUploadProgress?.call(ProgressData(transferRateMbps: speed, percent: percent));
          }
        },
        (speed) {
          finalUpload = speed;
        },
      );
      if (!_isTesting) return;

      // 5. Completion
      _updateState(EngineState.completed);
      final metrics = SpeedMetrics(
        ping: pingResult.medianPing,
        jitter: pingResult.jitter,
        packetLoss: pingResult.packetLoss,
        downloadSpeed: finalDownload,
        uploadSpeed: finalUpload,
        server: server,
        isp: 'Auto-detected ISP', // This could be fetched from an IP API if needed
      );
      
      onCompleted?.call(metrics);
      _isTesting = false;

    } catch (e) {
      _isTesting = false;
      _updateState(EngineState.error);
      onError?.call(e.toString());
    }
  }
}
