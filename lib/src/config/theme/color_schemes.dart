import 'package:flutter/material.dart';

/// App color scheme configuration
class AppColorScheme {
  // Private constructor to prevent instantiation
  AppColorScheme._();

  // Primary colors
  static const Color primaryColor = Color(0xFF3F51B5); // Indigo
  static const Color primaryLightColor = Color(0xFF757DE8);
  static const Color primaryDarkColor = Color(0xFF303F9F);

  // Secondary colors
  static const Color secondaryColor = Color(0xFFFF9800); // Orange
  static const Color secondaryLightColor = Color(0xFFFFB74D);
  static const Color secondaryDarkColor = Color(0xFFE65100);

  // Light theme colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textDisabledColor = Color(0xFFBDBDBD);

  // Dark theme colors
  static const Color backgroundDarkColor = Color(0xFF121212);
  static const Color surfaceDarkColor = Color(0xFF1E1E1E);
  static const Color dividerDarkColor = Color(0xFF424242);
  static const Color textPrimaryDarkColor = Colors.white;
  static const Color textSecondaryDarkColor = Color(0xFFB0B0B0);
  static const Color textDisabledDarkColor = Color(0xFF757575);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Attendance status colors
  static const Color presentColor = Color(0xFF4CAF50); // Green
  static const Color absentColor = Color(0xFFF44336); // Red
  static const Color lateColor = Color(0xFFFF9800); // Orange/Amber

  // Light color scheme
  static final ColorScheme lightColorScheme = ColorScheme(
    primary: primaryColor,
    primaryContainer: primaryLightColor,
    secondary: secondaryColor,
    secondaryContainer: secondaryLightColor,
    surface: surfaceColor,
    background: backgroundColor,
    error: errorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: textPrimaryColor,
    onBackground: textPrimaryColor,
    onError: Colors.white,
    brightness: Brightness.light,
    surfaceContainerHighest: Color(0xFFE1E1E1),
    outline: Color(0xFFBDBDBD),
  );

  // Dark color scheme
  static final ColorScheme darkColorScheme = ColorScheme(
    primary: primaryColor,
    primaryContainer: primaryDarkColor,
    secondary: secondaryColor,
    secondaryContainer: secondaryDarkColor,
    surface: surfaceDarkColor,
    background: backgroundDarkColor,
    error: errorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: textPrimaryDarkColor,
    onBackground: textPrimaryDarkColor,
    onError: Colors.white,
    brightness: Brightness.dark,
    surfaceContainerHighest: Color(0xFF383838),
    outline: Color(0xFF6C6C6C),
  );

  static const Color excusedColor = Color(0xFF9C27B0); // Purple
}
