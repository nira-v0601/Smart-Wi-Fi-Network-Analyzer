import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/signal_colors.dart';

import '../view_models/dashboard_view_model.dart';
import '../widgets/detail_card.dart';
import '../widgets/isp_logo_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _timer;
  Timer? _signalTimer;
  Timer? _networkTimer;
  Timer? _publicIpTimer;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    
    // Full load on open (includes Public IP + ISP HTTP call)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardViewModelProvider.notifier).load();
    });

    // TIMER 1: Refresh RSSI + SSID every 1 seconds (live feel)
    _signalTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => ref.read(dashboardViewModelProvider.notifier).refreshSignal(),
    );

    // TIMER 2: Refresh local network info every 20 seconds
    _networkTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => ref.read(dashboardViewModelProvider.notifier).refreshNetworkInfo(),
    );

    // TIMER 3: Refresh Public IP + ISP every 60 seconds
    _publicIpTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => ref.read(dashboardViewModelProvider.notifier).refreshPublicIp(),
    );
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _signalTimer?.cancel();
    _networkTimer?.cancel();
    _publicIpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);

    ref.listen<DashboardState>(dashboardViewModelProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(theme),
              const SizedBox(height: 24),
              if (state.isLoading)
                Expanded(
                  child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
                )
              else if (state.networkInfo != null) ...[
                _buildHeroCard(theme, state.networkInfo)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
                const SizedBox(height: 24),
                Expanded(child: _buildDetailsGrid(theme, state.networkInfo)),
                const SizedBox(height: 16),
                _buildIspCard(theme, state.networkInfo)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
              ] else
                Expanded(
                  child: Center(
                    child: Text('No Network Info Available', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Wi-Fi Network Analyzer',
              style: GoogleFonts.rajdhani(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currentTime,
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
          onPressed: () {
            ref.read(dashboardViewModelProvider.notifier).load();
            // Manual tap = full reload including Public IP + ISP
          },
        ),
      ],
    );
  }

  Widget _buildHeroCard(ThemeData theme, dynamic networkInfo) {
    final signalColor = SignalColors.fromRssi(networkInfo.rssi);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: signalColor.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15), // glass highlight
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.25),
                  theme.colorScheme.surface.withValues(alpha: 0.5),
                  signalColor.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background big icon
                Positioned(
                  right: -30,
                  bottom: -20,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: signalColor.withValues(alpha: 0.06)),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (context, color, child) {
                      return Icon(
                        Icons.wifi,
                        size: 180,
                        color: color,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.wifi_tethering, color: theme.colorScheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    networkInfo.ssid,
                                    style: GoogleFonts.rajdhani(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield, size: 12, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  networkInfo.securityType,
                                  style: GoogleFonts.inter(
                                    color: theme.colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Signal Strength
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${networkInfo.rssi}',
                                style: GoogleFonts.rajdhani(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 64,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'dBm',
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: signalColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: signalColor.withValues(alpha: 0.3)),
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              style: GoogleFonts.inter(
                                color: signalColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                              child: Text(
                                networkInfo.signalQuality.toUpperCase(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Bottom Specs Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoColumn(theme, Icons.speed, 'Band', networkInfo.band),
                            Container(width: 1, height: 30, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                            _buildInfoColumn(theme, Icons.settings_ethernet, 'Standard', networkInfo.wifiVersion),
                            Container(width: 1, height: 30, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                            _buildInfoColumn(theme, Icons.router, 'IP Version', networkInfo.ipVersion ?? 'IPv4'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(ThemeData theme, IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  String _bandFromFrequency(String freqStr) {
    if (freqStr == '—' || freqStr.isEmpty) return '—';
    final mhz = int.tryParse(freqStr.replaceAll(RegExp(r'[^0-9]'), ''));
    if (mhz == null) return freqStr;
    if (mhz >= 5945) return '6 GHz';
    if (mhz >= 5000) return '5 GHz';
    if (mhz >= 2400) return '2.4 GHz';
    return freqStr;
  }

  Widget _buildDetailsGrid(ThemeData theme, dynamic networkInfo) {
    String ispShort = networkInfo.ispName;
    if (ispShort.length > 15) {
      ispShort = '${ispShort.substring(0, 15)}...';
    }

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        DetailCard(icon: Icons.public, label: 'Public IP', value: networkInfo.publicIp),
        DetailCard(icon: Icons.router, label: 'Gateway', value: networkInfo.gateway ?? "—"),
        DetailCard(
          icon: Icons.cell_tower,
          label: 'ISP',
          value: ispShort,
          trailingWidget: IspLogoWidget(domain: networkInfo.ispDomain, ispName: networkInfo.ispName, size: 20),
        ),
        DetailCard(icon: Icons.speed, label: 'Band', value: _bandFromFrequency(networkInfo.frequency)),
        DetailCard(icon: Icons.dns, label: 'IP Version', value: networkInfo.ipVersion ?? "IPv4"),
      ].animate(interval: 50.ms).fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildIspCard(ThemeData theme, dynamic networkInfo) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IspLogoWidget(
            domain: networkInfo.ispDomain,
            ispName: networkInfo.ispName,
            size: 32,
            fallbackWidget: Icon(Icons.business, color: theme.colorScheme.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  networkInfo.ispName,
                  style: GoogleFonts.rajdhani(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  networkInfo.ispOrg,
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Connected',
              style: GoogleFonts.inter(
                color: theme.colorScheme.secondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
