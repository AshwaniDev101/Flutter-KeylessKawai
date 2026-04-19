package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

//class MainActivity : FlutterActivity()

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)


        Log.d("===", "WebSocketManager init()",);
        WebSocketManager.init()
    }
}

