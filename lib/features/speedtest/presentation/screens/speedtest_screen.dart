import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../view_models/speedtest_view_model.dart';
import '../widgets/metric_card.dart';
import '../widgets/speedometer_painter.dart';

class SpeedtestScreen extends ConsumerStatefulWidget {
  const SpeedtestScreen({super.key});

  @override
  ConsumerState<SpeedtestScreen> createState() => _SpeedtestScreenState();
}

class _SpeedtestScreenState extends ConsumerState<SpeedtestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(speedtestViewModelProvider);
    final viewModel = ref.read(speedtestViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Speed Test',
          style: GoogleFonts.rajdhani(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _buildSpeedometer(theme, state, viewModel),
                ),
              ),
              const SizedBox(height: 24),
              if (state.phase != SpeedTestPhase.idle) _buildStatsRow(state),
              const SizedBox(height: 24),
              if (state.phase == SpeedTestPhase.testingDownload ||
                  state.phase == SpeedTestPhase.testingUpload)
                _buildProgressIndicators(state),
              const SizedBox(height: 32),
              _buildActionBtn(state, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedometer(ThemeData theme, SpeedtestState state, SpeedtestViewModel viewModel) {
    double percent = 0.0;
    Color activeColor = theme.colorScheme.primary;
    bool useGradient = false;

    if (state.phase == SpeedTestPhase.testingDownload) {
      percent = state.downloadProgress;
      activeColor = theme.colorScheme.primary;
    } else if (state.phase == SpeedTestPhase.testingUpload) {
      percent = state.uploadProgress;
      activeColor = theme.colorScheme.secondary;
    } else if (state.phase == SpeedTestPhase.complete) {
      percent = 1.0;
      useGradient = true;
    } else if (state.phase == SpeedTestPhase.testingPing) {
      percent = 0.0; // no arc yet
    }

    return InkWell(
      onTap: state.phase == SpeedTestPhase.idle || state.phase == SpeedTestPhase.complete || state.phase == SpeedTestPhase.error
          ? () => viewModel.startTest()
          : null,
      borderRadius: BorderRadius.circular(150),
      child: Container(
        width: 300,
        height: 300,
        padding: const EdgeInsets.all(16.0),
        child: CustomPaint(
          painter: SpeedometerPainter(
            percent: percent,
            activeColor: activeColor,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            useGradient: useGradient,
          ),
          child: Center(
            child: _buildSpeedometerCenterContent(theme, state),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedometerCenterContent(ThemeData theme, SpeedtestState state) {
    if (state.phase == SpeedTestPhase.idle || state.phase == SpeedTestPhase.error) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 48, color: theme.colorScheme.primary.withAlpha(150)),
          const SizedBox(height: 16),
          Text(
            state.phase == SpeedTestPhase.error ? 'TEST FAILED\nTAP TO RETRY' : 'TAP TO START',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      );
    }

    if (state.phase == SpeedTestPhase.testingPing) {
      return FadeTransition(
        opacity: _pulseController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_tethering, size: 48, color: theme.colorScheme.tertiary),
            const SizedBox(height: 16),
            Text(
              'PING\nTesting...',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final isUpload = state.phase == SpeedTestPhase.testingUpload;
    final isComplete = state.phase == SpeedTestPhase.complete;
    final speedValue = isUpload ? state.uploadSpeed : state.downloadSpeed;
    final valueColor = isUpload ? theme.colorScheme.secondary : theme.colorScheme.primary;
    final labelText = isUpload ? '↑ Upload' : '↓ Download';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isComplete) ...[
          Text(
            labelText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          speedValue.toStringAsFixed(1),
          style: GoogleFonts.rajdhani(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: isComplete ? theme.colorScheme.primary : valueColor,
            height: 1.0,
          ),
        ),
        Text(
          'Mbps',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (isComplete) ...[
          const SizedBox(height: 16),
          Text(
            'TEST COMPLETE',
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(SpeedtestState state) {
    final theme = Theme.of(context);
    return Row(
      children: [
        MetricCard(
          label: 'PING',
          value: state.ping > 0 ? '${state.ping} ms' : '—',
          color: theme.colorScheme.tertiary,
        ),
        MetricCard(
          label: 'JITTER',
          value: state.ping > 0 ? '${state.jitter} ms' : '—',
          color: theme.colorScheme.tertiary,
        ),
        MetricCard(
          label: 'DOWNLOAD',
          value: state.downloadSpeed > 0 ? state.downloadSpeed.toStringAsFixed(1) : '—',
          color: theme.colorScheme.primary,
        ),
        MetricCard(
          label: 'UPLOAD',
          value: state.uploadSpeed > 0 ? state.uploadSpeed.toStringAsFixed(1) : '—',
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildProgressIndicators(SpeedtestState state) {
    final theme = Theme.of(context);
    final isDownload = state.phase == SpeedTestPhase.testingDownload;
    final progress = isDownload ? state.downloadProgress : state.uploadProgress;
    final color = isDownload ? theme.colorScheme.primary : theme.colorScheme.secondary;
    final label = isDownload ? 'Download' : 'Upload';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildActionBtn(SpeedtestState state, SpeedtestViewModel viewModel) {
    final isTesting = state.phase != SpeedTestPhase.idle && state.phase != SpeedTestPhase.complete && state.phase != SpeedTestPhase.error;
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isTesting ? null : () => viewModel.startTest(),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.scaffoldBackgroundColor,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isTesting ? 0 : 4,
        ),
        child: Text(
          isTesting ? 'Testing...' : 'Start Speed Test',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
