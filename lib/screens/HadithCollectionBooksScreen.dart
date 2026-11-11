import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helper/hadith_db.dart';
import '../models/HadithBook.dart';
import 'HadithListScreen.dart';
import 'HadithSearchScreen.dart';

class HadithCollectionBooksScreen extends StatefulWidget {
  final String dbFileName;
  final String collectionName;

  const HadithCollectionBooksScreen({
    super.key,
    required this.dbFileName,
    required this.collectionName,
  });

  @override
  State<HadithCollectionBooksScreen> createState() =>
      _HadithCollectionBooksScreenState();
}

class _HadithCollectionBooksScreenState
    extends State<HadithCollectionBooksScreen> {
  late final Future<List<HadithBookModel>> _futureBooks =
  HadithDb.getBooks(widget.dbFileName);
  String _searchQuery = '';
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchOpen = false;
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF14201A);
    const paper = Color(0xFFF7F4EC);
    const primary = Color(0xFF0F3D26);
    const gold = Color(0xFFC9A227);

    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: _searchOpen
            ? _buildSearchField(primary)
            : Text(
          widget.collectionName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.15,
          ),
        ),
        actions: _searchOpen
            ? [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'Close search',
                  onPressed: _closeSearch,
                ),
                const SizedBox(width: 4),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded, size: 22),
                  tooltip: 'Filter books',
                  onPressed: _openSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, size: 22),
                  tooltip: 'Search Hadiths',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithSearchScreen(
                        dbFileName: widget.dbFileName,
                        collectionName: widget.collectionName,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: FutureBuilder<List<HadithBookModel>>(
        future: _futureBooks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading books:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            );
          }

          final books = snapshot.data ?? [];
          final filtered = books.where((book) {
            final q = _searchQuery.toLowerCase().trim();
            if (q.isEmpty) return true;
            return book.bookNumber.toString() == q ||
                book.nameEn.toLowerCase().contains(q) ||
                book.nameUr.toLowerCase().contains(q) ||
                book.nameAr.toLowerCase().contains(q);
          }).toList();

          if (filtered.isEmpty) {
            return _EmptyState(
              searching: _searchQuery.isNotEmpty,
              ink: ink,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: filtered.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SectionHeader(
                  count: filtered.length,
                  searching: _searchQuery.isNotEmpty,
                  ink: ink,
                  gold: gold,
                );
              }
              final book = filtered[index - 1];
              return _BookCard(
                book: book,
                ink: ink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithListScreen(
                        dbFileName: widget.dbFileName,
                        bookNumber: book.bookNumber,
                        bookTitle: book.nameEn.isNotEmpty
                            ? book.nameEn
                            : 'Book ${book.bookNumber}',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Inline search field
  // ───────────────────────────────────────────────────────────
  Widget _buildSearchField(Color primary) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (val) => setState(() => _searchQuery = val),
        textInputAction: TextInputAction.search,
        cursorColor: primary,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by name or number…',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: primary,
          ),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 36, minHeight: 36),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final int count;
  final bool searching;
  final Color ink;
  final Color gold;

  const _SectionHeader({
    required this.count,
    required this.searching,
    required this.ink,
    required this.gold,
  });

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
            searching ? 'Results' : 'Chapters',
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
              '$count',
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
// Simple book card — English left, Arabic + Urdu right
// ─────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final HadithBookModel book;
  final Color ink;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleEn =
    book.nameEn.isNotEmpty ? book.nameEn : 'Book ${book.bookNumber}';
    final hasArabic = book.nameAr.isNotEmpty;
    final hasUrdu = book.nameUr.isNotEmpty;
    final hasRight = hasArabic || hasUrdu;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ink.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: ink.withValues(alpha: 0.035),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── LEFT: English title ──
              Expanded(
                flex: 5,
                child: Text(
                  titleEn,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: ink,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (hasRight) ...[
                // thin vertical separator
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: ink.withValues(alpha: 0.08),
                ),

                // ── RIGHT: Arabic + Urdu (RTL) ──
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasArabic)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            book.nameAr,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.playpenSansArabic(
                              fontSize: 16,
                              color: Color(0xFF0F3D26),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (hasArabic && hasUrdu) const SizedBox(height: 4),
                      if (hasUrdu)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            book.nameUr,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.notoNastaliqUrdu(
                              fontSize: 12.5,
                              color: ink.withValues(alpha: 0.72),
                              height: 2.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool searching;
  final Color ink;
  const _EmptyState({required this.searching, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching
                  ? Icons.search_off_rounded
                  : Icons.menu_book_outlined,
              size: 48,
              color: ink.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 14),
            Text(
              searching ? 'No books match your search' : 'No books available',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ink.withValues(alpha: 0.7),
              ),
            ),
            if (searching) ...[
              const SizedBox(height: 4),
              Text(
                'Try a different name or number',
                style: TextStyle(
                  fontSize: 12,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}