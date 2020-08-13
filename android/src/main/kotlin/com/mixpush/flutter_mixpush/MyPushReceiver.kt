package com.mixpush.flutter_mixpush

import android.content.Context
import android.content.Intent
import com.mixpush.core.MixPushMessage
import com.mixpush.core.MixPushPlatform
import com.mixpush.core.MixPushReceiver


class MyPushReceiver : MixPushReceiver() {
    override fun onRegisterSucceed(context: Context, platform: MixPushPlatform) {
        // 这里需要实现上传regId和推送平台信息到服务端保存，
        //也可以通过MixPushClient.getInstance().getRegisterId的方式实现
    }

    override fun onNotificationMessageClicked(context: Context, message: MixPushMessage) {
        // TODO 通知栏消息点击触发，实现打开具体页面，打开浏览器等。
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        context.startActivity(intent)
        FlutterMixPushPlugin.clickNotification(message)
    }
}