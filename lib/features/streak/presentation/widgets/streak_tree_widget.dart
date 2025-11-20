import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/streak_providers.dart';
import '../../../../core/constants/colors.dart';

/// Displays tree visualization showing streak progress.
///
/// Visual representation of reading consistency following Rahmah UX:
/// - Calm, minimal aesthetic
/// - Static display (no unnecessary motion)
/// - Clear visual progression from soil to mature tree (12 levels)
class StreakTreeWidget extends ConsumerWidget {
  const StreakTreeWidget({super.key});

  // Display constants
  static const double _kTreeSize = 200.0;
  static const int _kMaxLevel = 11;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakCount = ref.watch(streakCurrentProvider);
    final level = _calculateLevel(streakCount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTree(level),
        const SizedBox(height: 12),
        _buildLevelInfo(streakCount, level),
      ],
    );
  }

  /// Builds the SVG tree visualization.
  Widget _buildTree(int level) {
    return Container(
      width: _kTreeSize,
      height: _kTreeSize,
      decoration: BoxDecoration(
        color: miqraSand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/streak/level_$level.svg',
          width: _kTreeSize,
          height: _kTreeSize,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Builds level information text below the tree.
  Widget _buildLevelInfo(int streakCount, int level) {
    return Column(
      children: [
        Text(
          _getLevelName(level),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: miqraText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          streakCount > 0
              ? '$streakCount hari berturut-turut'
              : 'Mulai perjalananmu',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Calculates tree level (0-11) based on streak count.
  ///
  /// Progression designed to encourage long-term consistency:
  /// - Early levels: quick wins (1-3 days)
  /// - Mid levels: building habit (4-28 days)
  /// - Late levels: mastery (29-60+ days)
  int _calculateLevel(int streakCount) {
    if (streakCount == 0) return 0;  // Soil
    if (streakCount == 1) return 1;  // Seed
    if (streakCount <= 3) return 2;  // Tiny Sprout
    if (streakCount <= 6) return 3;  // Sprout 2-3 leaves
    if (streakCount <= 10) return 4; // Baby Plant (first fruit)
    if (streakCount <= 15) return 5; // Young Plant
    if (streakCount <= 21) return 6; // Small Tree
    if (streakCount <= 28) return 7; // Growing Tree
    if (streakCount <= 36) return 8; // Growth Tree
    if (streakCount <= 45) return 9; // Mature Small Tree
    if (streakCount <= 60) return 10; // Near Final Tree
    return _kMaxLevel; // Final Tree (Mastery)
  }

  /// Returns display name for each level.
  String _getLevelName(int level) {
    switch (level) {
      case 0:
        return 'Level 0 — Tanah';
      case 1:
        return 'Level 1 — Benih';
      case 2:
        return 'Level 2 — Kecambah';
      case 3:
        return 'Level 3 — Tunas Muda';
      case 4:
        return 'Level 4 — Tanaman Kecil';
      case 5:
        return 'Level 5 — Tanaman Muda';
      case 6:
        return 'Level 6 — Pohon Kecil';
      case 7:
        return 'Level 7 — Pohon Tumbuh';
      case 8:
        return 'Level 8 — Pohon Berkembang';
      case 9:
        return 'Level 9 — Pohon Dewasa';
      case 10:
        return 'Level 10 — Pohon Matang';
      case 11:
        return 'Level 11 — Pohon Sempurna ✨';
      default:
        return 'Level $level';
    }
  }
}
