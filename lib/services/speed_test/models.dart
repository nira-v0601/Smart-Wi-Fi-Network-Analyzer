import 'package:flutter/foundation.dart';

class ServerInfo {
  final String name;
  final String host;
  final String url;
  final double latitude;
  final double longitude;

  const ServerInfo({
    required this.name,
    required this.host,
    required this.url,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}

class SpeedMetrics {
  final double ping;
  final double jitter;
  final double packetLoss;
  final double downloadSpeed;
  final double uploadSpeed;
  final ServerInfo server;
  final String isp;

  const SpeedMetrics({
    this.ping = 0,
    this.jitter = 0,
    this.packetLoss = 0,
    this.downloadSpeed = 0,
    this.uploadSpeed = 0,
    required this.server,
    this.isp = 'Unknown ISP',
  });
}

class ProgressData {
  final double transferRateMbps;
  final double percent;
  
  const ProgressData({
    required this.transferRateMbps,
    required this.percent,
  });
}
