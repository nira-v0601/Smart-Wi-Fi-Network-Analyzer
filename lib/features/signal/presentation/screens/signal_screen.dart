import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/signal_colors.dart';
import '../view_models/signal_view_model.dart';
import '../widgets/signal_bar_painter.dart';

class SignalScreen extends ConsumerStatefulWidget {
  const SignalScreen({super.key});

  @override
  ConsumerState<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends ConsumerState<SignalScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signalViewModelProvider.notifier).startMonitoring();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    try {
      ref.read(signalViewModelProvider.notifier).stopMonitoring();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signalViewModelProvider);
    final signalColor = SignalColors.fromRssi(state.currentRssi);
    final qualityLabel = SignalColors.qualityLabel(state.currentRssi);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Signal Strength',
                    style: GoogleFonts.rajdhani(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                    onPressed: () {
                      ref.read(signalViewModelProvider.notifier).startMonitoring();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLiveMeter(theme, state, signalColor, qualityLabel),
              const SizedBox(height: 32),
              _buildSignalBar(theme, state),
              const SizedBox(height: 32),
              _buildGraph(theme, state),
              const SizedBox(height: 32),
              _buildInfoRow(theme, state, qualityLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMeter(ThemeData theme, SignalState state, Color signalColor, String qualityLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: signalColor.withValues(alpha: 0.5), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: signalColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${state.currentRssi}',
                    style: GoogleFonts.rajdhani(
                      color: signalColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 72,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'dBm',
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: signalColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              qualityLabel,
              style: GoogleFonts.inter(
                color: signalColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBar(ThemeData theme, SignalState state) {
    return Column(
      children: [
        SizedBox(
          height: 24,
          width: double.infinity,
          child: CustomPaint(
            painter: SignalBarPainter(currentRssi: state.currentRssi, labelColor: theme.colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-100 dBm', style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            Text('-30 dBm', style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildGraph(ThemeData theme, SignalState state) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signal History (last 60s)',
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: -100,
                maxY: -30,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outline,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == -30 || value == -50 || value == -70 || value == -90) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: state.graphData.isEmpty ? const [FlSpot(0, -100)] : state.graphData,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        return spot == barData.spots.last;
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: theme.colorScheme.primary,
                          strokeWidth: 0,
                          strokeColor: Colors.transparent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, SignalState state, String qualityLabel) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(theme, Icons.wifi_channel, 'Network', state.ssid),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(theme, Icons.graphic_eq, 'Quality', qualityLabel),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(theme, Icons.history, 'Readings', '${state.dataPointIndex} pts'),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
