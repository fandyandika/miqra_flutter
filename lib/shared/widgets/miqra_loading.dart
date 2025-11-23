import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';

/// Miqra Loading Indicator
///
/// Consistent loading states across the app
///
/// Usage:
/// ```dart
/// MiqraLoading()
/// MiqraLoading.withMessage(message: 'Loading Quran...')
/// MiqraLoading.inline()
/// ```
class MiqraLoading extends StatelessWidget {
  /// Optional loading message
  final String? message;

  /// Color of the loading indicator
  final Color? color;

  /// Size of the loading indicator
  final double size;

  const MiqraLoading({
    super.key,
    this.message,
    this.color,
    this.size = 40,
  });

  /// Loading with message
  const MiqraLoading.withMessage({
    super.key,
    required this.message,
    this.color,
  }) : size = 40;

  /// Inline loading (smaller, for inline use)
  const MiqraLoading.inline({
    super.key,
    this.color,
  })  : message = null,
        size = 20;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size > 30 ? 3 : 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? MiqraColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            MiqraSpacing.gapMD,
            Text(
              message!,
              style: MiqraTextStyles.body.copyWith(
                color: MiqraColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Linear progress indicator with Miqra styling
class MiqraProgressBar extends StatelessWidget {
  /// Progress value (0.0 - 1.0)
  final double? value;

  /// Color of the progress bar
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  /// Height of the progress bar
  final double height;

  const MiqraProgressBar({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? MiqraColors.primary,
          ),
          backgroundColor: backgroundColor ?? MiqraColors.bgTertiary,
        ),
      ),
    );
  }
}

/// Skeleton loader for content placeholders
///
/// Usage:
/// ```dart
/// MiqraSkeleton(width: 100, height: 20)
/// MiqraSkeleton.text()
/// MiqraSkeleton.circle(size: 40)
/// ```
class MiqraSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const MiqraSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// Text skeleton (full width, 16px height)
  const MiqraSkeleton.text({
    super.key,
    this.width,
  })  : height = 16,
        borderRadius = MiqraSpacing.radiusSmall;

  /// Circle skeleton (for avatars)
  const MiqraSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(999));

  /// Card skeleton
  const MiqraSkeleton.card({
    super.key,
    this.width,
    this.height = 120,
  }) : borderRadius = MiqraSpacing.radiusMedium;

  @override
  State<MiqraSkeleton> createState() => _MiqraSkeletonState();
}

class _MiqraSkeletonState extends State<MiqraSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? MiqraSpacing.radiusSmall,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                MiqraColors.bgSecondary,
                MiqraColors.bgTertiary,
                MiqraColors.bgSecondary,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
