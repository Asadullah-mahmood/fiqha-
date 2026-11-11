import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helper/hadith_db.dart';
import '../models/ChapterModel.dart';
import 'HadithListScreen.dart';

class HadithCollectionChaptersScreen extends StatefulWidget {
  final String dbFileName;
  final int bookNumber;
  final String bookName;

  const HadithCollectionChaptersScreen({
    super.key,
    required this.dbFileName,
    required this.bookNumber,
    required this.bookName,
  });

  @override
  State<HadithCollectionChaptersScreen> createState() =>
      _HadithCollectionChaptersScreenState();
}

class _HadithCollectionChaptersScreenState
    extends State<HadithCollectionChaptersScreen> {
  late final Future<List<ChapterModel>> _futureChapters =
      HadithDb.getChapters(widget.dbFileName, widget.bookNumber);
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F3D26);
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: Text(
          widget.bookName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<ChapterModel>>(
        future: _futureChapters,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading chapters:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              ),
            );
          }

          final chapters = snapshot.data ?? [];
          final filtered = chapters.where((c) {
            final q = _searchQuery.toLowerCase().trim();
            if (q.isEmpty) return true;
            return c.chapterNumber.toString() == q ||
                c.nameEn.toLowerCase().contains(q) ||
                c.nameUr.toLowerCase().contains(q) ||
                c.nameAr.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search chapters by name or number...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No chapters found',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return Card(
                            elevation: 1.2,
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: gold.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HadithListScreen(
                                      dbFileName: widget.dbFileName,
                                      chapterId: c.chapterId,
                                      chapterTitle: c.nameEn.isNotEmpty
                                          ? c.nameEn
                                          : 'Chapter ${c.chapterNumber}',
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF0F3D26),
                                            Color(0xFF145A36),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: gold,
                                          width: 1.2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${c.chapterNumber}',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: Text(
                                              c.nameAr.isNotEmpty
                                                  ? c.nameAr
                                                  : '—',
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.amiri(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F3D26),
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: Text(
                                              c.nameUr.isNotEmpty
                                                  ? c.nameUr
                                                  : '(اردو ترجمہ دستیاب نہیں)',
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts
                                                  .notoNastaliqUrdu(
                                                fontSize: 13,
                                                color: c.nameUr.isNotEmpty
                                                    ? Colors.grey[800]
                                                    : Colors.grey[400],
                                                height: 1.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            c.nameEn.isNotEmpty
                                                ? c.nameEn
                                                : 'Chapter ${c.chapterNumber}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: c.nameEn.isNotEmpty
                                                  ? Colors.black87
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.menu_book,
                                                  size: 13, color: gold),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${c.hadithsCount} Hadiths',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
