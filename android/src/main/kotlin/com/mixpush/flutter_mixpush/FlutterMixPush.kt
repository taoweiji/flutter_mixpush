package com.mixpush.flutter_mixpush

import android.app.Activity
import android.app.Application
import android.content.Context
import com.mixpush.core.MixPushClient
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class FlutterMixPush {

    companion object {
        var context:Context? = null;

        @JvmStatic
        fun init(context: Context) {
            FlutterMixPush.context = context.applicationContext
            MixPushClient.getInstance().setPushReceiver(MyPushReceiver())
            MixPushClient.getInstance().register(context)
        }

        @JvmStatic
        fun onActivityCreate(activity: Activity) {
            // 感觉也不用
        }

    }
}