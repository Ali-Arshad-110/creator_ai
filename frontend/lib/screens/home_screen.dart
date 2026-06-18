import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import 'reel_analyzer_screen.dart';
import 'profile_search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ReelAnalyzerScreen(),
    ProfileSearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CreatorAI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Show history icon only for Reel Analyzer (since Profile has its own inline history)
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: () => context.push('/history'),
              tooltip: 'Reel History',
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.movie_filter_rounded),
              activeIcon: Icon(Icons.movie_filter_rounded, color: AppTheme.primaryColor),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              activeIcon: Icon(Icons.analytics_rounded, color: AppTheme.primaryColor),
              label: 'Audits',
            ),
          ],
        ),
      ),
    );
  }
}
