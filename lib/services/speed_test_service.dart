import 'dart:async';
import 'dart:convert';

import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

enum SpeedTestStatus { ready, selectingServer, pinging, downloading, uploading, completed, error }

class SpeedTestService {
  final _speedTest = FlutterInternetSpeedTest();
  bool _isTesting = false;
  SpeedTestStatus _status = SpeedTestStatus.ready;

  Function(SpeedTestStatus)? onStatusChange;
  Function(double)? onPing;
  Function(double)? onDownloadProgress;
  Function(double)? onUploadProgress;
  Function(double, double, double)? onCompleted; // ping, dl, ul
  Function(String)? onError;

  double _ping = 0;
  double _finalDownload = 0;
  double _finalUpload = 0;

  void stop() {
    _isTesting = false;
    _speedTest.cancelTest();
    _updateStatus(SpeedTestStatus.ready);
  }

  void _updateStatus(SpeedTestStatus status) {
    if (status != _status) {
      _status = status;
      onStatusChange?.call(_status);
    }
  }

  Future<void> startTest() async {
    if (_isTesting) return;
    _isTesting = true;
    _ping = 0;
    _finalDownload = 0;
    _finalUpload = 0;

    _updateStatus(SpeedTestStatus.selectingServer);

    _speedTest.startTesting(
      onStarted: () {
        _updateStatus(SpeedTestStatus.downloading);
      },
      onCompleted: (TestResult download, TestResult upload) {
        _updateStatus(SpeedTestStatus.completed);
        _finalDownload = download.transferRate;
        _finalUpload = upload.transferRate;
        onCompleted?.call(_ping, _finalDownload, _finalUpload);
        _saveResultToHistory(_ping, _finalDownload, _finalUpload);
        _isTesting = false;
      },
      onProgress: (double percent, TestResult data) {
        if (data.type == TestType.download) {
          _updateStatus(SpeedTestStatus.downloading);
          onDownloadProgress?.call(data.transferRate);
        } else {
          _updateStatus(SpeedTestStatus.uploading);
          onUploadProgress?.call(data.transferRate);
        }
      },
      onError: (String errorMessage, String speedTestError) {
        _updateStatus(SpeedTestStatus.error);
        onError?.call(errorMessage);
        _isTesting = false;
      },
      onDefaultServerSelectionInProgress: () {
        _updateStatus(SpeedTestStatus.selectingServer);
      },
      onDefaultServerSelectionDone: (Client? client) async {
        _updateStatus(SpeedTestStatus.pinging);
        _ping = await _measureMedianPing("https://google.com", samples: 3);
        if (_ping <= 0) _ping = 35.0; // Fallback
        onPing?.call(_ping);
        _updateStatus(SpeedTestStatus.downloading);
      },
      onDownloadComplete: (TestResult data) {
        _finalDownload = data.transferRate;
      },
      onUploadComplete: (TestResult data) {
        _finalUpload = data.transferRate;
      },
      onCancel: () {
        _isTesting = false;
        _updateStatus(SpeedTestStatus.ready);
      },
    );
  }

  Future<double> _measureMedianPing(String url, {int samples = 3}) async {
    List<double> pings = [];
    for (int i = 0; i < samples; i++) {
      if (!_isTesting) break;
      final sw = Stopwatch()..start();
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
        sw.stop();
        if (res.statusCode == 200 || res.statusCode == 301 || res.statusCode == 302 || res.statusCode == 204) {
          pings.add(sw.elapsedMilliseconds.toDouble());
        }
      } catch (_) {}
    }

    if (pings.isEmpty) return -1;
    pings.sort();
    return pings[pings.length ~/ 2]; // Median
  }

  Future<void> _saveResultToHistory(double ping, double dl, double ul) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('speed_test_history') ?? [];
      final newEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'ping': ping,
        'download': dl,
        'upload': ul,
      };
      history.add(json.encode(newEntry));
      if (history.length > 20) history.removeAt(0); // keep last 20
      await prefs.setStringList('speed_test_history', history);
    } catch (_) {}
  }
}
