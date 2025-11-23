import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';

/// Miqra Card Component
///
/// Modern, flat card design based on Notion/Apple principles:
/// - No elevation (flat design)
/// - Subtle border instead of shadow
/// - Consistent border radius
/// - Optional tap interaction
///
/// Usage:
/// ```dart
/// MiqraCard(
///   child: Text('Content'),
///   onTap: () => print('Tapped'),
/// )
///
/// MiqraCard.filled(
///   child: Text('Content'),
///   color: MiqraColors.primaryLight,
/// )
/// ```
class MiqraCard extends StatelessWidget {
  /// The widget to display inside the card
  final Widget child;

  /// Optional tap callback
  final VoidCallback? onTap;

  /// Custom padding (defaults to MiqraSpacing.cardPadding)
  final EdgeInsets? padding;

  /// Custom border color (defaults to MiqraColors.borderLight)
  final Color? borderColor;

  /// Background color (defaults to MiqraColors.surface)
  final Color? color;

  /// Border radius (defaults to MiqraSpacing.radiusMedium)
  final BorderRadius? borderRadius;

  /// Show border (defaults to true)
  final bool showBorder;

  /// Border width (defaults to 1)
  final double borderWidth;

  const MiqraCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderColor,
    this.color,
    this.borderRadius,
    this.showBorder = true,
    this.borderWidth = 1,
  });

  /// Filled card variant with colored background
  const MiqraCard.filled({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    required Color backgroundColor,
    this.borderRadius,
    this.showBorder = false,
    this.borderWidth = 1,
  })  : color = backgroundColor,
        borderColor = null;

  /// Outlined card variant with emphasized border
  const MiqraCard.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    Color? outlineColor,
  })  : color = null,
        borderColor = outlineColor,
        showBorder = true,
        borderWidth = 1.5;

  /// Compact card variant with reduced padding
  const MiqraCard.compact({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.color,
    this.borderRadius,
    this.showBorder = true,
    this.borderWidth = 1,
  }) : padding = MiqraSpacing.cardPaddingCompact;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? MiqraSpacing.cardPadding;
    final effectiveBorderRadius = borderRadius ?? MiqraSpacing.radiusMedium;
    final effectiveColor = color ?? MiqraColors.surface;
    final effectiveBorderColor = borderColor ?? MiqraColors.borderLight;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveBorderRadius,
        border: showBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              )
            : null,
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    // If onTap is provided, wrap in InkWell for tap interaction
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Miqra Card with icon and text
///
/// Common pattern for info cards, stat cards, etc.
///
/// Usage:
/// ```dart
/// MiqraIconCard(
///   icon: Icons.star,
///   iconColor: MiqraColors.accent,
///   title: 'Hasanat',
///   value: '120',
/// )
/// ```
class MiqraIconCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const MiqraIconCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return MiqraCard(
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          MiqraSpacing.gapSM,
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MiqraColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Miqra List Card
///
/// Card variant optimized for list items with leading/trailing widgets
///
/// Usage:
/// ```dart
/// MiqraListCard(
///   leading: Icon(Icons.book),
///   title: 'Al-Fatihah',
///   subtitle: 'The Opening',
///   trailing: Icon(Icons.arrow_forward_ios),
///   onTap: () => print('Tapped'),
/// )
/// ```
class MiqraListCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const MiqraListCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return MiqraCard(
      onTap: onTap,
      padding: padding ?? MiqraSpacing.listItemPadding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            MiqraSpacing.gapHorizontalSM,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MiqraColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            MiqraSpacing.gapHorizontalSM,
            trailing!,
          ],
        ],
      ),
    );
  }
}
