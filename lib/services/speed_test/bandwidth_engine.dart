import 'dart:io';
import 'package:smart_wifi_analyzer/services/speed_test/models.dart';
import 'package:smart_wifi_analyzer/services/speed_test/server_selection.dart';
import 'package:smart_wifi_analyzer/services/speed_test/ping_test.dart';
import 'package:smart_wifi_analyzer/services/speed_test/download_test.dart';
import 'package:smart_wifi_analyzer/services/speed_test/upload_test.dart';
import 'dart:developer' as developer;

enum EngineState { ready, selectingServer, pinging, downloading, uploading, completed, error }

class BandwidthEngine {
  EngineState _state = EngineState.ready;
  bool _isTesting = false;

  Function(EngineState)? onStateChange;
  Function(ServerInfo)? onServerSelected;
  Function(PingResult)? onPingComplete;
  Function(ProgressData)? onDownloadProgress;
  Function(ProgressData)? onUploadProgress;
  Function(SpeedMetrics)? onCompleted;
  Function(String)? onError;

  void _setState(EngineState state) {
    _state = state;
    onStateChange?.call(_state);
  }

  void stop() {
    _isTesting = false;
    _setState(EngineState.ready);
  }

  Future<void> startTest() async {
    if (_isTesting) return;
    _isTesting = true;

    try {
      _setState(EngineState.selectingServer);

      try {
        final result = await InternetAddress.lookup('cloudflare.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No active internet connection');
        }
      } catch (_) {
        throw Exception('No active internet connection');
      }

      final server = await ServerSelection.findBestServer();
      if (!_isTesting) return;
      onServerSelected?.call(server);

      _setState(EngineState.pinging);
      final pingResult = await PingTest.measurePing(server.host);
      if (!_isTesting) return;
      onPingComplete?.call(pingResult);

      _setState(EngineState.downloading);
      double finalDownloadSpeed = 0;
      await DownloadTest.runTest(
        server.downloadUrl,
        (speed, percent) {
          if (_isTesting) onDownloadProgress?.call(ProgressData(transferRateMbps: speed, percent: percent));
        },
        (finalSpeed) {
          finalDownloadSpeed = finalSpeed;
        },
      );
      if (!_isTesting) return;

      _setState(EngineState.uploading);
      double finalUploadSpeed = 0;
      await UploadTest.runTest(
        server.uploadUrl,
        (speed, percent) {
          if (_isTesting) onUploadProgress?.call(ProgressData(transferRateMbps: speed, percent: percent));
        },
        (finalSpeed) {
          finalUploadSpeed = finalSpeed;
        },
      );
      if (!_isTesting) return;

      _setState(EngineState.completed);
      
      final metrics = SpeedMetrics(
        ping: pingResult.medianPing,
        jitter: pingResult.jitter,
        packetLoss: pingResult.packetLoss,
        downloadSpeed: finalDownloadSpeed,
        uploadSpeed: finalUploadSpeed,
        server: server,
        isp: 'Auto-detected',
      );
      
      onCompleted?.call(metrics);
      _isTesting = false;

    } catch (e) {
      developer.log('BandwidthEngine Error: $e', name: 'BandwidthEngine');
      onError?.call('An unexpected error occurred during the test: $e');
      _setState(EngineState.error);
      _isTesting = false;
    }
  }
}
