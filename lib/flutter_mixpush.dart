import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class FlutterMixPush {
  static const MethodChannel _channel =
      const MethodChannel('com.mixpush/flutter_mixpush');
  static const EventChannel _eventChannel =
      const EventChannel('com.mixpush/flutter_mixpush_event');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<MixPushPlatform> get getRegisterId async {
    int checkCount = Platform.isIOS ? 10 : 1;
    while (checkCount > 0) {
      checkCount--;
      try {
        final Map info = await _channel.invokeMethod('getRegisterId');
        var platform = MixPushPlatform(info["platformName"], info["regId"]);
        return platform;
      } catch (e) {}
      await Future.delayed(Duration(seconds: 5));
    }
    throw Exception("获取超时");
  }

  static Future<Map> _init() async {
    final Map result = await _channel.invokeMethod('init');
    if (result.containsKey("message")) {
      _handleClick(result["message"]);
    }
    return result;
  }

  static _handleClick(Map message) {
    _onNotificationMessageClicked(MixPushMessage(
      title: message["title"],
      description: message["description"],
      platform: message["platform"],
      payload: message["payload"],
      passThrough: message["passThrough"],
    ));
  }

  static ValueChanged<MixPushMessage> _onNotificationMessageClicked;
  static ValueChanged<dynamic> _onError;

  static register({
    @required ValueChanged<MixPushMessage> onNotificationMessageClicked,
    @required ValueChanged<MixPushPlatform> onGetRegisterId,
    ValueChanged<dynamic> onError,
  }) {
    _onError = onError;
    _onNotificationMessageClicked = onNotificationMessageClicked;
    _init();
    _eventChannel.receiveBroadcastStream().listen((message) {
      _handleClick(message);
    }, onError: (dynamic errorDetails) {
      if (_onError != null) {
        _onError(errorDetails);
      }
      print("MixPush error:details:$errorDetails");
    }, onDone: () {});
    if (onGetRegisterId != null) {
      getRegisterId.then((platform) {
        onGetRegisterId(platform);
      }).catchError((error) {
        print("MixPush onGetRegisterId error: $error");
        if (onError != null) {
          onError("MixPush onGetRegisterId error: $error");
        }
      });
    }
  }
}

class MixPushPlatform {
  String platformName;
  String regId;

  MixPushPlatform(this.platformName, this.regId);

  @override
  String toString() {
    return 'MixPushPlatform{platformName: $platformName, regId: $regId}';
  }
}

class MixPushMessage {
  /// 通知栏标题,透传该字段为空
  String title;

  /// 通知栏副标题,透传该字段为空
  String description;

  /// 推送所属平台,比如mi/huawei
  String platform;

  /// 推送附属的内容信息
  String payload;

  /// 是否是透传推送
  bool passThrough;

  MixPushMessage(
      {this.title,
      this.description,
      this.platform,
      this.payload,
      this.passThrough});

  @override
  String toString() {
    return 'MixPushMessage{title: $title, description: $description, platform: $platform, payload: $payload, passThrough: $passThrough}';
  }
}
