import 'package:flutter/material.dart';

/// Color scheme constants used throughout the app
class AppColorScheme {
  // Private constructor to prevent instantiation
  AppColorScheme._();

  // Primary app colors
  static const Color primaryColor = Color(0xFF1E88E5); // Blue 600
  static const Color primaryDarkColor = Color(0xFF1565C0); // Blue 800
  static const Color primaryLightColor = Color(0xFF64B5F6); // Blue 300

  static const Color secondaryColor = Color(0xFF26A69A); // Teal 400
  static const Color secondaryDarkColor = Color(0xFF00897B); // Teal 600
  static const Color secondaryLightColor = Color(0xFF80CBC4); // Teal 200

  // Accent color - used for highlighting actions
  static const Color accentColor = Color(0xFFFFA000); // Amber 700

  // Background colors
  static const Color backgroundColor = Colors.white;
  static const Color backgroundDarkColor = Color(0xFF121212);
  static const Color surfaceColor = Colors.white;
  static const Color surfaceDarkColor = Color(0xFF1E1E1E);

  // Status colors for attendance
  static const Color presentColor = Color(0xFF4CAF50); // Green
  static const Color absentColor = Color(0xFFE53935); // Red
  static const Color lateColor = Color(0xFFFF9800); // Orange
  static const Color excusedColor = Color(0xFF8E24AA); // Purple

  // Feedback states
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFE53935); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color infoColor = Color(0xFF2196F3); // Blue

  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121); // Grey 900
  static const Color textSecondaryColor = Color(0xFF757575); // Grey 600
  static const Color textDisabledColor = Color(0xFFBDBDBD); // Grey 400

  static const Color textPrimaryDarkColor = Color(0xFFE0E0E0); // Grey 300
  static const Color textSecondaryDarkColor = Color(0xFF9E9E9E); // Grey 500
  static const Color textDisabledDarkColor = Color(0xFF616161); // Grey 700

  // Border and divider colors
  static const Color dividerColor = Color(0xFFE0E0E0); // Grey 300
  static const Color dividerDarkColor = Color(0xFF424242); // Grey 800

  // Shimmer effect colors for loading states
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);

  // Initialize the light color scheme with Material 3 colors
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: primaryLightColor,
    onPrimaryContainer: primaryDarkColor,
    secondary: secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: secondaryLightColor,
    onSecondaryContainer: secondaryDarkColor,
    tertiary: accentColor,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFD699),
    onTertiaryContainer: Color(0xFF7A4F00),
    error: errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: backgroundColor,
    onBackground: textPrimaryColor,
    surface: surfaceColor,
    onSurface: textPrimaryColor,
    surfaceVariant: Color(0xFFE7E0EC),
    onSurfaceVariant: textSecondaryColor,
    outline: dividerColor,
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Colors.black.withOpacity(0.15),
    scrim: Colors.black.withOpacity(0.3),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: primaryLightColor,
    surfaceTint: primaryColor,
    surfaceContainerHighest: Color(0xFFE6E6E6),
  );

  // Initialize the dark color scheme with Material 3 colors
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryLightColor,
    onPrimary: Color(0xFF003258),
    primaryContainer: primaryColor,
    onPrimaryContainer: Color(0xFFD1E4FF),
    secondary: secondaryLightColor,
    onSecondary: Color(0xFF003735),
    secondaryContainer: secondaryColor,
    onSecondaryContainer: Color(0xFFBEECE9),
    tertiary: Color(0xFFFFB94C),
    onTertiary: Color(0xFF452B00),
    tertiaryContainer: accentColor,
    onTertiaryContainer: Color(0xFFFFDEAD),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF690005),
    errorContainer: errorColor,
    onErrorContainer: Color(0xFFFFDAD6),
    background: backgroundDarkColor,
    onBackground: textPrimaryDarkColor,
    surface: surfaceDarkColor,
    onSurface: textPrimaryDarkColor,
    surfaceVariant: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: dividerDarkColor,
    outlineVariant: Color(0xFF49454F),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE6E0E9),
    onInverseSurface: Color(0xFF1C1B1F),
    inversePrimary: primaryDarkColor,
    surfaceTint: primaryLightColor,
    surfaceContainerHighest: Color(0xFF333333),
  );

  // Returns a color based on attendance status
  static Color getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return presentColor;
      case 'absent':
        return absentColor;
      case 'late':
        return lateColor;
      case 'excused':
        return excusedColor;
      default:
        return infoColor;
    }
  }
}
