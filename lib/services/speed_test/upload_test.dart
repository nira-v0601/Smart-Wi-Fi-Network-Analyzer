import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class UploadTestConfig {
  final String url;
  final int streams;
  final SendPort sendPort;

  UploadTestConfig(this.url, this.streams, this.sendPort);
}

class UploadTest {
  static Future<void> runTest(String testUrl, Function(double, double) onProgress, Function(double) onComplete) async {
    final receivePort = ReceivePort();
    
    // We'll use 4-6 streams for upload
    final config = UploadTestConfig(testUrl, 4, receivePort.sendPort);
    
    final isolate = await Isolate.spawn(_uploadIsolate, config);
    
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

  static void _uploadIsolate(UploadTestConfig config) async {
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 5);
    
    List<HttpClientRequest> requests = [];
    
    bool isRunning = true;
    int totalBytesWritten = 0;
    int previousBytesWritten = 0;
    List<double> throughputSamples = [];
    
    final stopwatch = Stopwatch()..start();
    final testDuration = const Duration(seconds: 10);
    final warmupDuration = const Duration(seconds: 2);
    
    final random = Random();
    
    // Generate a 1MB payload in memory
    final payload = Uint8List(1024 * 1024);
    for (int i = 0; i < payload.length; i++) {
      payload[i] = random.nextInt(256);
    }
    
    Future<void> startStream() async {
      try {
        final urlWithParam = Uri.parse('${config.url}?r=${random.nextInt(1000000)}');
        final request = await httpClient.postUrl(urlWithParam);
        request.headers.contentLength = -1; // Chunked transfer
        requests.add(request);
        
        // Continuously write payload to stream while running
        while (isRunning) {
          request.add(payload);
          await request.flush(); // ensure it gets sent
          totalBytesWritten += payload.length;
          // small delay to prevent blocking the isolate loop entirely
          await Future.delayed(const Duration(milliseconds: 10)); 
        }
        
        await request.close();
      } catch (e) {
        // Stream failed or closed
      }
    }

    // Start upload streams
    for (int i = 0; i < config.streams; i++) {
      startStream();
    }
    
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!isRunning) {
        timer.cancel();
        return;
      }
      
      final elapsed = stopwatch.elapsed;
      
      if (elapsed > testDuration) {
        isRunning = false;
        timer.cancel();
        
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
        
        for (var req in requests) {
          req.abort();
        }
        httpClient.close(force: true);
        return;
      }
      
      int bytesDiff = totalBytesWritten - previousBytesWritten;
      previousBytesWritten = totalBytesWritten;
      
      double currentSpeedMbps = (bytesDiff * 8 / 1000000) * 4;
      
      if (elapsed > warmupDuration) {
        throughputSamples.add(currentSpeedMbps);
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
