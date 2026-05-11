import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:math';

class DownloadTestConfig {
  final String url;
  final int initialStreams;
  final SendPort sendPort;

  DownloadTestConfig(this.url, this.initialStreams, this.sendPort);
}

class DownloadTest {
  static Future<void> runTest(String testUrl, Function(double, double) onProgress, Function(double) onComplete) async {
    final receivePort = ReceivePort();
    
    // We'll use 8 initial streams as requested
    final config = DownloadTestConfig(testUrl, 8, receivePort.sendPort);
    
    final isolate = await Isolate.spawn(_downloadIsolate, config);
    
    double finalSpeed = 0;
    
    await for (final message in receivePort) {
      if (message is Map) {
        if (message['type'] == 'progress') {
          onProgress(message['speed'], message['percent']);
        } else if (message['type'] == 'complete') {
          finalSpeed = message['speed'];
          receivePort.close();
          break;
        } else if (message['type'] == 'error') {
          receivePort.close();
          throw Exception(message['error']);
        }
      }
    }
    
    isolate.kill(priority: Isolate.immediate);
    onComplete(finalSpeed);
  }

  static void _downloadIsolate(DownloadTestConfig config) async {
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 5);
    
    List<HttpClientRequest> requests = [];
    List<StreamSubscription> subscriptions = [];
    
    bool isRunning = true;
    int totalBytesRead = 0;
    int previousBytesRead = 0;
    List<double> throughputSamples = [];
    
    final stopwatch = Stopwatch()..start();
    final testDuration = const Duration(seconds: 10);
    final warmupDuration = const Duration(seconds: 2);
    
    // Random parameter to prevent caching
    final random = Random();
    
    Future<void> startStream(int id) async {
      try {
        final urlWithParam = Uri.parse('${config.url}?r=${random.nextInt(1000000)}');
        final request = await httpClient.getUrl(urlWithParam);
        requests.add(request);
        
        final response = await request.close();
        
        final sub = response.listen(
          (List<int> chunk) {
            if (isRunning) {
              totalBytesRead += chunk.length;
            }
          },
          onError: (e) {
            // Ignore stream errors during test
          },
          cancelOnError: true,
        );
        subscriptions.add(sub);
      } catch (e) {
        // Stream failed to start
      }
    }

    // Start initial streams
    for (int i = 0; i < config.initialStreams; i++) {
      startStream(i);
    }
    
    // Dynamic stream scaling and progress calculation
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!isRunning) {
        timer.cancel();
        return;
      }
      
      final elapsed = stopwatch.elapsed;
      
      if (elapsed > testDuration) {
        isRunning = false;
        timer.cancel();
        
        // Calculate final sustained median speed
        double finalSpeed = 0;
        if (throughputSamples.isNotEmpty) {
          throughputSamples.sort();
          int middle = throughputSamples.length ~/ 2;
          finalSpeed = throughputSamples[middle];
        }
        
        config.sendPort.send({
          'type': 'complete',
          'speed': finalSpeed,
        });
        
        // Cleanup
        for (var sub in subscriptions) {
          sub.cancel();
        }
        for (var req in requests) {
          req.abort();
        }
        httpClient.close(force: true);
        return;
      }
      
      int bytesDiff = totalBytesRead - previousBytesRead;
      previousBytesRead = totalBytesRead;
      
      // Calculate speed in Mbps for this 250ms interval
      // bytes * 8 (bits) / 1,000,000 (Megabits) * 4 (per second since it's 250ms)
      double currentSpeedMbps = (bytesDiff * 8 / 1000000) * 4;
      
      if (elapsed > warmupDuration) {
        throughputSamples.add(currentSpeedMbps);
        
        // Scale streams if saturation is low (heuristic)
        if (currentSpeedMbps < 50 && subscriptions.length < 12) {
            startStream(subscriptions.length);
        }
      }
      
      double percent = (elapsed.inMilliseconds / testDuration.inMilliseconds) * 100;
      if (percent > 100) percent = 100;
      
      config.sendPort.send({
        'type': 'progress',
        'speed': currentSpeedMbps,
        'percent': percent,
      });
    });
  }
}
