import 'dart:io';
import 'dart:async';
import 'package:smart_wifi_analyzer/services/speed_test/models.dart';

class ServerSelection {
  static const List<ServerInfo> fallbackServers = [
    ServerInfo(
      name: 'Cloudflare',
      host: 'cloudflare.com',
      url: 'https://cloudflare.com/cdn-cgi/trace',
    ),
    ServerInfo(
      name: 'Google',
      host: 'google.com',
      url: 'https://google.com/generate_204',
    ),
    ServerInfo(
      name: 'Apple',
      host: 'apple.com',
      url: 'https://apple.com/library/test/success.html',
    ),
  ];

  static Future<ServerInfo> findBestServer() async {
    ServerInfo bestServer = fallbackServers.first;
    double lowestLatency = double.infinity;

    for (final server in fallbackServers) {
      try {
        final stopwatch = Stopwatch()..start();
        final socket = await Socket.connect(server.host, 443, timeout: const Duration(seconds: 2));
        stopwatch.stop();
        socket.destroy();

        double latency = stopwatch.elapsedMilliseconds.toDouble();
        if (latency < lowestLatency) {
          lowestLatency = latency;
          bestServer = server;
        }
      } catch (_) {
        // Ignore unreachable servers
      }
    }

    return bestServer;
  }
}
