import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/signal_colors.dart';
import '../../data/models/access_point_model.dart';
import 'signal_bars_widget.dart';

class AccessPointNetworkTile extends StatelessWidget {
  final AccessPointModel network;

  const AccessPointNetworkTile({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signalColor = SignalColors.fromRssi(network.rssi);

    Color securityColor = theme.colorScheme.outline;
    if (network.securityType == 'WPA3') {
      securityColor = theme.colorScheme.secondary;
    } else if (network.securityType == 'WPA2') {
      securityColor = theme.colorScheme.primary;
    } else if (network.securityType == 'Open') {
      securityColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: signalColor, width: 2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignalBarsWidget(rssi: network.rssi),
          ],
        ),
        title: Text(
          network.ssid.isEmpty ? '[Hidden Network]' : network.ssid,
          style: GoogleFonts.rajdhani(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              _buildChip(theme, network.band, theme.colorScheme.primary),
              const SizedBox(width: 8),
              _buildChip(theme, network.securityType, securityColor),
              const SizedBox(width: 8),
              Text(
                'Ch ${network.channel}',
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${network.rssi}',
              style: GoogleFonts.rajdhani(
                color: signalColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'dBm',
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: theme.colorScheme.onSurface,
          fontSize: 10,
        ),
      ),
    );
  }
}
