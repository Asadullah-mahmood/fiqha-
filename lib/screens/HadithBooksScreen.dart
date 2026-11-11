import 'package:flutter/material.dart';
import 'HadithCollectionBooksScreen.dart';

class HadithCollectionInfo {
  final String id;
  final String nameAr;
  final String nameUr;
  final String nameEn;
  final String author;
  final String authorUrdu;
  final String hadithCount;
  final String deathYear;
  final bool isAvailable;
  final String? dbFileName;
  final Color primaryColor;

  const HadithCollectionInfo({
    required this.id,
    required this.nameAr,
    required this.nameUr,
    required this.nameEn,
    required this.author,
    required this.authorUrdu,
    required this.hadithCount,
    required this.deathYear,
    required this.isAvailable,
    this.dbFileName,
    required this.primaryColor,
  });
}

class HadithBooksScreen extends StatelessWidget {
  const HadithBooksScreen({super.key});

  static const List<HadithCollectionInfo> sixBooks = [
    HadithCollectionInfo(
      id: 'bukhari',
      nameAr: 'صَحِيحُ البُخَارِيّ',
      nameUr: 'صحیح بخاری شریف',
      nameEn: 'Sahih al-Bukhari',
      author: 'Imam Muhammad al-Bukhari',
      authorUrdu: 'امام محمد بن اسماعیل بخاریؒ',
      hadithCount: '7,589',
      deathYear: '256 AH',
      isAvailable: true,
      dbFileName: 'sahih-bukhari.db',
      primaryColor: Color(0xFF0F3D26),
    ),
    HadithCollectionInfo(
      id: 'muslim',
      nameAr: 'صَحِيحُ مُسْلِم',
      nameUr: 'صحیح مسلم شریف',
      nameEn: 'Sahih Muslim',
      author: 'Imam Muslim ibn al-Hajjaj',
      authorUrdu: 'امام مسلم بن الحجاجؒ',
      hadithCount: '7,500+',
      deathYear: '261 AH',
      isAvailable: true,
      dbFileName: 'sahih-muslim.db',
      primaryColor: Color(0xFF1B4952),
    ),
    HadithCollectionInfo(
      id: 'abudawud',
      nameAr: 'سُنَنُ أَبِي دَاوُد',
      nameUr: 'سنن ابوداؤد',
      nameEn: 'Sunan Abu Dawud',
      author: 'Imam Abu Dawud al-Sijistani',
      authorUrdu: 'امام ابو داؤد السجستانیؒ',
      hadithCount: '5,274',
      deathYear: '275 AH',
      isAvailable: true,
      dbFileName: 'sunan-abu-dawud.db',
      primaryColor: Color(0xFF523A1B),
    ),
    HadithCollectionInfo(
      id: 'tirmidhi',
      nameAr: 'جَامِعُ التِّرْمِذِيّ',
      nameUr: 'جامع الترمذی',
      nameEn: 'Jami at-Tirmidhi',
      author: 'Imam Al-Tirmidhi',
      authorUrdu: 'امام محمد بن عیسیٰ الترمذیؒ',
      hadithCount: '3,956',
      deathYear: '279 AH',
      isAvailable: true,
      dbFileName: 'jami-at-tirmidhi.db',
      primaryColor: Color(0xFF421B52),
    ),
    HadithCollectionInfo(
      id: 'nasai',
      nameAr: 'سُنَنُ النَّسَائِيّ',
      nameUr: 'سنن النسائی',
      nameEn: "Sunan an-Nasa'i",
      author: "Imam An-Nasa'i",
      authorUrdu: 'امام احمد بن شعيب النسائیؒ',
      hadithCount: '5,760',
      deathYear: '303 AH',
      isAvailable: true,
      dbFileName: 'sunan-an-nasai.db',
      primaryColor: Color(0xFF1B3252),
    ),
    HadithCollectionInfo(
      id: 'ibnmajah',
      nameAr: 'سُنَنُ ابْنِ مَاجَه',
      nameUr: 'سنن ابن ماجہ',
      nameEn: 'Sunan Ibn Majah',
      author: 'Imam Ibn Majah',
      authorUrdu: 'امام محمد بن یزید ابن ماجہؒ',
      hadithCount: '4,341',
      deathYear: '273 AH',
      isAvailable: true,
      dbFileName: 'sunan-ibn-majah.db',
      primaryColor: Color(0xFF521B1B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF14201A);
    const paper = Color(0xFFF7F4EC);
    const gold = Color(0xFFC9A227);

    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3D26),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hadith Collections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'الكتب الستة · The Six Books',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: sixBooks.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SectionHeader(total: sixBooks.length, gold: gold, ink: ink);
          }
          final book = sixBooks[index - 1];
          return _BookCard(
            book: book,
            gold: gold,
            ink: ink,
            onTap: () {
              if (book.isAvailable && book.dbFileName != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HadithCollectionBooksScreen(
                      dbFileName: book.dbFileName!,
                      collectionName: book.nameEn,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header — small, editorial, no decoration
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final int total;
  final Color gold;
  final Color ink;
  const _SectionHeader({required this.total, required this.gold, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'All Collections',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ink.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Single uniform card — reused for every book
// ─────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final HadithCollectionInfo book;
  final Color gold;
  final Color ink;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.gold,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ink.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: ink.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar: color strip + emblem + name + count ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colored emblem block
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: book.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // English name + count badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  book.nameEn,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: book.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  book.hadithCount,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: book.primaryColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Arabic name
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              book.nameAr,
                              style: TextStyle(
                                fontFamily: 'indo_pak',
                                fontSize: 16,
                                color: book.primaryColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Urdu name + author ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    '${book.nameUr} • ${book.authorUrdu}',
                    style: TextStyle(
                      fontFamily: 'notoNastaliqUrdu',
                      fontSize: 12,
                      color: ink.withValues(alpha: 0.7),
                      height: 1.9,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Divider ──
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: ink.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 10),

              // ── Bottom meta row: author + death + arrow ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: ink.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: ink.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      book.deathYear,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: ink.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: book.primaryColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}