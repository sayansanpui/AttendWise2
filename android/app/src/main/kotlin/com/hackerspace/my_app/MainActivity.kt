package com.hackerspace.my_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Use our custom plugin registrant instead of the default
        com.hackerspace.my_app.CustomPluginRegistrant.registerWith(flutterEngine)
    }
}
