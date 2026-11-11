import 'package:flutter/material.dart';
import 'package:quranpak/screens/HomeScreen.dart';

import '../screens/QuranScreen.dart';
import '../widgets/FullSurahMiniPlayer.dart';

/// Root scaffold that hosts the mini player on every tab/screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Add more pages here as your app grows (Qibla, Tasbih, Settings, etc.)
  static const List<Widget> _pages = [
    HomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Your bottom nav bar (if you have one) ──
          if (_pages.length > 1)
            BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              selectedItemColor: Theme.of(context).primaryColor,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book),
                  label: 'Quran',
                ),
                // ... other tabs
              ],
            ),
        ],
      ),
    );
  }
}