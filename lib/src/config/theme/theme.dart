import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'dimensions.dart';

/// App theme configuration
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme for the app
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColorScheme.primaryColor,
        onPrimary: Colors.white,
        primaryContainer: AppColorScheme.primaryLightColor,
        onPrimaryContainer: Colors.white,
        secondary: AppColorScheme.secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: AppColorScheme.secondaryLightColor,
        onSecondaryContainer: Colors.black,
        error: AppColorScheme.errorColor,
        background: AppColorScheme.backgroundColor,
        surface: AppColorScheme.surfaceColor,
      ),
      brightness: Brightness.light,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorScheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: AppDimensions.cardElevation,
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColorScheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.buttonBorderRadius),
          ),
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorScheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.buttonBorderRadius),
          ),
          side: BorderSide(color: AppColorScheme.primaryColor, width: 1.5),
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorScheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing8,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.all(AppDimensions.spacing16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: AppColorScheme.textSecondaryColor),
        hintStyle: TextStyle(color: AppColorScheme.textDisabledColor),
        errorStyle: TextStyle(color: AppColorScheme.errorColor),
      ),

      // Font settings
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        bodySmall: TextStyle(
          fontSize: AppDimensions.fontSizeCaption,
          color: AppColorScheme.textSecondaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: AppDimensions.fontSizeBody,
          color: AppColorScheme.textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: AppDimensions.fontSizeBodyLarge,
          color: AppColorScheme.textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: AppDimensions.fontSizeTitle,
          color: AppColorScheme.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          fontSize: AppDimensions.fontSizeTitleLarge,
          color: AppColorScheme.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
          fontSize: AppDimensions.fontSizeHeadline,
          color: AppColorScheme.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColorScheme.dividerColor,
        thickness: 1,
        space: AppDimensions.spacing16,
      ),
    );
  }

  /// Dark theme for the app
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColorScheme.primaryColor,
        onPrimary: Colors.white,
        primaryContainer: AppColorScheme.primaryDarkColor,
        onPrimaryContainer: Colors.white,
        secondary: AppColorScheme.secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: AppColorScheme.secondaryDarkColor,
        onSecondaryContainer: Colors.white,
        error: AppColorScheme.errorColor,
        background: AppColorScheme.backgroundDarkColor,
        surface: AppColorScheme.surfaceDarkColor,
      ),
      brightness: Brightness.dark,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorScheme.surfaceDarkColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: AppDimensions.cardElevation,
      ),

      // Card theme
      cardTheme: CardTheme(
        color: Color(0xFF2C2C2C),
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColorScheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.buttonBorderRadius),
          ),
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorScheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.buttonBorderRadius),
          ),
          side: BorderSide(color: AppColorScheme.primaryColor, width: 1.5),
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorScheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing8,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Color(0xFF2C2C2C),
        filled: true,
        contentPadding: const EdgeInsets.all(AppDimensions.spacing16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.dividerDarkColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.dividerDarkColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: AppColorScheme.errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: AppColorScheme.textPrimaryDarkColor),
        hintStyle: TextStyle(color: AppColorScheme.textSecondaryDarkColor),
        errorStyle: TextStyle(color: AppColorScheme.errorColor),
      ),

      // Font settings
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        bodySmall: TextStyle(
          fontSize: AppDimensions.fontSizeCaption,
          color: AppColorScheme.textSecondaryDarkColor,
        ),
        bodyMedium: TextStyle(
          fontSize: AppDimensions.fontSizeBody,
          color: AppColorScheme.textPrimaryDarkColor,
        ),
        bodyLarge: TextStyle(
          fontSize: AppDimensions.fontSizeBodyLarge,
          color: AppColorScheme.textPrimaryDarkColor,
        ),
        titleMedium: TextStyle(
          fontSize: AppDimensions.fontSizeTitle,
          color: AppColorScheme.textPrimaryDarkColor,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          fontSize: AppDimensions.fontSizeTitleLarge,
          color: AppColorScheme.textPrimaryDarkColor,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
          fontSize: AppDimensions.fontSizeHeadline,
          color: AppColorScheme.textPrimaryDarkColor,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColorScheme.dividerDarkColor,
        thickness: 1,
        space: AppDimensions.spacing16,
      ),
    );
  }
}
