import 'package:flutter/material.dart';
import '../../config/theme/dimensions.dart';

/// A reusable empty state widget that displays when there's no data
class EmptyState extends StatelessWidget {
  /// Icon to display in the empty state
  final IconData icon;

  /// Title text to display
  final String title;

  /// Optional description text
  final String? description;

  /// Optional action button text
  final String? actionButtonText;

  /// Optional callback when action button is pressed
  final VoidCallback? onActionButtonPressed;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.description,
    this.actionButtonText,
    this.onActionButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            SizedBox(height: AppDimensions.spacing24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              SizedBox(height: AppDimensions.spacing12),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionButtonText != null && onActionButtonPressed != null) ...[
              SizedBox(height: AppDimensions.spacing32),
              ElevatedButton(
                onPressed: onActionButtonPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing24,
                    vertical: AppDimensions.spacing12,
                  ),
                ),
                child: Text(actionButtonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
