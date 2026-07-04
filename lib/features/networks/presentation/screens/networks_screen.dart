import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../view_models/networks_view_model.dart';
import '../widgets/permission_widget.dart';
import '../widgets/access_point_tile.dart';

class NetworksScreen extends ConsumerStatefulWidget {
  const NetworksScreen({super.key});

  @override
  ConsumerState<NetworksScreen> createState() => _NetworksScreenState();
}

class _NetworksScreenState extends ConsumerState<NetworksScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(networksViewModelProvider.notifier).initialize();
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getTimeAgo(DateTime? lastScan) {
    if (lastScan == null) return "Never";
    final diff = DateTime.now().difference(lastScan).inSeconds;
    return "$diff seconds ago";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(networksViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (state.isScanning && state.networks.isNotEmpty)
              LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: theme.colorScheme.primary,
                minHeight: 2,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Networks',
                    style: GoogleFonts.rajdhani(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Row(
                    children: [
                      if (state.networks.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Text(
                            '${state.networks.length} found',
                            style: GoogleFonts.inter(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                        onPressed: state.isScanning ? null : () {
                          ref.read(networksViewModelProvider.notifier).scan();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(state, theme),
            ),
            if (state.hasPermission && state.lastScan != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Last scan: ${_getTimeAgo(state.lastScan)}',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NetworksState state, ThemeData theme) {
    if (!state.hasPermission) {
      return PermissionWidget(
        onGrant: () {
          ref.read(networksViewModelProvider.notifier).initialize();
        },
      );
    }

    if (state.isScanning && state.networks.isEmpty) {
      return Center(
        child: AnimatedBuilder(
          animation: _radarController,
          builder: (context, child) {
            return SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: RadarPainter(_radarController.value * 2 * pi, theme.colorScheme.outline, theme.colorScheme.primary),
              ),
            );
          },
        ),
      );
    }

    if (state.networks.isEmpty) {
      return Center(
        child: Text(
          'No networks found.',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.networks.length,
      itemBuilder: (context, index) {
        final network = state.networks[index];
        return AccessPointNetworkTile(network: network);
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color borderColor;
  final Color primaryColor;

  RadarPainter(this.sweepAngle, this.borderColor, this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.66, circlePaint);
    canvas.drawCircle(center, radius * 0.33, circlePaint);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: 0.0),
          primaryColor.withValues(alpha: 0.5),
        ],
        stops: const [0.5, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}
