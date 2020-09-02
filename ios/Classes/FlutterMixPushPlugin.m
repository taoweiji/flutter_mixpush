#import "FlutterMixPushPlugin.h"
#import <Flutter/Flutter.h>
#import "MiPushSDK.h"
#import <UserNotifications/UserNotifications.h>

#define SAFE_STRING_VALUE(str) str ? : @""

@interface FlutterMixPushPlugin() <UNUserNotificationCenterDelegate, MiPushSDKDelegate, FlutterStreamHandler> {
    FlutterEventSink _eventSink;
    NSDictionary *_waitingMessage;
}
@end

@implementation FlutterMixPushPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:@"com.mixpush/flutter_mixpush" binaryMessenger:[registrar messenger]];
    FlutterMixPushPlugin *instance = [FlutterMixPushPlugin new];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    
    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"com.mixpush/flutter_mixpush_event" binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"getPlatformVersion"]) {
        result(UIDevice.currentDevice.systemVersion);
    } else if ([call.method isEqualToString:@"init"]) {
        NSDictionary *dict = [self parseMessage:_waitingMessage];
        result(dict);
    } else if ([call.method isEqualToString:@"getRegisterId"]) {
        NSString *regId = [MiPushSDK getRegId];
        if (regId && regId.length > 0) {
            NSDictionary *dict = @{@"platformName":@"mi_apns",@"regId":regId};
            result(dict);
        } else {
            result([FlutterError errorWithCode:@"timeout" message:@"获取失败" details:@""]);
        }
    }
}

- (void)clickNotification:(NSDictionary *)message {
    if (_eventSink) {
        NSDictionary *dict = [self parseMessage:message];
        _eventSink(dict);
        _waitingMessage = nil;
    }
}

- (NSDictionary *)parseMessage:(NSDictionary *)message {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:SAFE_STRING_VALUE(message[@"aps"][@"alert"][@"title"]) forKey:@"title"];
    [dict setValue:SAFE_STRING_VALUE(message[@"aps"][@"alert"][@"subtitle"]) forKey:@"description"];
    [dict setValue:@"mi_apns" forKey:@"platform"];
    [dict setValue:SAFE_STRING_VALUE(message[@"payload"]) forKey:@"payload"];
    [dict setValue:@(false) forKey:@"isPassThrough"];
    return dict;
}

#pragma mark - AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    [MiPushSDK registerMiPush:self];
    
    // 点击通知打开app处理逻辑
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(userInfo){
        _waitingMessage = userInfo;
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    // 注册APNS成功, 注册deviceToken
    [MiPushSDK bindDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    NSLog(@"mipush APNS error: %@", err);
    
    // 注册APNS失败.
    // 自行处理.
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    // 当同时启动APNs与内部长连接时, 把两处收到的消息合并. 通过miPushReceiveNotification返回
    [MiPushSDK handleReceiveRemoteNotification:userInfo];
}


#pragma mark - UNUserNotificationCenterDelegate

// 应用在前台收到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert);
}

// 点击通知进入应用
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [self clickNotification:userInfo];
    }
    completionHandler();
}

#pragma mark - MiPushSDKDelegate

- (void)miPushConnectionOnline {
    NSLog(@"mipush Connection Online");
}

- (void)miPushConnectionOffline {
    NSLog(@"mipush Connection Offline");
    
}

- (void)miPushRequestSuccWithSelector:(NSString *)selector data:(NSDictionary *)data{
    NSLog(@"mipush command succ(%@): %@", [self getOperateType:selector], data);
}

- (void)miPushRequestErrWithSelector:(NSString *)selector error:(int)error data:(NSDictionary *)data{
    NSLog(@"mipush command error(%d|%@): %@", error, [self getOperateType:selector], data);
}

- (void)miPushReceiveNotification:(NSDictionary*)data{
    // 测试了，没有长链接，都是走APNS -> wmh
    NSLog(@"mipush XMPP notify: %@", data);
}

- (NSString*)getOperateType:(NSString*)selector{
    NSString *ret = nil;
    if ([selector hasPrefix:@"registerMiPush:"] ) {
        ret = @"客户端注册设备";
    }else if ([selector isEqualToString:@"unregisterMiPush"]) {
        ret = @"客户端设备注销";
    }else if ([selector isEqualToString:@"registerApp"]) {
        ret = @"注册App";
    }else if ([selector isEqualToString:@"bindDeviceToken:"]) {
        ret = @"绑定 PushDeviceToken";
    }else if ([selector isEqualToString:@"setAlias:"]) {
        ret = @"客户端设置别名";
    }else if ([selector isEqualToString:@"unsetAlias:"]) {
        ret = @"客户端取消别名";
    }else if ([selector isEqualToString:@"subscribe:"]) {
        ret = @"客户端设置主题";
    }else if ([selector isEqualToString:@"unsubscribe:"]) {
        ret = @"客户端取消主题";
    }else if ([selector isEqualToString:@"setAccount:"]) {
        ret = @"客户端设置账号";
    }else if ([selector isEqualToString:@"unsetAccount:"]) {
        ret = @"客户端取消账号";
    }else if ([selector isEqualToString:@"openAppNotify:"]) {
        ret = @"统计客户端";
    }else if ([selector isEqualToString:@"getAllAliasAsync"]) {
        ret = @"获取Alias设置信息";
    }else if ([selector isEqualToString:@"getAllTopicAsync"]) {
        ret = @"获取Topic设置信息";
    }
    
    return ret;
}

#pragma mark - FlutterStreamHandler
- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

@end

