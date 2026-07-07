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
                color: theme.colorScheme.primary,
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
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(50), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withAlpha(40),
                theme.colorScheme.primary.withAlpha(10),
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    networkInfo.ssid,
                    style: GoogleFonts.rajdhani(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  networkInfo.securityType,
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${networkInfo.rssi}',
                style: GoogleFonts.rajdhani(
                  color: signalColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'dBm',
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            networkInfo.signalQuality,
            style: GoogleFonts.inter(
              color: signalColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChip(theme, networkInfo.band),
              _buildChip(theme, networkInfo.wifiVersion),
              _buildChip(theme, networkInfo.securityType),
            ],
          ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.onSurface.withAlpha(30)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
