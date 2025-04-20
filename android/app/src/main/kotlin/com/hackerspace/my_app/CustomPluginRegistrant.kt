package com.hackerspace.my_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import com.hackerspace.my_app.notification.CustomFlutterLocalNotificationsPlugin
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin

/**
 * CustomPluginRegistrant - Registers custom plugin implementations for the app.
 * 
 * This class is responsible for registering our custom versions of plugins
 * that need patching, while still allowing the rest of the plugins to be
 * registered normally by the Flutter engine.
 */
class CustomPluginRegistrant {
    companion object {
        /**
         * Register custom plugin implementations with the Flutter engine.
         * 
         * @param flutterEngine The Flutter engine to register plugins with
         */
        fun registerWith(flutterEngine: FlutterEngine) {
            // First, register all the default plugins
            io.flutter.plugins.GeneratedPluginRegistrant.registerWith(flutterEngine)
            
            // Remove the default flutter_local_notifications plugin if it's registered
            // The proper way to access plugins in the current Flutter embedding API
            val pluginsRegistry = flutterEngine.plugins
            
            // Find and remove the default implementation of the plugin
            // We need to use the remove(Class<T>) method of PluginRegistry
            try {
                // Remove the plugin by class type to avoid iterator and ambiguity issues
                pluginsRegistry.remove(FlutterLocalNotificationsPlugin::class.java)
                println("CustomPluginRegistrant: Removed default flutter_local_notifications plugin")
            } catch (e: Exception) {
                println("CustomPluginRegistrant: No default plugin found or error removing: ${e.message}")
            }
            
            // Add our custom implementation of the flutter_local_notifications plugin
            flutterEngine.plugins.add(CustomFlutterLocalNotificationsPlugin())
            
            // Log that our custom plugin registrant has been executed
            println("CustomPluginRegistrant: Registered custom flutter_local_notifications plugin")
        }
    }
}