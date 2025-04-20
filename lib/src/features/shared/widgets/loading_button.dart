import 'package:flutter/material.dart';
import '../../../config/theme/dimensions.dart';

/// A reusable button with loading state indicator
class LoadingButton extends StatelessWidget {
  /// Whether the button is in loading state
  final bool isLoading;

  /// Function called when button is pressed
  final VoidCallback onPressed;

  /// Text to display on the button
  final String text;

  /// Text to display when button is in loading state
  final String loadingText;

  /// Optional icon to display before the text
  final IconData? icon;

  /// Background color of the button
  final Color? backgroundColor;

  /// Text color of the button
  final Color? textColor;

  /// Button width (null for auto)
  final double? width;

  /// Button height
  final double height;

  const LoadingButton({
    Key? key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    required this.loadingText,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: textColor ?? theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor ?? theme.colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacing8),
                  Text(loadingText),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    SizedBox(width: AppDimensions.spacing8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
