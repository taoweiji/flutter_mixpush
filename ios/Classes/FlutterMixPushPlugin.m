#import "FlutterMixPushPlugin.h"
#if __has_include(<flutter_mixpush/flutter_mixpush-Swift.h>)
#import <flutter_mixpush/flutter_mixpush-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_mixpush-Swift.h"
#endif

@implementation FlutterMixPushPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMixPushPlugin registerWithRegistrar:registrar];
}
@end
