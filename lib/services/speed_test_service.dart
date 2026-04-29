import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TestServer {
  final String name;
  final String pingUrl;
  final String downloadUrl;
  final String uploadUrl;
  
  TestServer(this.name, this.pingUrl, this.downloadUrl, this.uploadUrl);
}

enum SpeedTestStatus { ready, selectingServer, pinging, downloading, uploading, completed, error }

class SpeedTestService {
  final int _durationSeconds = 10;
  final int _parallelConnections = 4;
  
  final List<TestServer> _servers = [
    TestServer("Cloudflare Global", "https://speed.cloudflare.com/__down?bytes=0", "https://speed.cloudflare.com/__down?bytes=50000000", "https://speed.cloudflare.com/__up"),
    TestServer("Tele2 EU", "http://speedtest.tele2.net/", "http://speedtest.tele2.net/100MB.zip", "http://speedtest.tele2.net/upload.php"),
  ];
  
  TestServer? _selectedServer;

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
    _updateStatus(SpeedTestStatus.ready);
  }

  void _updateStatus(SpeedTestStatus status) {
    _status = status;
    onStatusChange?.call(_status);
  }

  Future<T> _retry<T>(Future<T> Function() task, {int maxRetries = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        return await task();
      } catch (e) {
        attempts++;
        if (attempts > maxRetries || !_isTesting) {
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> startTest() async {
    if (_isTesting) return;
    _isTesting = true;
    _ping = 0;
    _finalDownload = 0;
    _finalUpload = 0;

    try {
      // 0. Server Selection
      _updateStatus(SpeedTestStatus.selectingServer);
      await _retry(() => _selectBestServer(), maxRetries: 2);
      if (!_isTesting || _selectedServer == null) return;

      // 1. Ping
      _updateStatus(SpeedTestStatus.pinging);
      _ping = await _retry(() => _measureMedianPing(_selectedServer!.pingUrl, samples: 10), maxRetries: 2);
      if (!_isTesting) return;
      onPing?.call(_ping);

      if (_ping < 0) {
        throw Exception("Failed to reach test server (Ping failed).");
      }

      // 2. Download
      _updateStatus(SpeedTestStatus.downloading);
      _finalDownload = await _retry(() => _runDownloadTest(_selectedServer!.downloadUrl), maxRetries: 2);
      if (!_isTesting) return;

      // 3. Upload
      _updateStatus(SpeedTestStatus.uploading);
      _finalUpload = await _retry(() => _runUploadTest(_selectedServer!.uploadUrl), maxRetries: 2);
      if (!_isTesting) return;

      // Completed
      _updateStatus(SpeedTestStatus.completed);
      onCompleted?.call(_ping, _finalDownload, _finalUpload);
      _saveResultToHistory(_ping, _finalDownload, _finalUpload);
    } catch (e) {
      _isTesting = false;
      _updateStatus(SpeedTestStatus.error);
      onError?.call("Network unstable, retry");
    } finally {
      _isTesting = false;
    }
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

  Future<void> _selectBestServer() async {
    double bestPing = double.infinity;
    TestServer? bestServer;

    for (var server in _servers) {
      if (!_isTesting) break;
      double median = await _measureMedianPing(server.pingUrl, samples: 5);
      if (median > 0 && median < bestPing) {
        bestPing = median;
        bestServer = server;
      }
    }
    
    if (bestServer != null) {
      _selectedServer = bestServer;
    } else {
      _selectedServer = _servers.first;
    }
  }

  Future<double> _measureMedianPing(String url, {int samples = 7}) async {
    List<double> pings = [];

    for (int i = 0; i < samples; i++) {
      if (!_isTesting) break;
      final sw = Stopwatch()..start();
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
        sw.stop();
        if (res.statusCode == 200 || res.statusCode == 301 || res.statusCode == 302) {
          pings.add(sw.elapsedMilliseconds.toDouble());
        }
      } catch (_) {}
    }

    if (pings.isEmpty) return -1;
    pings.sort();
    
    // Ignore outliers (top 20% highest values)
    int removeCount = (samples * 0.2).ceil();
    if (pings.length > removeCount + 1) {
      pings.removeRange(pings.length - removeCount, pings.length);
    }
    
    return pings[pings.length ~/ 2]; // Median
  }

  Future<double> _runDownloadTest(String downloadUrl) async {
    int totalBytes = 0;
    final List<http.Client> clients = [];
    final List<StreamSubscription> subscriptions = [];
    final sw = Stopwatch()..start();
    
    bool isDone = false;
    double maxSpeed = 0;

    Timer progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!isDone) {
        double seconds = sw.elapsedMilliseconds / 1000.0;
        if (seconds > 0) {
          double mbps = ((totalBytes * 8) / 1000000) / seconds;
          if (mbps > maxSpeed) maxSpeed = mbps;
          onDownloadProgress?.call(mbps);
        }
      }
    });

    for (int i = 0; i < _parallelConnections; i++) {
      final client = http.Client();
      clients.add(client);
      
      _startDownloadStream(client, downloadUrl, (bytes) {
        totalBytes += bytes;
      }, subscriptions);
    }

    // Wait for the duration
    int waitMs = _durationSeconds * 1000;
    while (_isTesting && sw.elapsedMilliseconds < waitMs) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    isDone = true;
    progressTimer.cancel();
    
    for (var sub in subscriptions) {
      sub.cancel();
    }
    for (var client in clients) {
      client.close();
    }

    double finalSeconds = sw.elapsedMilliseconds / 1000.0;
    double finalMbps = ((totalBytes * 8) / 1000000) / finalSeconds;
    
    // In case average is lower than sustained max due to ramp-up, use a blend or max.
    // For realism, let's just return the mathematically correct average.
    return finalMbps;
  }

  void _startDownloadStream(http.Client client, String url, Function(int) onData, List<StreamSubscription> subscriptions) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      
      final sub = response.stream.listen((chunk) {
        onData(chunk.length);
      }, onError: (_) {}, cancelOnError: true);
      
      subscriptions.add(sub);
    } catch (_) {}
  }

  Future<double> _runUploadTest(String uploadUrl) async {
    int totalBytes = 0;
    final List<http.Client> clients = [];
    final List<bool> activeUploads = [];
    final sw = Stopwatch()..start();
    
    bool isDone = false;
    double maxSpeed = 0;

    // Generate dummy payload (5MB)
    final dummyData = Uint8List(5 * 1024 * 1024);
    final random = math.Random();
    for (int i = 0; i < dummyData.length; i++) {
      dummyData[i] = random.nextInt(256);
    }

    Timer progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!isDone) {
        double seconds = sw.elapsedMilliseconds / 1000.0;
        if (seconds > 0) {
          double mbps = ((totalBytes * 8) / 1000000) / seconds;
          if (mbps > maxSpeed) maxSpeed = mbps;
          onUploadProgress?.call(mbps);
        }
      }
    });

    for (int i = 0; i < _parallelConnections; i++) {
      final client = http.Client();
      clients.add(client);
      activeUploads.add(true);
      
      _startUploadLoop(client, uploadUrl, dummyData, (bytes) {
        if (!isDone) totalBytes += bytes;
      }, () {
        if (_isTesting && !isDone) {
           // If it finishes before time, we can restart it.
           // For simplicity, just count the bytes that successfully transmitted.
        }
      });
    }

    int waitMs = _durationSeconds * 1000;
    while (_isTesting && sw.elapsedMilliseconds < waitMs) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    isDone = true;
    progressTimer.cancel();
    
    for (var client in clients) {
      client.close(); // Interrupts uploads
    }

    double finalSeconds = sw.elapsedMilliseconds / 1000.0;
    double finalMbps = ((totalBytes * 8) / 1000000) / finalSeconds;
    
    return finalMbps;
  }

  void _startUploadLoop(http.Client client, String url, Uint8List data, Function(int) onSent, VoidCallback onDone) async {
    while (_isTesting) {
      try {
        final request = http.Request('POST', Uri.parse(url));
        request.bodyBytes = data;
        
        // Wait for response to confirm sent. Actually, measuring upload speed accurately requires streaming.
        // We can use http.ByteStream but Flutter http package buffers. 
        // For accurate upload, counting when request completes is rough. 
        // To approximate, we count size sent after success.
        final response = await client.send(request);
        if (response.statusCode == 200) {
           onSent(data.length);
        }
      } catch (_) {
        break; // Stop if cancelled or error
      }
    }
    onDone();
  }
}
