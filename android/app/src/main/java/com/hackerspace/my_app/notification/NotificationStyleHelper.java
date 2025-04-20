package com.hackerspace.my_app.notification;

import android.app.Notification;
import android.graphics.Bitmap;

/**
 * NotificationStyleHelper - A helper class to fix the ambiguous method call issue
 * in flutter_local_notifications plugin when using bigLargeIcon(null) with Android SDK 35.
 */
public class NotificationStyleHelper {
    
    /**
     * Helper method to set a null large icon on a BigPictureStyle.
     * This method explicitly casts null to Bitmap to resolve the ambiguity.
     * 
     * @param style The Notification.BigPictureStyle to modify
     * @return The modified style
     */
    public static Notification.BigPictureStyle setBigLargeIconNull(Notification.BigPictureStyle style) {
        return style.bigLargeIcon((Bitmap) null);
    }
}