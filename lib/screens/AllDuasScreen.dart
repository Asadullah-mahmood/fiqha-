import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/StaticDua.dart';
import '../utils/AppTheme.dart';
import '../utils/islamicDuaData.dart';

class AllDuasScreen extends StatefulWidget {
  const AllDuasScreen({super.key});

  @override
  State<AllDuasScreen> createState() => _AllDuasScreenState();
}

class _AllDuasScreenState extends State<AllDuasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: IslamicDuasData.allSections.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = IslamicDuasData.allSections;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Islamic Duas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppTheme.gold,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.gold,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start,
          tabs: sections.map((s) => Tab(text: s.key)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: sections.map((s) => _sectionListView(s.value)).toList(),
      ),
    );
  }

  Widget _sectionListView(List<StaticDua> duas) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: duas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _duaCard(duas[i]),
    );
  }

  Widget _duaCard(StaticDua dua) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.gold.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 16, color: AppTheme.gold),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dua.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Arabic
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              dua.arabic,
              style: GoogleFonts.amiriQuran(
                fontSize: 20,
                color: AppTheme.primary,
                height: 2.1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 10),

          // Transliteration
          Text(
            dua.transliteration,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // English
          Text(
            dua.english,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.55,
            ),
          ),

          if (dua.note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppTheme.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dua.note!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Reference badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dua.reference,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}