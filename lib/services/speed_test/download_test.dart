import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;

class DownloadTest {
  static Future<void> runTest(String testUrl, Function(double, double) onProgress, Function(double) onComplete) async {
    final completer = Completer<void>();
    const int numWorkers = 4;
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 5);
    
    // Anti-Bot Bypass Headers
    const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36';
    httpClient.userAgent = userAgent;

    bool isRunning = true;
    int totalBytesRead = 0;
    int previousTotalBytes = 0;
    int consecutiveErrors = 0;
    
    final stopwatch = Stopwatch()..start();
    const testDuration = Duration(seconds: 10);
    const warmupDuration = Duration(seconds: 2);
    
    double smoothedSpeedMbps = 0.0;
    List<double> validSamples = [];
    final random = Random();
    
    developer.log('DownloadTest Async: Starting test with $numWorkers streams', name: 'DownloadTest');

    Future<void> startStream(int workerId) async {
      try {
        final separator = testUrl.contains('?') ? '&' : '?';
        final urlWithParam = Uri.parse('$testUrl${separator}r=${random.nextInt(1000000)}&w=$workerId');
        
        final request = await httpClient.getUrl(urlWithParam);
        request.headers.set(HttpHeaders.acceptHeader, '*/*');
        final response = await request.close();
        
        response.listen(
          (List<int> chunk) {
            if (isRunning) {
              totalBytesRead += chunk.length;
              consecutiveErrors = 0; // reset on success
            }
          },
          onError: (e) {
            developer.log('DownloadTest Async: Stream error: $e', name: 'DownloadTest');
            consecutiveErrors++;
            if (consecutiveErrors > 10 && isRunning) {
               isRunning = false;
               if (!completer.isCompleted) completer.completeError(Exception('Internet connection lost.'));
            }
          },
          cancelOnError: false,
          onDone: () {
            if (isRunning) {
               startStream(workerId);
            }
          }
        );
      } catch (e) {
        developer.log('DownloadTest Async: Connection error: $e', name: 'DownloadTest');
        if (isRunning) {
          consecutiveErrors++;
          if (consecutiveErrors > 10) {
             isRunning = false;
             if (!completer.isCompleted) completer.completeError(Exception('Internet connection lost.'));
             return;
          }
          await Future.delayed(const Duration(milliseconds: 500));
          startStream(workerId);
        }
      }
    }

    for (int i = 0; i < numWorkers; i++) {
      startStream(i);
    }

    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!isRunning) {
        timer.cancel();
        return;
      }

      int bytesDiff = totalBytesRead - previousTotalBytes;
      previousTotalBytes = totalBytesRead;
      
      double instantSpeedMbps = (bytesDiff * 8) / (250 / 1000.0) / 1000000.0;
      
      if (instantSpeedMbps.isNaN || instantSpeedMbps.isInfinite || instantSpeedMbps < 0) {
        instantSpeedMbps = 0.0;
      }

      if (smoothedSpeedMbps == 0.0 && instantSpeedMbps > 0) {
        smoothedSpeedMbps = instantSpeedMbps;
      } else {
        smoothedSpeedMbps = (smoothedSpeedMbps * 0.7) + (instantSpeedMbps * 0.3);
      }

      developer.log('DownloadTest Async: Instant: $instantSpeedMbps Mbps, Smoothed: $smoothedSpeedMbps Mbps', name: 'DownloadTest');

      if (stopwatch.elapsed > warmupDuration) {
        validSamples.add(smoothedSpeedMbps);
      }

      double percent = (stopwatch.elapsedMilliseconds / testDuration.inMilliseconds) * 100;
      if (percent > 100) percent = 100;

      onProgress(smoothedSpeedMbps, percent);

      if (stopwatch.elapsed >= testDuration) {
        isRunning = false;
        timer.cancel();
        
        double finalSpeed = smoothedSpeedMbps;
        if (validSamples.isNotEmpty) {
          validSamples.sort();
          finalSpeed = validSamples[validSamples.length ~/ 2];
        }
        
        developer.log('DownloadTest Async: Test completed. Final Median Mbps: $finalSpeed', name: 'DownloadTest');
        
        httpClient.close(force: true);
        onComplete(finalSpeed);
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }
}
