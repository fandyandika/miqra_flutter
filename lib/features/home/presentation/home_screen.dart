import 'package:flutter/material.dart';
import '../../streak/presentation/widgets/streak_tree_widget.dart';
import '../../streak/presentation/widgets/streak_card.dart';

/// Main home screen displaying streak progress and reading stats.
///
/// Follows Rahmah UX principles:
/// - One primary action per screen
/// - Calm, minimal design
/// - Clear visual hierarchy
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStreakSection(),
              const SizedBox(height: 16),
              const StreakCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds header section with greeting.
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu\'alaikum',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Yuk lanjutkan perjalanan membaca Al-Qur\'an',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Builds streak visualization section with SVG tree.
  Widget _buildStreakSection() {
    return const Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: StreakTreeWidget(),
      ),
    );
  }
}
