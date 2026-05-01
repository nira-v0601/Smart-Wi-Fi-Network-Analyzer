//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<connectivity_plus/ConnectivityPlusPlugin.h>)
#import <connectivity_plus/ConnectivityPlusPlugin.h>
#else
@import connectivity_plus;
#endif

#if __has_include(<flutter_internet_speed_test_plus/FlutterInternetSpeedTestPlugin.h>)
#import <flutter_internet_speed_test_plus/FlutterInternetSpeedTestPlugin.h>
#else
@import flutter_internet_speed_test_plus;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [ConnectivityPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"ConnectivityPlusPlugin"]];
  [FlutterInternetSpeedTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterInternetSpeedTestPlugin"]];
}

@end
