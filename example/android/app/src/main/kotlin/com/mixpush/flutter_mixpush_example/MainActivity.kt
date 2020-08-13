package com.mixpush.flutter_mixpush_example

import android.content.Intent
import android.os.Bundle
import com.mixpush.flutter_mixpush.FlutterMixPush
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FlutterMixPush.onActivityCreate(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 这个位置不应该让用户处理,应该判断,如果有注册就走
    }
}
