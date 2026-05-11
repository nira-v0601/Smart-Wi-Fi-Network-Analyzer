import 'dart:io';
import 'dart:math';

class PingResult {
  final double medianPing;
  final double jitter;
  final double packetLoss;

  PingResult({
    required this.medianPing,
    required this.jitter,
    required this.packetLoss,
  });
}

class PingTest {
  static Future<PingResult> measurePing(String host, {int attempts = 10}) async {
    List<double> pings = [];
    int lostPackets = 0;

    for (int i = 0; i < attempts; i++) {
      try {
        final stopwatch = Stopwatch()..start();
        final socket = await Socket.connect(host, 443, timeout: const Duration(seconds: 2));
        stopwatch.stop();
        socket.destroy();
        pings.add(stopwatch.elapsedMilliseconds.toDouble());
      } catch (_) {
        lostPackets++;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }

    double packetLoss = (lostPackets / attempts) * 100;

    if (pings.isEmpty) {
      return PingResult(medianPing: 0, jitter: 0, packetLoss: packetLoss);
    }

    if (pings.length > 2) {
      pings.sort();
      pings.removeAt(0); // Remove lowest
      pings.removeLast(); // Remove highest
    }

    // Calculate median
    pings.sort();
    double medianPing = 0;
    if (pings.isNotEmpty) {
      int middle = pings.length ~/ 2;
      if (pings.length % 2 == 1) {
        medianPing = pings[middle];
      } else {
        medianPing = (pings[middle - 1] + pings[middle]) / 2.0;
      }
    }

    // Calculate jitter
    double jitter = 0;
    if (pings.length > 1) {
      double sumDiff = 0;
      for (int i = 1; i < pings.length; i++) {
        sumDiff += (pings[i] - pings[i - 1]).abs();
      }
      jitter = sumDiff / (pings.length - 1);
    }

    return PingResult(
      medianPing: medianPing,
      jitter: jitter,
      packetLoss: packetLoss,
    );
  }
}
