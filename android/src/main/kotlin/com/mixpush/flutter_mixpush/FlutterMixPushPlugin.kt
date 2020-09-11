package com.mixpush.flutter_mixpush

import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.mixpush.core.GetRegisterIdCallback
import com.mixpush.core.MixPushClient
import com.mixpush.core.MixPushMessage
import com.mixpush.core.MixPushPlatform
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.lang.Exception


/** FlutterMixPushPlugin */
public class FlutterMixPushPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FlutterMixPushPlugin.eventSink = null
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.mixpush/flutter_mixpush")
        channel.setMethodCallHandler(this)
        val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.mixpush/flutter_mixpush_event")
        eventChannel.setStreamHandler(this)
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            FlutterMixPushPlugin.eventSink = null
            val plugin = FlutterMixPushPlugin()
            val channel = MethodChannel(registrar.messenger(), "com.mixpush/flutter_mixpush")
            channel.setMethodCallHandler(plugin)

            val eventChannel = EventChannel(registrar.messenger(), "com.mixpush/flutter_mixpush_event")
            eventChannel.setStreamHandler(plugin)
        }

        fun clickNotification(message: MixPushMessage) {
            waitingMessage = message
            if (eventSink != null) {
                val result = HashMap<Any, Any?>()
                result["title"] = waitingMessage!!.title
                result["description"] = waitingMessage!!.description
                result["platform"] = waitingMessage!!.platform
                result["payload"] = waitingMessage!!.payload
                result["isPassThrough"] = waitingMessage!!.isPassThrough
                Handler(Looper.getMainLooper()).post {
                    try {
                        eventSink!!.success(result)
                        waitingMessage = null
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }

        private var waitingMessage: MixPushMessage? = null
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "init" -> {
                val map = HashMap<Any, Any?>()
                if (waitingMessage != null) {
                    val message = HashMap<Any, Any?>()
                    message["title"] = waitingMessage!!.title
                    message["description"] = waitingMessage!!.description
                    message["platform"] = waitingMessage!!.platform
                    message["payload"] = waitingMessage!!.payload
                    message["isPassThrough"] = waitingMessage!!.isPassThrough
                    map["message"] = message
                }
                result.success(map)
            }

            "getRegisterId" -> {
                if (FlutterMixPush.context == null) {
                    result.error("not_init", "没有初始化", "")
                    return
                }
                MixPushClient.getInstance().getRegisterId(FlutterMixPush.context, object : GetRegisterIdCallback() {
                    override fun callback(platform: MixPushPlatform?) {
                        Handler(Looper.getMainLooper()).post {
                            if (platform != null) {
                                val map = HashMap<Any, Any?>()
                                map["platformName"] = platform.platformName
                                map["regId"] = platform.regId
                                result.success(map)
                            } else {
                                result.error("timeout", "获取失败", "")
                            }
                        }
                    }
                })
                // TODO 在这里检查
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventSink = null
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        FlutterMixPushPlugin.eventSink = eventSink
        // TODO 返回初始化出错信息
        eventSink?.error("","","")
    }

    override fun onCancel(arguments: Any?) {
        FlutterMixPushPlugin.eventSink = null
    }
}
