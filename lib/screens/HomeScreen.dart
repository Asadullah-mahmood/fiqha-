import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/screens/QuranScreen.dart';
import 'package:quranpak/screens/Audio.dart';
import 'package:quranpak/screens/SearchScreen.dart';
import 'package:quranpak/screens/SettingsScreen.dart';
import 'package:quranpak/services/DuaApiService.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:quranpak/screens/DashboardScreen.dart';
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
    setState(() {
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EC), // cream`
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            onQuranTap: () => setState(() => _selectedIndex = 1),
          ),
          //_buildMainList(),
          QuranHomeScreen(),
          const SearchScreen(),
          const AudioDownloadsScreen(),
          const SettingsScreen(), // Using Settings for Profile temporarily
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white, // cream
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(index: 0, icon: customIcons.home, label: 'Home'),
                _buildNavItem(
                  index: 1,
                  icon: customIcons.quran,
                  label: 'Quran',
                ),
                _buildNavItem(
                  index: 2,
                  icon: customIcons.search,
                  label: 'Search',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.headphones_outlined,
                  label: 'Audio',
                ),
                _buildNavItem(
                  index: 4,
                  icon: customIcons.profile,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    const activeColor = Color(0xFF8B6F2C); // brown/gold
    const inactiveColor = Color(0xFF3E3E3E); // dark grey

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(40),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: const BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
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
