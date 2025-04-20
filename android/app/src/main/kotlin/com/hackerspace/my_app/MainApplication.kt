package com.hackerspace.my_app

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.embedding.engine.plugins.FlutterPlugin

class MainApplication : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun registerWith(registry: PluginRegistry) {
        // This is not used in the embedding v2
    }

    override fun onCreate() {
        super.onCreate()
        // Register our custom plugin implementations
    }
}