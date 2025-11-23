import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/miqra_card.dart';
import '../../streak/presentation/widgets/streak_card.dart';
import '../../streak/presentation/widgets/streak_calendar.dart';

/// Progress Screen - Display user's reading progress and streak calendar.
///
/// Design System:
/// - Uses MiqraCard for consistent cards
/// - Uses MiqraTextStyles for typography
/// - Uses MiqraSpacing for gaps
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: MiqraSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StreakCard(),
            MiqraSpacing.gapSM,
            MiqraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalender Streak (30 hari)',
                    style: MiqraTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MiqraColors.textPrimary,
                    ),
                  ),
                  MiqraSpacing.gapSM,
                  const StreakCalendar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

