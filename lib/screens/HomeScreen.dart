import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/screens/FullAudioPlayerScreen.dart';
import 'package:quranpak/screens/QuranScreen.dart';
import 'package:quranpak/screens/Audio.dart';
import 'package:quranpak/screens/HadithBooksScreen.dart';
import 'package:quranpak/screens/SettingsScreen.dart';
import 'package:quranpak/services/DuaApiService.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:quranpak/screens/DashboardScreen.dart';
import 'package:quranpak/widgets/FullSurahMiniPlayer.dart';
import 'package:quranpak/widgets/customIcons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController;

  final List<String> juzNames = [
    "Alif Lam Meem",
    "Sayaqool",
    "Tilkal Rusul",
    "Lan Tana Loo",
    "Wal Mohsanat",
    "La Yuhibbullah",
    "Wa Iza Samiu",
    "Wa Lau Annana",
    "Qalal Malao",
    "Wa'lamu",
    "Ya'taziroon",
    "Wa Ma Min Daabbatin",
    "Wa Ma Ubabrioo",
    "Rubama",
    "Subhanallazi",
    "Qala Alam",
    "Iqtaraba Linnasi",
    "Qad Aflaha",
    "Wa Qalallazina",
    "Amman Khalaqa",
    "Utlu Ma Oohiya",
    "Wa Man Yaqnut",
    "Wa Maliya",
    "Faman Azlamu",
    "Ilaihi Yuraddu",
    "Ha Meem",
    "Qala Fama Khatbukum",
    "Qad Sami Allah",
    "Tabarakallazi",
    "Amma Yatasa'aloon",
  ];

  final List<String> juzNamesUrdu = [
    "الف لآم میم",
    "سیقول",
    "تلك الرسل",
    "لن تنالوا",
    "والحصنت",
    "لا یحب اللہ",
    "و اذا سمعوا",
    "و لو اننا",
    "قال الملأ",
    "واعلموا",
    "یعتذرون",
    "و ما من دآبۃ",
    "و ما ابرئ",
    "ربما",
    "سبحن الذی",
    "قال الم",
    "اقترب للناس",
    "قد افلح",
    "و قال الذین",
    "امن خلق",
    "اتل ما اوحی",
    "و من یقنت",
    "و مالی",
    "فمن اظلم",
    "الیہ یرد",
    "حم",
    "قال فما خطبکم",
    "قد سمع اللہ",
    "تبارك الذی",
    "عم یتسآءلون",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadSurahs();
    });
    _loadRandomDua();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadRandomDua() async {
    final _ = await DuaApiService().getRandomDua();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EC), // cream`
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(onQuranTap: () => setState(() => _selectedIndex = 1)),
          const QuranHomeScreen(),
          const HadithBooksScreen(),
          const AudioDownloadsScreen(),
          const SettingsScreen(), // Using Settings for Profile temporarily
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FullSurahMiniPlayer(),
            AppBottomNav(
              selectedIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              items: const [
                NavDestination(icon: customIcons.home, label: 'Home'),
                NavDestination(icon: customIcons.quran, label: 'Quran'),
                NavDestination(icon: customIcons.book, label: 'Hadiths'),
                NavDestination(icon: Icons.headphones_outlined, label: 'Audio'),
                NavDestination(icon: customIcons.settings, label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NavDestination {
  final IconData icon;
  final String label;
  const NavDestination({required this.icon, required this.label});
}

/// Floating bottom navigation bar that:
///  • always sits ABOVE the system navigation bar / gesture bar
///    (reads the raw window inset, so a parent that strips MediaQuery
///    padding can't break it),
///  • adapts to small phones, large phones and tablets,
///  • never overflows with large system font sizes.
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> items;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  static const _activeColor = Color(0xFF8B6F2C);
  static const _inactiveColor = Color(0xFF3E3E3E);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    // Raw system inset straight from the window (logical pixels).
    final view = View.of(context);
    final rawBottomInset = view.viewPadding.bottom / view.devicePixelRatio;
    final systemInset = math.max(mq.viewPadding.bottom, rawBottomInset);

    final width = mq.size.width;
    final isCompact = width < 360;
    final barHeight = isCompact ? 60.0 : 68.0;
    final sideMargin = isCompact ? 10.0 : 16.0;
    final iconSize = isCompact ? 22.0 : 25.0;

    return MediaQuery(
      // Keep labels from growing past the bar when the user enlarges fonts.
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.15)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          sideMargin,
          8,
          sideMargin,
          // 10 px breathing room + whatever the system bar needs.
          10 + systemInset,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            // Don't stretch edge-to-edge on tablets / landscape.
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(barHeight / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItem(
                        destination: items[i],
                        selected: i == selectedIndex,
                        iconSize: iconSize,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestination destination;
  final bool selected;
  final double iconSize;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppBottomNav._activeColor
        : AppBottomNav._inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, size: iconSize, color: color),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 5 : 0,
                height: selected ? 5 : 0,
                decoration: const BoxDecoration(
                  color: AppBottomNav._activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
