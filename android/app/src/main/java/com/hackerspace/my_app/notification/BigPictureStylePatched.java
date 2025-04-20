package com.hackerspace.my_app.notification;

import android.app.Notification;
import android.graphics.Bitmap;

/**
 * BigPictureStylePatched - Utility class to fix ambiguous method call issues in Android SDK 35
 * 
 * This class provides static methods to create properly typed BigPictureStyle objects
 * that avoid the ambiguity between bigLargeIcon(Bitmap) and bigLargeIcon(Icon) methods.
 */
public class BigPictureStylePatched {
    
    /**
     * Creates a BigPictureStyle with the provided picture and explicitly casts null
     * to Bitmap for the bigLargeIcon method to avoid ambiguity.
     * 
     * @param picture The bitmap to use as the big picture
     * @return A properly configured BigPictureStyle with unambiguous method calls
     */
    public static Notification.BigPictureStyle createWithNullBigLargeIcon(Bitmap picture) {
        Notification.BigPictureStyle style = new Notification.BigPictureStyle();
        style.bigPicture(picture);
        // Explicitly cast null to Bitmap to resolve the ambiguity between
        // bigLargeIcon(Bitmap) and bigLargeIcon(Icon) methods
        style.bigLargeIcon((Bitmap) null);
        return style;
    }
    
    /**
     * Creates a BigPictureStyle with the provided picture and large icon.
     * 
     * @param picture The bitmap to use as the big picture
     * @param largeIcon The bitmap to use as the large icon
     * @return A properly configured BigPictureStyle
     */
    public static Notification.BigPictureStyle createWithBigLargeIcon(Bitmap picture, Bitmap largeIcon) {
        Notification.BigPictureStyle style = new Notification.BigPictureStyle();
        style.bigPicture(picture);
        style.bigLargeIcon(largeIcon);
        return style;
    }
    
    /**
     * Directly fixes any existing BigPictureStyle by applying the null large icon with proper casting.
     * This can be used to fix instances of BigPictureStyle created elsewhere in the code.
     * 
     * @param style An existing BigPictureStyle instance that needs the ambiguity fixed
     * @return The same style instance with the ambiguity resolved
     */
    public static Notification.BigPictureStyle fixBigPictureStyle(Notification.BigPictureStyle style) {
        // Explicitly cast null to Bitmap to resolve the ambiguity
        return style.bigLargeIcon((Bitmap) null);
    }
}