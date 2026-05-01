import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_internet_speed_test_plus/flutter_internet_speed_test_plus.dart';

void main() {
  test('Test speed test initialization', () {
    final speedTest = FlutterInternetSpeedTest();
    expect(speedTest, isNotNull);
  });
}
