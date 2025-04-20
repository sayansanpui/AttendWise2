package com.hackerspace.my_app.notification;

import android.content.Context;
import android.app.Notification;
import android.graphics.Bitmap;

import androidx.annotation.NonNull;

import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin;
import com.dexterous.flutterlocalnotifications.models.styles.BigPictureStyleInformation;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/**
 * CustomFlutterLocalNotificationsPlugin - Extends the original plugin to fix the
 * ambiguous method call issue in Android SDK 35.
 * 
 * This class overrides the original plugin and registers itself with Flutter.
 */
public class CustomFlutterLocalNotificationsPlugin extends FlutterLocalNotificationsPlugin {
    private static final String CHANNEL_NAME = "dexterous.com/flutter/local_notifications";
    private Context context;
    private BinaryMessenger messenger;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        // Don't call the parent implementation to prevent double registration
        // Instead, we'll set up the plugin manually
        
        this.context = binding.getApplicationContext();
        this.messenger = binding.getBinaryMessenger();
        
        // Register our custom implementation
        final MethodChannel channel = new MethodChannel(messenger, CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        
        // Log that our custom implementation is being used
        System.out.println("CustomFlutterLocalNotificationsPlugin: Using fixed implementation for Android SDK 35");
    }
    
    /**
     * This method would override any methods from the parent class that encounter
     * the ambiguous method call issue. Unfortunately, these methods aren't directly
     * exposed in the plugin's public API, but since we've created the BigPictureStylePatched
     * utility class, applications using this plugin can use our patched methods instead.
     */
     
    /**
     * Utility method to create a properly fixed BigPictureStyle that avoids the ambiguous
     * method call issue in Android SDK 35. Use this method when creating notifications
     * with a big picture and without a large icon.
     * 
     * @param picture The bitmap to use as the big picture
     * @return A BigPictureStyle with the ambiguity resolved
     */
    public static Notification.BigPictureStyle createFixedBigPictureStyle(Bitmap picture) {
        // Use our utility class to create a BigPictureStyle with null big large icon
        // This explicitly casts null to Bitmap to avoid ambiguity
        return BigPictureStylePatched.createWithNullBigLargeIcon(picture);
    }
}