import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../models/BukhariModels.dart';
import '../repository/BukhariRepository.dart';

enum HadithViewLanguage { all, english, urdu, arabic }

class HadithChaptersScreen extends StatefulWidget {
  final Book book;

  const HadithChaptersScreen({
    super.key,
    required this.book,
  });

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  final BukhariRepository _repository = BukhariRepository.instance;
  late final Future<List<Chapter>> _futureChapters;

  List<Chapter> _chapters = [];
  int _selectedChapterIndex = 0;
  List<Hadith> _currentHadiths = [];
  bool _loadingHadiths = true;

  HadithViewLanguage _selectedLanguage = HadithViewLanguage.all;
  final ScrollController _chapterChipsScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _futureChapters = _loadChapters();
  }

  @override
  void dispose() {
    _chapterChipsScrollController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<List<Chapter>> _loadChapters() async {
    final chapters = await _repository.getChapters(widget.book.bookNumber);
    if (!mounted) return chapters;
    setState(() {
      _chapters = chapters;
    });
    if (chapters.isNotEmpty) {
      _loadHadithsForChapter(chapters[0].chapterId);
    } else {
      setState(() => _loadingHadiths = false);
    }
    return chapters;
  }

  Future<void> _loadHadithsForChapter(int chapterId) async {
    setState(() => _loadingHadiths = true);
    final hadiths = await _repository.getHadiths(chapterId);
    if (!mounted) return;
    setState(() {
      _currentHadiths = hadiths;
      _loadingHadiths = false;
    });
    // Reset scroll position to top when chapter changes
    if (_contentScrollController.hasClients) {
      _contentScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onChapterSelected(int index) {
    if (index < 0 || index >= _chapters.length || index == _selectedChapterIndex) {
      return;
    }
    setState(() {
      _selectedChapterIndex = index;
    });
    _loadHadithsForChapter(_chapters[index].chapterId);

    // Auto-scroll chapter chips to center selected item
    if (_chapterChipsScrollController.hasClients) {
      const itemWidth = 105.0;
      final targetOffset = (index * itemWidth) - 80.0;
      _chapterChipsScrollController.animateTo(
        targetOffset.clamp(0.0, _chapterChipsScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showChapterJumpModal() {
    const primary = Color(0xFF0F3D26);
    const gold = Color(0xFFD4AF37);
    String modalSearch = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _chapters.where((c) {
              final q = modalSearch.toLowerCase().trim();
              if (q.isEmpty) return true;
              return c.chapterNumber.toString() == q ||
                  c.nameEn.toLowerCase().contains(q) ||
                  c.nameUr.toLowerCase().contains(q) ||
                  c.nameAr.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF9F4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jump to Chapter (${_chapters.length} Total)',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (val) => setModalState(() => modalSearch = val),
                      decoration: InputDecoration(
                        hintText: 'Search chapters by name or number...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: primary, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // List of chapters
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final ch = filtered[idx];
                        final realIndex = _chapters.indexOf(ch);
                        final isSelected = realIndex == _selectedChapterIndex;
                        final count = _repository.getHadithCountForChapter(ch.chapterId);

                        return Material(
                          color: isSelected ? primary.withValues(alpha: 0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pop(ctx);
                              _onChapterSelected(realIndex);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? gold : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isSelected ? primary : const Color(0xFFF0EDE2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${ch.chapterNumber}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (ch.nameAr.isNotEmpty)
                                          Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: Text(
                                              ch.nameAr,
                                              style: const TextStyle(
                                                fontFamily: 'indo_pak',
                                                fontSize: 16,
                                                color: primary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          ch.nameEn.isNotEmpty
                                              ? ch.nameEn
                                              : 'Chapter ${ch.chapterNumber}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3EC),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$count Hadiths',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primary,
                                      ),
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
              ),
            );
          },
        );
      },
    );
  }

  String _formatHadithNumber(num number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toString();
  }

  void _copyHadith(Hadith h) {
    final buffer = StringBuffer();
    buffer.writeln(h.reference.isNotEmpty
        ? h.reference
        : 'Sahih al-Bukhari ${_formatHadithNumber(h.hadithNumber)}');
    buffer.writeln('Grade: ${h.category}');
    if (h.headingEn.isNotEmpty) buffer.writeln('Chapter: ${h.headingEn}');
    buffer.writeln();

    if (h.hadithArabic.isNotEmpty &&
        (_selectedLanguage == HadithViewLanguage.all ||
            _selectedLanguage == HadithViewLanguage.arabic)) {
      buffer.writeln(h.hadithArabic);
      buffer.writeln();
    }

    if (h.hadithUrdu.isNotEmpty &&
        (_selectedLanguage == HadithViewLanguage.all ||
            _selectedLanguage == HadithViewLanguage.urdu)) {
      buffer.writeln(h.hadithUrdu);
      buffer.writeln();
    }

    if (h.hadithEng.isNotEmpty &&
        (_selectedLanguage == HadithViewLanguage.all ||
            _selectedLanguage == HadithViewLanguage.english)) {
      buffer.writeln(h.hadithEng);
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hadith copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareHadith(Hadith h) {
    final buffer = StringBuffer();
    buffer.writeln(h.reference.isNotEmpty
        ? h.reference
        : 'Sahih al-Bukhari ${_formatHadithNumber(h.hadithNumber)}');
    buffer.writeln();

    if (h.hadithArabic.isNotEmpty) {
      buffer.writeln(h.hadithArabic);
      buffer.writeln();
    }

    if (h.hadithUrdu.isNotEmpty) {
      buffer.writeln(h.hadithUrdu);
      buffer.writeln();
    }

    if (h.hadithEng.isNotEmpty) {
      buffer.writeln(h.hadithEng);
      buffer.writeln();
    }

    buffer.writeln('— Shared from Fiqha App');
    Share.share(buffer.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F3D26);
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book ${widget.book.bookNumber}: ${widget.book.nameEn}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.book.nameAr,
              style: const TextStyle(
                fontFamily: 'indo_pak',
                fontSize: 14,
                color: gold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'All Chapters',
            onPressed: _showChapterJumpModal,
          ),
        ],
      ),
      body: FutureBuilder<List<Chapter>>(
        future: _futureChapters,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading chapters: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              ),
            );
          }

          if (_chapters.isEmpty) {
            return Center(
              child: Text(
                'No chapters found in this book',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            );
          }

          final currentChapter = _chapters[_selectedChapterIndex];

          return Column(
            children: [
              // 1. Horizontal Chapter Selector Carousel
              Container(
                color: primary,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    controller: _chapterChipsScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final ch = _chapters[index];
                      final isSelected = index == _selectedChapterIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Ch. ${ch.chapterNumber}'),
                          selected: isSelected,
                          onSelected: (_) => _onChapterSelected(index),
                          selectedColor: gold,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? primary : Colors.white,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isSelected ? gold : Colors.white24,
                              width: 1,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Language Selector Pills
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Language:',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildLangFilterChip('All', HadithViewLanguage.all),
                    const SizedBox(width: 6),
                    _buildLangFilterChip('English', HadithViewLanguage.english),
                    const SizedBox(width: 6),
                    _buildLangFilterChip('اردو', HadithViewLanguage.urdu),
                    const SizedBox(width: 6),
                    _buildLangFilterChip('العربية', HadithViewLanguage.arabic),
                  ],
                ),
              ),

              // 3. Main Content: Chapter Banner + Hadiths List (without extra screen!)
              Expanded(
                child: _loadingHadiths
                    ? const Center(child: CircularProgressIndicator(color: primary))
                    : ListView(
                        controller: _contentScrollController,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
                        children: [
                          // ── Chapter Banner (Repainted Professionally) ──
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0F3D26),
                                  Color(0xFF1B4D36),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: gold.withValues(alpha: 0.6), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Chapter Number & Quick Switch Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: gold, width: 0.8),
                                      ),
                                      child: Text(
                                        'CHAPTER ${currentChapter.chapterNumber} OF ${_chapters.length}',
                                        style: GoogleFonts.inter(
                                          color: gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_currentHadiths.length} Hadiths',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Arabic Bab Heading in Indo-Pak font
                                if (currentChapter.nameAr.isNotEmpty)
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        currentChapter.nameAr,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontFamily: 'indo_pak',
                                          fontSize: 22,
                                          color: Color(0xFFF3E5AB),
                                          height: 1.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),

                                // Urdu Bab Heading in Noto Nastaliq Urdu font
                                if (currentChapter.nameUr.isNotEmpty)
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        currentChapter.nameUr,
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.notoNastaliqUrdu(
                                          fontSize: 14.5,
                                          color: Colors.white,
                                          height: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),

                                // English Bab Heading
                                if (currentChapter.nameEn.isNotEmpty)
                                  Text(
                                    currentChapter.nameEn,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),

                                const SizedBox(height: 14),
                                const Divider(color: Colors.white12, height: 1),
                                const SizedBox(height: 10),

                                // Prev / Next Chapter Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: _selectedChapterIndex > 0
                                          ? () => _onChapterSelected(_selectedChapterIndex - 1)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_back_ios,
                                              size: 12,
                                              color: _selectedChapterIndex > 0 ? gold : Colors.white24,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Previous',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedChapterIndex > 0 ? Colors.white : Colors.white24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_selectedChapterIndex + 1} / ${_chapters.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _selectedChapterIndex < _chapters.length - 1
                                          ? () => _onChapterSelected(_selectedChapterIndex + 1)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Next Chapter',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedChapterIndex < _chapters.length - 1
                                                    ? Colors.white
                                                    : Colors.white24,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: _selectedChapterIndex < _chapters.length - 1
                                                  ? gold
                                                  : Colors.white24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Hadiths List (Repainted Professionally) ──
                          if (_currentHadiths.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No hadiths in this chapter',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._currentHadiths.map((h) => _buildHadithCard(h, primary, gold)),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLangFilterChip(String label, HadithViewLanguage view) {
    const primary = Color(0xFF0F3D26);
    const gold = Color(0xFFD4AF37);
    final isSelected = _selectedLanguage == view;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLanguage = view),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? primary : const Color(0xFFF1EFEA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? gold : Colors.transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHadithCard(Hadith h, Color primary, Color gold) {
    final isSourceEmpty = h.hadithArabic.isEmpty && h.hadithUrdu.isEmpty && h.hadithEng.isEmpty;

    return Card(
      elevation: 1.2,
      margin: const EdgeInsets.symmetric(vertical: 7),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: gold.withValues(alpha: 0.35), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Reference + Category Badge + Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    h.reference.isNotEmpty
                        ? h.reference
                        : 'Sahih al-Bukhari ${_formatHadithNumber(h.hadithNumber)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    h.category.isNotEmpty ? h.category : 'Sahih',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
                  tooltip: 'Copy Hadith',
                  onPressed: () => _copyHadith(h),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 18, color: Colors.grey),
                  tooltip: 'Share Hadith',
                  onPressed: () => _shareHadith(h),
                ),
              ],
            ),

            // Topics
            if (h.topics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: h.topics.take(4).map((topic) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$topic',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A6000),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Empty historical entry notice
            if (isSourceEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This record entry contains no text in the primary manuscript.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],

            // 1. Arabic Text in Indo-Pak font
            if (h.hadithArabic.isNotEmpty &&
                (_selectedLanguage == HadithViewLanguage.all ||
                    _selectedLanguage == HadithViewLanguage.arabic)) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'متن الحديث',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    h.hadithArabic,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'indo_pak',
                      fontSize: 22,
                      height: 2.1,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                ),
              ),
            ],

            // 2. Urdu Translation in Noto Nastaliq Urdu font
            // (Hidden if hadithUrdu is empty — the 33 hadiths)
            if (h.hadithUrdu.trim().isNotEmpty &&
                (_selectedLanguage == HadithViewLanguage.all ||
                    _selectedLanguage == HadithViewLanguage.urdu)) ...[
              if (_selectedLanguage == HadithViewLanguage.all)
                const Divider(height: 24, thickness: 0.8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'اردو ترجمہ',
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 11,
                        color: const Color(0xFF6B5400),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    h.hadithUrdu,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 15.5,
                      height: 2.1,
                      color: const Color(0xFF242424),
                    ),
                  ),
                ),
              ),
            ],

            // 3. English Translation in Inter
            if (h.hadithEng.trim().isNotEmpty &&
                (_selectedLanguage == HadithViewLanguage.all ||
                    _selectedLanguage == HadithViewLanguage.english)) ...[
              if (_selectedLanguage == HadithViewLanguage.all)
                const Divider(height: 24, thickness: 0.8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'English Translation (Muhsin Khan)',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                h.hadithEng,
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.65,
                  color: const Color(0xFF1C1C1C),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
