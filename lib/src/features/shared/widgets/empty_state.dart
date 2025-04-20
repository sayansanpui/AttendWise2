import 'package:flutter/material.dart';
import '../../../config/theme/dimensions.dart';

/// A reusable empty state widget to display when there's no data to show
class EmptyState extends StatelessWidget {
  /// Icon to display in the empty state
  final IconData icon;

  /// Title text for the empty state
  final String title;

  /// Description text that explains why the state is empty
  final String description;

  /// Optional text for the action button
  final String? actionButtonText;

  /// Optional callback for when the action button is pressed
  final VoidCallback? onActionButtonPressed;

  /// Optional image asset path to show instead of an icon
  final String? imagePath;

  /// Size of the icon or image
  final double iconSize;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionButtonText,
    this.onActionButtonPressed,
    this.imagePath,
    this.iconSize = 80.0,
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
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: iconSize * 1.5,
                height: iconSize * 1.5,
              )
            else
              Icon(
                icon,
                size: iconSize,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            SizedBox(height: AppDimensions.spacing24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionButtonText != null && onActionButtonPressed != null) ...[
              SizedBox(height: AppDimensions.spacing24),
              ElevatedButton.icon(
                onPressed: onActionButtonPressed,
                icon: const Icon(Icons.add),
                label: Text(actionButtonText!),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing24,
                    vertical: AppDimensions.spacing12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
