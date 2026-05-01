import 'package:flutter/material.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:smart_wifi_analyzer/services/speed_test_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final speedTestService = SpeedTestService();

  SpeedTestStatus _status = SpeedTestStatus.ready;
  
  double _currentRate = 0;
  double _currentPercent = 0;
  final String _unitText = 'Mbps';

  final List<double> _downloadData = [];
  final List<double> _uploadData = [];
  
  double _peakDownload = 0;
  double _peakUpload = 0;
  double _avgDownload = 0;
  double _avgUpload = 0;
  double _ping = 0;

  @override
  void initState() {
    super.initState();
    speedTestService.onStatusChange = (status) {
      if (mounted) setState(() => _status = status);
    };
    speedTestService.onPing = (ping) {
      if (mounted) setState(() => _ping = ping);
    };
    speedTestService.onDownloadProgress = (speed, percent) {
      if (mounted) {
        setState(() {
          _currentRate = speed;
          _currentPercent = percent;
          _downloadData.add(speed);
          if (speed > _peakDownload) _peakDownload = speed;
          // Dynamically compute average up to this point
          if (_downloadData.isNotEmpty) {
             _avgDownload = _downloadData.reduce((a, b) => a + b) / _downloadData.length;
          }
        });
      }
    };
    speedTestService.onUploadProgress = (speed, percent) {
      if (mounted) {
        setState(() {
          _currentRate = speed;
          _currentPercent = percent;
          _uploadData.add(speed);
          if (speed > _peakUpload) _peakUpload = speed;
          // Dynamically compute average up to this point
          if (_uploadData.isNotEmpty) {
             _avgUpload = _uploadData.reduce((a, b) => a + b) / _uploadData.length;
          }
        });
      }
    };
    speedTestService.onCompleted = (ping, dl, ul) {
      if (mounted) {
        setState(() {
          _ping = ping;
          _avgDownload = dl;
          _avgUpload = ul;
          _currentRate = 0;
          _currentPercent = 100;
        });
      }
    };
    speedTestService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Test Failed: $error"),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    speedTestService.stop();
    super.dispose();
  }

  void _startTesting() {
    setState(() {
      _currentRate = 0;
      _currentPercent = 0;
      _peakDownload = 0;
      _peakUpload = 0;
      _avgDownload = 0;
      _avgUpload = 0;
      _ping = 0;
      _downloadData.clear();
      _uploadData.clear();
    });
    speedTestService.startTest();
  }


  String _getStatusText() {
    switch (_status) {
      case SpeedTestStatus.ready: return "READY";
      case SpeedTestStatus.selectingServer: return "SELECTING SERVER...";
      case SpeedTestStatus.pinging: return "MEASURING PING...";
      case SpeedTestStatus.downloading: return "TESTING DOWNLOAD...";
      case SpeedTestStatus.uploading: return "TESTING UPLOAD...";
      case SpeedTestStatus.completed: return "COMPLETED";
      case SpeedTestStatus.error: return "TEST FAILED";
    }
  }

  Widget _buildGraph() {
    List<double> activeData = [];
    Color lineColor = AppTheme.primary;
    
    if (_status == SpeedTestStatus.downloading) {
      activeData = _getSmoothedData(_downloadData);
      lineColor = AppTheme.secondary;
    } else if (_status == SpeedTestStatus.uploading || _status == SpeedTestStatus.completed) {
      activeData = _getSmoothedData(_uploadData);
      lineColor = AppTheme.tertiary;
    }

    List<FlSpot> spots = [];
    if (activeData.isEmpty) {
      spots.add(const FlSpot(0, 0));
    } else {
      for (int i = 0; i < activeData.length; i++) {
        spots.add(FlSpot(i.toDouble(), activeData[i]));
      }
    }

    double maxY = 100;
    if (_status == SpeedTestStatus.downloading && _peakDownload > 0) maxY = _peakDownload * 1.2;
    if ((_status == SpeedTestStatus.uploading || _status == SpeedTestStatus.completed) && _peakUpload > 0) maxY = _peakUpload * 1.2;
    if (maxY < 10) maxY = 10;

    return Container(
      height: 120,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(20, activeData.length.toDouble()),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.3),
                    lineColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding, vertical: 16.0),
          child: Column(
            children: [
              _buildUnifiedStage(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedStage() {
    return Column(
      children: [
        if (_status == SpeedTestStatus.error)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: AppTheme.cardDecoration(AppTheme.error),
            child: const Text(
              "Test Failed. Please check your connection and try again.",
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        Text(
          _getStatusText(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceContainerLow,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 60,
                spreadRadius: 10,
              )
            ]
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, color: AppTheme.secondary.withValues(alpha: 0.8), size: 32),
                const SizedBox(height: 8),
                Text(
                  _currentRate.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: 48,
                    shadows: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 15)],
                  ),
                ),
                Text(_unitText, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, letterSpacing: 2)),
                const SizedBox(height: 8),
                if (_status == SpeedTestStatus.downloading || _status == SpeedTestStatus.uploading)
                  Text('${_currentPercent.toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_status == SpeedTestStatus.downloading || _status == SpeedTestStatus.uploading || _status == SpeedTestStatus.completed)
          _buildGraph(),
        if (_status == SpeedTestStatus.downloading || _status == SpeedTestStatus.uploading || _status == SpeedTestStatus.completed)
          const SizedBox(height: 32),
        _buildMetricsGrid(),
        const SizedBox(height: 48),
        if (_status == SpeedTestStatus.ready || _status == SpeedTestStatus.error || _status == SpeedTestStatus.completed)
          _buildActionButton(_status == SpeedTestStatus.completed ? "TEST AGAIN" : "START TEST", _startTesting),
      ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration(AppTheme.primary),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.network_ping, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'PING: ${_ping > 0 ? _ping.toStringAsFixed(0) : '--'} ms',
                style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, width: double.infinity, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildMetricCol('DOWNLOAD', _avgDownload, _peakDownload, AppTheme.secondary)),
              Container(width: 1, height: 60, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2)),
              Expanded(child: _buildMetricCol('UPLOAD', _avgUpload, _peakUpload, AppTheme.tertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String title, double avg, double peak, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(title == 'DOWNLOAD' ? Icons.download : Icons.upload, size: 16, color: color),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 16),
        Text('${avg > 0 ? avg.toStringAsFixed(1) : '--'} $_unitText', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('AVERAGE', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 16),
        Text('${peak > 0 ? peak.toStringAsFixed(1) : '--'} $_unitText', style: const TextStyle(color: AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('PEAK', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }

  List<double> _getSmoothedData(List<double> rawData) {
    if (rawData.isEmpty) return [];
    List<double> smoothed = [];
    double previous = rawData.first;
    smoothed.add(previous);

    for (int i = 1; i < rawData.length; i++) {
      double current = rawData[i];
      
      // Clamp changes > 50% between frames
      if (current > previous * 1.5) {
        current = previous * 1.5;
      } else if (previous > 0 && current < previous * 0.5) {
        current = previous * 0.5;
      }
      
      // Exponential Moving Average
      double smoothedValue = (previous * 0.7) + (current * 0.3);
      smoothed.add(smoothedValue);
      previous = smoothedValue;
    }
    
    // Keep time-series buffer (last 20 values) as requested
    if (smoothed.length > 20) {
      smoothed = smoothed.sublist(smoothed.length - 20);
    }
    
    return smoothed;
  }
}
