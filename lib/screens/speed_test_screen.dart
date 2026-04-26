import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

enum TestStatus { ready, downloading, uploading, completed }

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final internetSpeedTest = FlutterInternetSpeedTest();

  TestStatus _status = TestStatus.ready;
  
  double _currentRate = 0;
  String _unitText = 'Mbps';

  final List<double> _downloadData = [];
  final List<double> _uploadData = [];
  
  double _peakDownload = 0;
  double _peakUpload = 0;
  double _avgDownload = 0;
  double _avgUpload = 0;

  void _startTesting() {
    setState(() {
      _status = TestStatus.ready;
      _currentRate = 0;
      _peakDownload = 0;
      _peakUpload = 0;
      _avgDownload = 0;
      _avgUpload = 0;
      _downloadData.clear();
      _uploadData.clear();
    });

    internetSpeedTest.startTesting(
      useFastApi: true,
      fileSizeInBytes: 100 * 1024 * 1024, // 100 MB for accurate high-speed measurement
      onStarted: () {
        setState(() => _status = TestStatus.downloading);
      },
      onCompleted: (TestResult download, TestResult upload) {
        setState(() {
          _status = TestStatus.completed;
          _avgDownload = download.transferRate;
          _avgUpload = upload.transferRate;
          _currentRate = 0;
          _unitText = download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          if (data.type == TestType.download) {
            _status = TestStatus.downloading;
            _downloadData.add(data.transferRate);
            if (data.transferRate > _peakDownload) _peakDownload = data.transferRate;
            
            final smoothed = _getSmoothedData(_downloadData);
            _currentRate = smoothed.isNotEmpty ? smoothed.last : 0;
            if (smoothed.isNotEmpty) {
              _avgDownload = smoothed.reduce((a, b) => a + b) / smoothed.length;
            }
          } else {
            _status = TestStatus.uploading;
            _uploadData.add(data.transferRate);
            if (data.transferRate > _peakUpload) _peakUpload = data.transferRate;
            
            final smoothed = _getSmoothedData(_uploadData);
            _currentRate = smoothed.isNotEmpty ? smoothed.last : 0;
            if (smoothed.isNotEmpty) {
              _avgUpload = smoothed.reduce((a, b) => a + b) / smoothed.length;
            }
          }
        });
      },
      onError: (String errorMessage, String speedTestError) {
        if (mounted) {
          setState(() => _status = TestStatus.ready);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Test Failed: $errorMessage"),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onDefaultServerSelectionInProgress: () {},
      onDefaultServerSelectionDone: (Client? client) {},
      onDownloadComplete: (TestResult data) {
        setState(() {
          _avgDownload = data.transferRate;
        });
      },
      onUploadComplete: (TestResult data) {
        setState(() {
          _avgUpload = data.transferRate;
        });
      },
      onCancel: () {
        setState(() => _status = TestStatus.ready);
      },
    );
  }

  List<double> _getSmoothedData(List<double> rawData) {
    if (rawData.isEmpty) return [];
    int window = 5; // 5-point moving average
    List<double> smoothed = [];
    for (int i = 0; i < rawData.length; i++) {
      int start = math.max(0, i - window + 1);
      int count = i - start + 1;
      double sum = 0;
      for (int j = start; j <= i; j++) {
        sum += rawData[j];
      }
      smoothed.add(sum / count);
    }
    return smoothed;
  }

  String _getStatusText() {
    switch (_status) {
      case TestStatus.ready: return "READY";
      case TestStatus.downloading: return "TESTING DOWNLOAD...";
      case TestStatus.uploading: return "TESTING UPLOAD...";
      case TestStatus.completed: return "COMPLETED";
    }
  }

  Widget _buildGraph() {
    List<double> activeData = [];
    Color lineColor = AppTheme.primary;
    
    if (_status == TestStatus.downloading) {
      activeData = _getSmoothedData(_downloadData);
      lineColor = AppTheme.secondary;
    } else if (_status == TestStatus.uploading || _status == TestStatus.completed) {
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
    if (_status == TestStatus.downloading && _peakDownload > 0) maxY = _peakDownload * 1.2;
    if ((_status == TestStatus.uploading || _status == TestStatus.completed) && _peakUpload > 0) maxY = _peakUpload * 1.2;
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
    bool isTesting = _status == TestStatus.downloading || _status == TestStatus.uploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              _getStatusText(),
              style: TextStyle(
                color: _status == TestStatus.completed ? AppTheme.primary : AppTheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            
            // Circular Speed Indicator
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerLow,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: isTesting ? 0.3 : 0.1),
                    blurRadius: isTesting ? 60 : 30,
                    spreadRadius: isTesting ? 10 : 5,
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
                      _status == TestStatus.completed ? _avgDownload.toStringAsFixed(1) : _currentRate.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primary,
                        fontSize: 48,
                        shadows: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 15)],
                      ),
                    ),
                    Text(_unitText, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Live Graph
            _buildGraph(),
            const SizedBox(height: 32),

            // Detailed Metrics Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildMetricCol('DOWNLOAD', _avgDownload, _peakDownload, AppTheme.secondary)),
                        Container(width: 1, height: 60, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2)),
                        Expanded(child: _buildMetricCol('UPLOAD', _avgUpload, _peakUpload, AppTheme.tertiary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // Action Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: isTesting ? 0.0 : 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: ElevatedButton(
                onPressed: isTesting ? null : _startTesting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.surfaceVariant,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: Text(
                  isTesting ? 'TESTING IN PROGRESS' : 'START TEST',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
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
        Text('${avg.toStringAsFixed(1)} $_unitText', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('AVERAGE', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 16),
        Text('${peak.toStringAsFixed(1)} $_unitText', style: const TextStyle(color: AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('PEAK', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}
