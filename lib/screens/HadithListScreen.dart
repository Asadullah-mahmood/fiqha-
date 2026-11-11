import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quranpak/screens/HadithDetailScreen.dart'
    show HadithDetailScreen;
import 'package:share_plus/share_plus.dart';

import '../helper/hadith_db.dart';
import '../models/BukhariModels.dart';
import '../repository/BukhariRepository.dart';
import '../utils/hadees_share_card.dart';

enum HadithLanguageView { all, arabic, urdu, english }

class HadithListScreen extends StatefulWidget {
  final Chapter? chapter;
  final Book? book;
  final String? dbFileName;
  final int? chapterId;
  final int? bookNumber;
  final String? chapterTitle;
  final String? bookTitle;

  const HadithListScreen({
    super.key,
    this.chapter,
    this.book,
    this.dbFileName,
    this.chapterId,
    this.bookNumber,
    this.chapterTitle,
    this.bookTitle,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  late final Future<List<Hadith>> _futureHadiths;
  HadithLanguageView _selectedLanguage = HadithLanguageView.all;

  static const _ink = Color(0xFF14201A);
  static const _paper = Color(0xFFF7F4EC);
  static const _primary = Color(0xFF0F3D26);
  static const _gold = Color(0xFFC9A227);

  @override
  void initState() {
    super.initState();
    if (widget.dbFileName != null && widget.chapterId != null) {
      _futureHadiths = HadithDb.getHadiths(
        widget.dbFileName!,
        widget.chapterId!,
      ).then((items) => items.map((item) => item.toHadith()).toList());
    } else if (widget.dbFileName != null && widget.bookNumber != null) {
      _futureHadiths = HadithDb.getHadithsByBook(
        widget.dbFileName!,
        widget.bookNumber!,
      ).then((items) => items.map((item) => item.toHadith()).toList());
    } else if (widget.chapter != null) {
      _futureHadiths = BukhariRepository.instance.getHadiths(
        widget.chapter!.chapterId,
      );
    } else {
      _futureHadiths = Future.value([]);
    }
  }

  String _formatHadithNumber(num number) {
    if (number == number.toInt()) return number.toInt().toString();
    return number.toString();
  }

  // ── Shared text builder used by copy + share ──
  String _buildHadithText(Hadith h, {bool withHeader = true}) {
    final b = StringBuffer();
    if (withHeader) {
      b.writeln(
        h.reference.isNotEmpty
            ? h.reference
            : 'Hadith ${_formatHadithNumber(h.hadithNumber)}',
      );
      b.writeln();
    }
    if (h.hadithArabic.isNotEmpty) {
      b.writeln(h.hadithArabic);
      b.writeln();
    }
    if (h.hadithUrdu.isNotEmpty) {
      b.writeln(h.hadithUrdu);
      b.writeln();
    }
    if (h.hadithEng.isNotEmpty) {
      b.writeln(h.hadithEng);
      b.writeln();
    }
    return b.toString().trim();
  }

  void _copyHadith(Hadith h) {
    Clipboard.setData(ClipboardData(text: _buildHadithText(h)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.down,
        backgroundColor: _primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        content: Center(
          child: Text('Hadith # ${h.hadithNumber} copied to clipboard'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareHadith(Hadith h) async {
    await shareHadithAsCard(
      context,
      h,
      formattedNumber: _formatHadithNumber(h.hadithNumber),
      appName: 'Fiqah',
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText =
        widget.chapterTitle ??
        widget.bookTitle ??
        (widget.chapter?.nameEn.isNotEmpty == true
            ? widget.chapter!.nameEn
            : 'Hadiths');

    final subtitle =
        widget.bookTitle ??
        (widget.book != null
            ? 'Book ${widget.book!.bookNumber} · ${widget.book!.nameEn}'
            : null);

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD4C68A),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
      body: FutureBuilder<List<Hadith>>(
        future: _futureHadiths,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          if (snapshot.hasError) {
            return _ErrorState(message: '${snapshot.error}');
          }

          final hadiths = snapshot.data ?? [];
          if (hadiths.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            children: [
              _LanguageBar(
                count: hadiths.length,
                selected: _selectedLanguage,
                onChanged: (v) => setState(() => _selectedLanguage = v),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: hadiths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final h = hadiths[index];
                    return _HadithCard(
                      hadith: h,
                      displayNumber: _formatHadithNumber(h.hadithNumber),
                      language: _selectedLanguage,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HadithDetailScreen(hadith: h),
                        ),
                      ),
                      onCopy: () => _copyHadith(h),
                      onShare: () => _shareHadith(h),
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

// ─────────────────────────────────────────────────────────────
// Language bar — clean, single row, no rounded box fighting content
// ─────────────────────────────────────────────────────────────
class _LanguageBar extends StatelessWidget {
  final int count;
  final HadithLanguageView selected;
  final ValueChanged<HadithLanguageView> onChanged;

  const _LanguageBar({
    required this.count,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _HadithListScreenState._ink.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: _HadithListScreenState._gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count ${count == 1 ? 'Hadith' : 'Hadiths'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _HadithListScreenState._ink.withValues(alpha: 0.75),
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                'View',
                style: TextStyle(
                  fontSize: 10.5,
                  color: _HadithListScreenState._ink.withValues(alpha: 0.4),
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LangChip(
                label: 'All',
                isSelected: selected == HadithLanguageView.all,
                onTap: () => onChanged(HadithLanguageView.all),
              ),
              const SizedBox(width: 6),
              _LangChip(
                label: 'English',
                isSelected: selected == HadithLanguageView.english,
                onTap: () => onChanged(HadithLanguageView.english),
              ),
              const SizedBox(width: 6),
              _LangChip(
                label: 'اردو',
                fontFamily: 'notoNastaliqUrdu',
                isSelected: selected == HadithLanguageView.urdu,
                onTap: () => onChanged(HadithLanguageView.urdu),
              ),
              const SizedBox(width: 6),
              _LangChip(
                label: 'العربية',
                fontFamily: 'indo_pak',
                isSelected: selected == HadithLanguageView.arabic,
                onTap: () => onChanged(HadithLanguageView.arabic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final String? fontFamily;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    this.fontFamily,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = _HadithListScreenState._ink;
    final primary = _HadithListScreenState._primary;

    return Expanded(
      child: Material(
        color: isSelected ? primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? primary : ink.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontFamily != null ? 12.5 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : ink.withValues(alpha: 0.65),
                height: fontFamily != null ? 1.9 : 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hadith card — manuscript reading layout
// ─────────────────────────────────────────────────────────────
class _HadithCard extends StatelessWidget {
  final Hadith hadith;
  final String displayNumber;
  final HadithLanguageView language;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _HadithCard({
    required this.hadith,
    required this.displayNumber,
    required this.language,
    required this.onTap,
    required this.onCopy,
    required this.onShare,
  });

  static const _ink = _HadithListScreenState._ink;
  static const _primary = _HadithListScreenState._primary;
  static const _gold = _HadithListScreenState._gold;

  bool get _showArabic =>
      hadith.hadithArabic.isNotEmpty &&
      (language == HadithLanguageView.all ||
          language == HadithLanguageView.arabic);

  bool get _showUrdu =>
      hadith.hadithUrdu.isNotEmpty &&
      (language == HadithLanguageView.all ||
          language == HadithLanguageView.urdu);

  bool get _showEnglish =>
      hadith.hadithEng.isNotEmpty &&
      (language == HadithLanguageView.all ||
          language == HadithLanguageView.english);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _ink.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.035),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar: number + grade + actions ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 0),
                child: Row(
                  children: [
                    // Hadith number — small, subtle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Hadith $displayNumber',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Grade chip — only if available
                    if (hadith.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hadith.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Compact actions
                    _IconAction(
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy',
                      onTap: onCopy,
                    ),
                    _IconAction(
                      icon: Icons.ios_share_rounded,
                      tooltip: 'Share',
                      onTap: onShare,
                    ),
                  ],
                ),
              ),

              // ── Chapter heading (small, muted) ──
              if (hadith.headingEn.isNotEmpty || hadith.headingUr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Text(
                    hadith.headingEn.isNotEmpty
                        ? hadith.headingEn
                        : hadith.headingUr,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: _ink.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 10),

              // ── Arabic — the sacred text (primary) ──
              if (_showArabic)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        hadith.hadithArabic,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'indo_pak',
                          fontSize: 21,
                          height: 1.85,
                          color: Color(0xFF1A2E22),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Gold divider between languages ──
              if (_showArabic && (_showUrdu || _showEnglish))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _gold.withValues(alpha: 0),
                                _gold.withValues(alpha: 0.35),
                                _gold.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Transform.rotate(
                          angle: 0.785,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _gold.withValues(alpha: 0),
                                _gold.withValues(alpha: 0.35),
                                _gold.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Urdu translation ──
              if (_showUrdu)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        hadith.hadithUrdu,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.notoNastaliqUrdu(
                          fontSize: 14,
                          height: 2.05,
                          color: _ink.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── English translation ──
              if (_showEnglish)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, _showUrdu ? 12 : 0, 16, 0),
                  child: Text(
                    hadith.hadithEng,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.65,
                      color: _ink.withValues(alpha: 0.75),
                    ),
                  ),
                ),

              // ── Bottom spacer ──
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small round icon action
// ─────────────────────────────────────────────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 17,
            color: _HadithListScreenState._ink.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: _HadithListScreenState._ink.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 14),
            Text(
              'No hadiths found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _HadithListScreenState._ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.red.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load hadiths',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _HadithListScreenState._ink.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: _HadithListScreenState._ink.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
