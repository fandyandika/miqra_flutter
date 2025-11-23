import 'package:flutter/material.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/miqra_card.dart';
import '../../streak/presentation/widgets/streak_tree_widget.dart';
import '../../streak/presentation/widgets/streak_card.dart';

/// Main home screen displaying streak progress and reading stats.
///
/// Follows Rahmah UX principles:
/// - One primary action per screen
/// - Calm, minimal design
/// - Clear visual hierarchy
///
/// Design System:
/// - Uses MiqraTextStyles for typography
/// - Uses MiqraSpacing for consistent gaps
/// - Uses MiqraCard for flat, modern design
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: MiqraSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              MiqraSpacing.gapLG,
              _buildStreakSection(),
              MiqraSpacing.gapMD,
              const StreakCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds header section with greeting.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu\'alaikum',
          style: MiqraTextStyles.title1,
        ),
        const SizedBox(height: 4),
        Text(
          'Yuk lanjutkan perjalanan membaca Al-Qur\'an',
          style: MiqraTextStyles.body.copyWith(
            color: MiqraColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Builds streak visualization section with SVG tree.
  Widget _buildStreakSection() {
    return MiqraCard(
      padding: const EdgeInsets.all(20),
      child: const StreakTreeWidget(),
    );
  }
}
