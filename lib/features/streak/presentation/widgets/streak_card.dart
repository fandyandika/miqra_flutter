import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/miqra_card.dart';
import '../../../../shared/widgets/miqra_loading.dart';
import '../../providers/streak_providers.dart';
import '../../data/streak_summary_model.dart';

/// Card widget displaying streak information.
///
/// Design System:
/// - Uses MiqraCard for flat design
/// - Uses MiqraTextStyles for typography
/// - Uses MiqraSpacing for gaps
/// - Uses MiqraLoading for loading state
/// - Uses MiqraColors for semantic colors
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(streakSummaryProvider);

    return summaryAsync.when(
      data: (summary) => _buildCard(context, summary),
      loading: () => _buildLoadingCard(context),
      error: (error, stackTrace) => _buildErrorCard(context, ref),
    );
  }

  Widget _buildCard(BuildContext context, StreakSummary summary) {
    final currentStreak = summary.currentStreak;
    final bestStreak = summary.bestStreak;

    return MiqraCard(
      child: Row(
        children: [
          // Left section: Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak kamu',
                  style: MiqraTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MiqraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStreak > 0
                      ? 'Istiqomah $currentStreak hari'
                      : 'Belum membaca hari ini',
                  style: MiqraTextStyles.headline.copyWith(
                    color: currentStreak > 0
                        ? MiqraColors.primary
                        : MiqraColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Right section: Icon and best streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.local_fire_department,
                color: MiqraColors.accent,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Rekor: $bestStreak hari',
                style: MiqraTextStyles.label.copyWith(
                  color: MiqraColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return MiqraCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak kamu',
                  style: MiqraTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MiqraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menghitung streak...',
                  style: MiqraTextStyles.headline.copyWith(
                    color: MiqraColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const MiqraLoading.inline(),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref) {
    return MiqraCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak kamu',
                  style: MiqraTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MiqraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Streak belum tersedia',
                  style: MiqraTextStyles.headline.copyWith(
                    color: MiqraColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(streakSummaryProvider);
            },
            tooltip: 'Coba lagi',
            color: MiqraColors.primary,
          ),
        ],
      ),
    );
  }
}

