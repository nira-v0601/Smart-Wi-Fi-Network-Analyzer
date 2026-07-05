import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/theme/signal_colors.dart';

part 'access_point_model.freezed.dart';

@freezed
class AccessPointModel with _$AccessPointModel {
  const AccessPointModel._();

  const factory AccessPointModel({
    required String ssid,
    required String bssid,
    required int rssi,
    required int frequency,
    required String capabilities,
  }) = _AccessPointModel;

  String get band {
    if (frequency >= 5945) return '6 GHz';
    if (frequency >= 5000) return '5 GHz';
    return '2.4 GHz';
  }

  int get channel {
    if (frequency >= 5945) return ((frequency - 5950) ~/ 5);
    if (frequency >= 5000) return ((frequency - 5000) ~/ 5) + 36;
    if (frequency == 2484) return 14;
    return ((frequency - 2412) ~/ 5) + 1;
  }

  String get securityType {
    final caps = capabilities.toUpperCase();
    if (caps.contains('WPA3') || caps.contains('SAE')) return 'WPA3';
    if (caps.contains('WPA2') || caps.contains('RSN')) return 'WPA2';
    if (caps.contains('WPA')) return 'WPA';
    if (caps.contains('WEP')) return 'WEP';
    if (caps.contains('OWE')) return 'OWE';
    return 'Open';
  }

  String get signalQuality => SignalColors.qualityLabel(rssi);
}
