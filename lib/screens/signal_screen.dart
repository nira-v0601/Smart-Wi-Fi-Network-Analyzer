import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wifi_analyzer/providers/network_provider.dart';
import 'package:smart_wifi_analyzer/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class SignalScreen extends StatefulWidget {
  const SignalScreen({super.key});

  @override
  State<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends State<SignalScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String getSignalStatus(int rssi) {
    if (rssi >= -50 && rssi < 0) return "Excellent 🟢";
    if (rssi >= -60 && rssi < 0) return "Good 🟡";
    if (rssi >= -70 && rssi < 0) return "Fair 🟠";
    return "Poor 🔴";
  }

  Color getSignalColor(int rssi) {
    if (rssi == 0) return AppTheme.secondary;
    if (rssi >= -50) return Colors.greenAccent;
    if (rssi >= -70) return Colors.yellowAccent;
    return AppTheme.error;
  }

  int getSignalQuality(int rssi) {
    if (rssi == 0) return 0;
    if (rssi >= -50) return 100;
    if (rssi <= -100) return 0;
    return 2 * (rssi + 100);
  }

  Widget _buildGraph(BuildContext context, List<int> rssiHistory) {
    List<FlSpot> spots = [];
    if (rssiHistory.isEmpty) {
      spots.add(const FlSpot(0, -100)); // Dummy spot to prevent FlChart crash on empty data
    } else {
      int startIdx = rssiHistory.length > 30 ? rssiHistory.length - 30 : 0;
      for (int i = startIdx; i < rssiHistory.length; i++) {
        spots.add(FlSpot((i - startIdx).toDouble(), rssiHistory[i] == 0 ? -100 : rssiHistory[i].toDouble()));
      }
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 29,
          minY: -100,
          maxY: -20,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.onSurface.withValues(alpha: 0.05),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: AppTheme.onSurface.withValues(alpha: 0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == -100 || value == -30) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${value.toInt()}', 
                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
                reservedSize: 35,
              ),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.3),
                    AppTheme.primary.withValues(alpha: 0.0),
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
    final provider = Provider.of<NetworkProvider>(context);
    final currentRssi = provider.currentRssi;
    final rssiHistory = provider.rssiHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Time Signal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulse reading
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseColor = getSignalColor(currentRssi);
                  return Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pulseColor.withValues(alpha: 0.05),
                      border: Border.all(
                        color: pulseColor.withValues(alpha: _pulseController.value * 0.8 + 0.2),
                        width: 4 + (_pulseController.value * 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: pulseColor.withValues(alpha: _pulseController.value * 0.3),
                          blurRadius: 40 * _pulseController.value,
                          spreadRadius: 10 * _pulseController.value,
                        )
                      ]
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentRssi != 0 ? '$currentRssi' : '--',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: pulseColor,
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  shadows: [BoxShadow(color: pulseColor.withValues(alpha: 0.5), blurRadius: 20)],
                                ),
                          ),
                          Text(
                            'dBm',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: pulseColor.withValues(alpha: 0.7),
                              letterSpacing: 2,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: Text(
                  currentRssi != 0 ? getSignalStatus(currentRssi) : "Scanning... ⏳",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                ),
              ),

              const SizedBox(height: 48),
              
              // Graph Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LIVE SIGNAL GRAPH',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant, 
                    fontSize: 12, 
                    letterSpacing: 2, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // FlChart Graph
              _buildGraph(context, rssiHistory),
              const SizedBox(height: 24),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }


}
