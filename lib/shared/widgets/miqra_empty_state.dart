import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';

/// Miqra Empty State Component
///
/// Beautiful, consistent empty states across the app
/// Based on Apple HIG empty state patterns
///
/// Usage:
/// ```dart
/// MiqraEmptyState(
///   icon: Icons.book_outlined,
///   title: 'No bookmarks yet',
///   description: 'Start bookmarking your favorite ayahs',
///   actionLabel: 'Browse Quran',
///   onAction: () => Navigator.push(...),
/// )
/// ```
class MiqraEmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Main title
  final String title;

  /// Optional description
  final String? description;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action button callback
  final VoidCallback? onAction;

  /// Icon color (defaults to textTertiary)
  final Color? iconColor;

  /// Icon size (defaults to 64)
  final double iconSize;

  const MiqraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: MiqraSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? MiqraColors.textTertiary,
            ),
            MiqraSpacing.gapMD,

            // Title
            Text(
              title,
              style: MiqraTextStyles.headline.copyWith(
                color: MiqraColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              MiqraSpacing.gapSM,
              Text(
                description!,
                style: MiqraTextStyles.body.copyWith(
                  color: MiqraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action Button
            if (actionLabel != null && onAction != null) ...[
              MiqraSpacing.gapLG,
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact Empty State (for smaller spaces like sections)
class MiqraEmptyStateCompact extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? iconColor;

  const MiqraEmptyStateCompact({
    super.key,
    required this.icon,
    required this.message,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: MiqraSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor ?? MiqraColors.textTertiary,
            ),
            MiqraSpacing.gapSM,
            Text(
              message,
              style: MiqraTextStyles.caption.copyWith(
                color: MiqraColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
