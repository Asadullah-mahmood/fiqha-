import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../helper/hadith_db.dart';
import '../models/BukhariModels.dart';
import 'HadithDetailScreen.dart';

enum _SearchTab { number, topic, narrator }

class _ParsedRow {
  final Hadith hadith;
  final num number;
  final Set<String> topics, keywordsEng, keywordsUrdu;
  final String normHeading,
      normBody,
      normArabic,
      normUrdu,
      normEng,
      normUrduStart,
      normArabicStart;

  _ParsedRow({
    required this.hadith,
    required this.number,
    required this.topics,
    required this.keywordsEng,
    required this.keywordsUrdu,
    required this.normHeading,
    required this.normBody,
    required this.normArabic,
    required this.normUrdu,
    required this.normEng,
    required this.normUrduStart,
    required this.normArabicStart,
  });
}

class HadithSearchScreen extends StatefulWidget {
  final String dbFileName;
  final String collectionName;

  const HadithSearchScreen({
    super.key,
    required this.dbFileName,
    required this.collectionName,
  });

  @override
  State<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends State<HadithSearchScreen> {
  static const Color ink = Color(0xFF14201A),
      paper = Color(0xFFF7F4EC),
      primary = Color(0xFF0F3D26),
      gold = Color(0xFFC9A227);

  static const List<String> _popularTopics = [
    'Namaz',
    'Roza',
    'Zakat',
    'Hajj',
    'Divorce',
    'Nikah',
    'Inheritance',
    'Jihad',
    'Prayer',
    'Fasting',
    'Charity',
    'Patience',
    'Forgiveness',
    'Neighbors',
    'Parents',
    'Orphans',
    'Marriage',
    'Trade',
    'Interest',
    'Alcohol',
  ];

  _SearchTab _tab = _SearchTab.topic;
  String _query = '';
  final TextEditingController _controller = TextEditingController();
  List<_ParsedRow> _rows = [];
  List<Hadith> _results = [];
  bool _loading = true;
  int _queryToken = 0;
  Timer? _debounceTimer;

  static String norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'[إأآا]'), 'ا')
      .replaceAll(RegExp(r'ى'), 'ی')
      .replaceAll(RegExp(r'ة'), 'ہ')
      .replaceAll(RegExp(r'[^\w\u0600-\u06FF ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Set<String> _parseJsonSet(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List)
        return decoded
            .map((e) => norm(e.toString()))
            .where((e) => e.isNotEmpty)
            .toSet();
    } catch (_) {}
    return const {};
  }

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    final rawItems = await HadithDb.getAllHadithsOfCollection(
      widget.dbFileName,
    );
    final parsed = rawItems.map((item) {
      final nAr = norm(item.arabic),
          nUr = norm(item.urdu),
          nEn = norm(item.english);
      return _ParsedRow(
        hadith: item.toHadith(),
        number: item.hadithNumber,
        topics: _parseJsonSet(item.topics),
        keywordsEng: _parseJsonSet(item.keywordsEng),
        keywordsUrdu: _parseJsonSet(item.keywordsUrdu),
        normHeading: norm(
          '${item.headingEn} ${item.headingUr} ${item.headingAr}',
        ),
        normBody: '$nAr $nUr $nEn',
        normArabic: nAr,
        normUrdu: nUr,
        normEng: nEn,
        normUrduStart: norm(
          item.urdu.length > 120 ? item.urdu.substring(0, 120) : item.urdu,
        ),
        normArabicStart: norm(
          item.arabic.length > 120
              ? item.arabic.substring(0, 120)
              : item.arabic,
        ),
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _rows = parsed;
      _loading = false;
    });
  }

  void _onQueryChanged(String val) {
    setState(() => _query = val);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _executeSearch);
  }

  void _executeSearch() {
    final currentToken = ++_queryToken;
    final q = _query.trim();
    if (q.isEmpty || _rows.isEmpty) {
      if (mounted && currentToken == _queryToken) setState(() => _results = []);
      return;
    }

    List<Hadith> matched = [];
    switch (_tab) {
      case _SearchTab.number:
        final cleanDigits = RegExp(r'\d+(\.\d+)?').firstMatch(q)?.group(0);
        if (cleanDigits != null) {
          final targetNum = num.tryParse(cleanDigits);
          if (targetNum != null) {
            for (final r in _rows) {
              if (r.number == targetNum || r.number == targetNum.toInt()) {
                matched.add(r.hadith);
                break;
              }
            }
          }
        }
        break;

      case _SearchTab.topic:
        final nq = norm(q);
        if (nq.isEmpty) break;
        final scored = <MapEntry<_ParsedRow, int>>[];
        for (final r in _rows) {
          int score = 0;
          if (r.topics.contains(nq)) {
            score = 5;
          } else if (r.keywordsEng.contains(nq) ||
              r.keywordsUrdu.contains(nq)) {
            score = 4;
          } else if (r.normHeading.contains(nq)) {
            score = 3;
          } else if (r.normBody.contains(nq)) {
            score = 2;
          } else if (r.topics.any((t) => t.contains(nq)) ||
              r.keywordsEng.any((k) => k.contains(nq)) ||
              r.keywordsUrdu.any((k) => k.contains(nq))) {
            score = 1;
          }
          if (score > 0) scored.add(MapEntry(r, score));
        }
        scored.sort((a, b) {
          final c = b.value.compareTo(a.value);
          return c != 0 ? c : a.key.number.compareTo(b.key.number);
        });
        matched = scored.take(50).map((e) => e.key.hadith).toList();
        break;

      case _SearchTab.narrator:
        final nq = norm(q);
        if (nq.isEmpty) break;
        final scored = <MapEntry<_ParsedRow, int>>[];
        for (final r in _rows) {
          int score = 0;
          if (r.normUrduStart.contains(nq) || r.normArabicStart.contains(nq)) {
            score = 3;
          } else if (r.normUrdu.contains(nq) ||
              r.normArabic.contains(nq) ||
              r.normEng.contains(nq)) {
            score = 1;
          }
          if (score > 0) scored.add(MapEntry(r, score));
        }
        scored.sort((a, b) {
          final c = b.value.compareTo(a.value);
          return c != 0 ? c : a.key.number.compareTo(b.key.number);
        });
        matched = scored.take(50).map((e) => e.key.hadith).toList();
        break;
    }

    if (!mounted || currentToken != _queryToken) return;
    setState(() => _results = matched);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.collectionName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Search',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              style: const TextStyle(fontSize: 14, color: ink),
              decoration: InputDecoration(
                hintText: 'Search by number, topic, or narrator…',
                hintStyle: TextStyle(
                  color: ink.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: primary,
                  size: 22,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: ink,
                        ),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: ink.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: ink.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _tabChip('By Topic', _SearchTab.topic),
                const SizedBox(width: 8),
                _tabChip('By Number', _SearchTab.number),
                const SizedBox(width: 8),
                _tabChip('By Narrator', _SearchTab.narrator),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _popularTopics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final topic = _popularTopics[i];
                final isSelected =
                    _tab == _SearchTab.topic &&
                    _query.toLowerCase() == topic.toLowerCase();
                return ActionChip(
                  label: Text(topic),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : ink,
                  ),
                  backgroundColor: isSelected ? primary : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? primary : ink.withValues(alpha: 0.1),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.text = topic;
                    setState(() {
                      _tab = _SearchTab.topic;
                      _query = topic;
                    });
                    _executeSearch();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _query.trim().isEmpty
                ? _emptyState(
                    Icons.menu_book_rounded,
                    'Start typing or pick a topic',
                  )
                : _results.isEmpty
                ? _emptyState(Icons.search_off_rounded, 'No hadiths found')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => _ResultCard(
                      hadith: _results[i],
                      query: _query.trim(),
                      ink: ink,
                      primary: primary,
                      gold: gold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, _SearchTab tab) {
    final active = _tab == tab;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_tab == tab) return;
          setState(() => _tab = tab);
          _executeSearch();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? primary : ink.withValues(alpha: 0.1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 52, color: ink.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );
}

class _ResultCard extends StatelessWidget {
  final Hadith hadith;
  final String query;
  final Color ink, primary, gold;

  const _ResultCard({
    required this.hadith,
    required this.query,
    required this.ink,
    required this.primary,
    required this.gold,
  });

  String _formatNum(num n) =>
      n == n.toInt() ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    final heading = hadith.headingEn.isNotEmpty
        ? hadith.headingEn
        : hadith.headingUr;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HadithDetailScreen(hadith: hadith)),
        ),
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Hadith ${_formatNum(hadith.hadithNumber)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Share',
                    onPressed: () {
                      final text =
                          '${hadith.reference}\n\n${hadith.hadithArabic}\n\n${hadith.hadithUrdu}\n\n${hadith.hadithEng}';
                      SharePlus.instance.share(ShareParams(text: text));
                    },
                  ),
                ],
              ),
              if (heading.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: ink.withValues(alpha: 0.55),
                  ),
                ),
              ],
              if (hadith.hadithArabic.isNotEmpty) ...[
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      hadith.hadithArabic,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'indo_pak',
                        fontSize: 17,
                        height: 1.8,
                        color: Color(0xFF1A2E22),
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gold.withValues(alpha: 0),
                              gold.withValues(alpha: 0.35),
                              gold.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Transform.rotate(
                        angle: 0.785,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.6),
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
                              gold.withValues(alpha: 0),
                              gold.withValues(alpha: 0.35),
                              gold.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hadith.hadithUrdu.isNotEmpty) ...[
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      hadith.hadithUrdu,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 13,
                        height: 2.1,
                        color: ink.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (hadith.hadithEng.isNotEmpty)
                _buildHighlightedEnglish(hadith.hadithEng, query),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedEnglish(String text, String q) {
    final baseStyle = GoogleFonts.inter(
      fontSize: 13,
      height: 1.6,
      color: ink.withValues(alpha: 0.75),
    );
    if (q.isEmpty || !text.toLowerCase().contains(q.toLowerCase())) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }
    final spans = <TextSpan>[];
    final pattern = RegExp(RegExp.escape(q), caseSensitive: false);
    int start = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > start)
        spans.add(
          TextSpan(text: text.substring(start, m.start), style: baseStyle),
        );
      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: baseStyle.copyWith(
            backgroundColor: gold.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      );
      start = m.end;
    }
    if (start < text.length)
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
