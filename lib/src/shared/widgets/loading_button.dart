import 'package:flutter/material.dart';
import '../../config/theme/dimensions.dart';

/// A button that shows a loading indicator when processing
class LoadingButton extends StatelessWidget {
  /// Whether the button is in loading state
  final bool isLoading;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Text to display on the button
  final String text;

  /// Text to display when loading
  final String loadingText;

  /// Optional icon to display
  final IconData? icon;

  /// Optional loading indicator color
  final Color? loadingColor;

  /// Optional button color
  final Color? buttonColor;

  /// Width of the button (null for auto)
  final double? width;

  const LoadingButton({
    Key? key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    required this.loadingText,
    this.icon,
    this.loadingColor,
    this.buttonColor,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: buttonColor?.withOpacity(0.6) ??
              theme.colorScheme.primary.withOpacity(0.6),
          disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.7),
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
                      color: loadingColor ?? theme.colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacing12),
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
