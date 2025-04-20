import 'package:flutter/material.dart';

/// A reusable loading indicator widget that shows a centered circular progress indicator
/// with an optional message.
class LoadingIndicator extends StatelessWidget {
  /// Optional message to display below the spinner
  final String? message;

  /// Optional color for the spinner (defaults to theme's primary color)
  final Color? color;

  /// Size of the spinner (defaults to 40.0)
  final double size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.color,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              color: color ?? Theme.of(context).colorScheme.primary,
              strokeWidth: 4.0,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16.0),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
