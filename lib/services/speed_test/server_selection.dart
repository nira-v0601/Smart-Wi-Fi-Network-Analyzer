import 'dart:io';
import 'dart:async';
import 'package:smart_wifi_analyzer/services/speed_test/models.dart';
import 'dart:developer' as developer;

class ServerSelection {
  static const List<ServerInfo> fallbackServers = [
    ServerInfo(
      name: 'Tele2 Speedtest',
      host: 'speedtest.tele2.net',
      downloadUrl: 'http://speedtest.tele2.net/100MB.zip',
      uploadUrl: 'http://speedtest.tele2.net/upload.php',
    ),
    ServerInfo(
      name: 'ThinkBroadband',
      host: 'ipv4.download.thinkbroadband.com',
      downloadUrl: 'http://ipv4.download.thinkbroadband.com/100MB.zip',
      uploadUrl: 'http://ipv4.download.thinkbroadband.com/100MB.zip',
    ),
    ServerInfo(
      name: 'Cloudflare Edge',
      host: 'speed.cloudflare.com',
      downloadUrl: 'https://speed.cloudflare.com/__down?bytes=50000000',
      uploadUrl: 'https://speed.cloudflare.com/__up',
    ),
  ];

  static Future<ServerInfo> findBestServer() async {
    ServerInfo bestServer = fallbackServers.first;
    double lowestLatency = double.infinity;

    for (final server in fallbackServers) {
      try {
        final stopwatch = Stopwatch()..start();
        int port = server.downloadUrl.startsWith('https') ? 443 : 80;
        final socket = await Socket.connect(server.host, port, timeout: const Duration(seconds: 2));
        stopwatch.stop();
        socket.destroy();

        double latency = stopwatch.elapsedMilliseconds.toDouble();
        developer.log('ServerSelection: ${server.name} latency = $latency ms', name: 'ServerSelection');
        
        if (latency < lowestLatency) {
          lowestLatency = latency;
          bestServer = server;
        }
      } catch (e) {
        developer.log('ServerSelection: Failed to connect to ${server.name}: $e', name: 'ServerSelection');
      }
    }

    if (lowestLatency == double.infinity) {
      throw Exception('No internet connection. All servers unreachable.');
    }

    developer.log('ServerSelection: Best server selected = ${bestServer.name}', name: 'ServerSelection');
    return bestServer;
  }
}
