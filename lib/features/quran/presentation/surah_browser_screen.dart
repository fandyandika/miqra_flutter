import 'package:flutter/material.dart';
import 'screens/surah_list_screen.dart';
import 'screens/juz_list_screen.dart';
import 'screens/bookmark_list_screen.dart';

class SurahBrowserScreen extends StatelessWidget {
  const SurahBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Baca Qur\'an'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Surah'),
              Tab(text: 'Juz'),
              Tab(text: 'Bookmark'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SurahListScreen(),
            JuzListScreen(),
            BookmarkListScreen(),
          ],
        ),
      ),
    );
  }
}

