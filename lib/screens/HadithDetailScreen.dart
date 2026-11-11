import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../models/BukhariModels.dart';

class HadithDetailScreen extends StatelessWidget {
  final Hadith hadith;

  const HadithDetailScreen({super.key, required this.hadith});

  static const _ink = Color(0xFF14201A);
  static const _paper = Color(0xFFF7F4EC);
  static const _primary = Color(0xFF0F3D26);
  static const _gold = Color(0xFFC9A227);

  String _formatHadithNumber(num number) {
    if (number == number.toInt()) return number.toInt().toString();
    return number.toString();
  }

  String _getGradeUrdu(String grade) {
    final g = grade.toLowerCase();
    if (g.contains('hasan') || g.contains('حسن')) return 'حسن';
    if (g.contains('daif') ||
        g.contains('ضعیف') ||
        g.contains('da\'if') ||
        g.contains('daeef')) {
      return 'ضعیف';
    }
    return 'صحیح';
  }

  Color _getGradeColor(String grade) {
    final g = grade.toLowerCase();
    if (g.contains('hasan') || g.contains('حسن'))
      return const Color(0xFFE68A00);
    if (g.contains('daif') ||
        g.contains('ضعیف') ||
        g.contains('da\'if') ||
        g.contains('daeef')) {
      return const Color(0xFFC62828);
    }
    return const Color(0xFF2E7D32);
  }

  void _copyHadith(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln(
      hadith.reference.isNotEmpty
          ? hadith.reference
          : 'Hadith ${_formatHadithNumber(hadith.hadithNumber)}',
    );
    buffer.writeln('Grade: ${hadith.category}');
    if (hadith.headingEn.isNotEmpty) {
      buffer.writeln('Chapter: ${hadith.headingEn}');
    }
    buffer.writeln();

    if (hadith.hadithArabic.isNotEmpty) {
      buffer.writeln(hadith.hadithArabic);
      buffer.writeln();
    }
    if (hadith.hadithUrdu.isNotEmpty) {
      buffer.writeln(hadith.hadithUrdu);
      buffer.writeln();
    }
    if (hadith.hadithEng.isNotEmpty) {
      buffer.writeln(hadith.hadithEng);
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        content: Text(
          'Hadith #${_formatHadithNumber(hadith.hadithNumber)} copied',
          style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareHadith(BuildContext context) async {
    await shareHadithAsCard(
      context,
      hadith,
      formattedNumber: _formatHadithNumber(hadith.hadithNumber),
      appName: 'Fiqha',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSourceEmpty =
        hadith.hadithArabic.isEmpty &&
        hadith.hadithUrdu.isEmpty &&
        hadith.hadithEng.isEmpty;

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
              hadith.reference.isNotEmpty
                  ? hadith.reference
                  : 'Hadith #${_formatHadithNumber(hadith.hadithNumber)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Hadith ${_formatHadithNumber(hadith.hadithNumber)}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy',
            onPressed: () => _copyHadith(context),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Share as image',
            onPressed: () => _shareHadith(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Meta strip: grade + topics ──
            _buildMetaStrip(),
            const SizedBox(height: 14),

            // ── Chapter heading ──
            if (hadith.headingAr.isNotEmpty ||
                hadith.headingUr.isNotEmpty ||
                hadith.headingEn.isNotEmpty) ...[
              _buildChapterHeading(),
              const SizedBox(height: 14),
            ],

            // ── Empty record notice ──
            if (isSourceEmpty) _buildEmptyNotice(),

            // ── Arabic — hero card ──
            if (hadith.hadithArabic.isNotEmpty) ...[
              _buildArabicCard(),
              const SizedBox(height: 14),
            ],

            // ── Urdu ──
            if (hadith.hadithUrdu.trim().isNotEmpty) ...[
              _buildUrduCard(),
              const SizedBox(height: 14),
            ],

            // ── English ──
            if (hadith.hadithEng.trim().isNotEmpty) ...[
              _buildEnglishCard(),
              const SizedBox(height: 20),
            ],

            // ── Share CTA at bottom ──
            _buildShareButton(context),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // META STRIP — grade + topics inline
  // ───────────────────────────────────────────────────────────
  Widget _buildMetaStrip() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Grade chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _getGradeColor(hadith.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getGradeColor(hadith.category).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getGradeColor(hadith.category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                hadith.category.isNotEmpty ? hadith.category : 'Sahih',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _getGradeColor(hadith.category),
                ),
              ),
            ],
          ),
        ),
        // Urdu grade label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _getGradeUrdu(hadith.category),
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 11,
              height: 1.9,
              fontWeight: FontWeight.w600,
              color: _primary,
            ),
          ),
        ),
        // Topics
        if (hadith.topics.isNotEmpty)
          ...hadith.topics.map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _gold.withValues(alpha: 0.25)),
              ),
              child: Text(
                '#$t',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B5400),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  // CHAPTER HEADING
  // ───────────────────────────────────────────────────────────
  Widget _buildChapterHeading() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ink.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CHAPTER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _gold,
                ),
              ),
            ],
          ),
          if (hadith.headingAr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                hadith.headingAr,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'indo_pak',
                  fontSize: 16,
                  height: 1.7,
                  color: _primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (hadith.headingUr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                hadith.headingUr,
                textAlign: TextAlign.right,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 12.5,
                  height: 2.0,
                  color: _ink.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
          if (hadith.headingEn.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hadith.headingEn,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: _ink.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // EMPTY NOTICE
  // ───────────────────────────────────────────────────────────
  Widget _buildEmptyNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: _ink.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This record entry contains no text in the primary manuscript.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: _ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // ARABIC CARD — hero, parchment style
  // ───────────────────────────────────────────────────────────
  Widget _buildArabicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0F3D26), const Color(0xFF0A2C1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark corner ornament
          Positioned(
            bottom: -25,
            left: -25,
            child: Icon(
              Icons.menu_book_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          // Gold top edge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gold.withValues(alpha: 0.0),
                    _gold.withValues(alpha: 0.7),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.language_rounded, size: 14, color: _gold),
                  const SizedBox(width: 6),
                  Text(
                    'ARABIC · الحديث بالعربية',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  hadith.hadithArabic,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 22,
                    height: 2.05,
                    color: const Color(0xFFF4EFE3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // URDU CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildUrduCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'URDU · اردو ترجمہ',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              hadith.hadithUrdu,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 14,
                height: 2.3,
                color: _ink.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // ENGLISH CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildEnglishCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: _ink.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ENGLISH TRANSLATION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _ink.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hadith.hadithEng,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.7,
              color: _ink.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // SHARE BUTTON at bottom — big, prominent
  // ───────────────────────────────────────────────────────────
  Widget _buildShareButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _shareHadith(context),
        icon: const Icon(
          Icons.ios_share_rounded,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          'Share as Image',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PNG SHARE — off-screen render + capture
// ═══════════════════════════════════════════════════════════════
Future<void> shareHadithAsCard(
  BuildContext context,
  Hadith hadith, {
  required String formattedNumber,
  String appName = 'Fiqha',
}) async {
  // Preload fonts (critical for Nastaliq)
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoNastaliqUrdu(),
    GoogleFonts.amiriQuran(),
    GoogleFonts.inter(),
  ]);

  final overlay = Overlay.of(context);
  final completer = Completer<Uint8List?>();

  final entry = OverlayEntry(
    builder: (_) => _OffscreenCardRenderer(
      hadith: hadith,
      formattedNumber: formattedNumber,
      appName: appName,
      onDone: (bytes) {
        if (!completer.isCompleted) completer.complete(bytes);
      },
    ),
  );
  overlay.insert(entry);

  final bytes = await completer.future;
  entry.remove();
  if (bytes == null) return;

  // Save to temp dir
  final tempDir = Directory.systemTemp;
  final file = File(
    '${tempDir.path}/hadith_${formattedNumber}_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes);

  await Share.shareXFiles([
    XFile(file.path, mimeType: 'image/png'),
  ], text: 'Hadith $formattedNumber — shared from $appName');
}

class _OffscreenCardRenderer extends StatefulWidget {
  final Hadith hadith;
  final String formattedNumber;
  final String appName;
  final ValueChanged<Uint8List?> onDone;

  const _OffscreenCardRenderer({
    required this.hadith,
    required this.formattedNumber,
    required this.appName,
    required this.onDone,
  });

  @override
  State<_OffscreenCardRenderer> createState() => _OffscreenCardRendererState();
}

class _OffscreenCardRendererState extends State<_OffscreenCardRenderer> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        widget.onDone(null);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      widget.onDone(byteData?.buffer.asUint8List());
    } catch (_) {
      widget.onDone(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -3000,
      top: -3000,
      child: RepaintBoundary(
        key: _key,
        child: Material(
          color: Colors.transparent,
          child: _HadithShareCard(
            hadith: widget.hadith,
            formattedNumber: widget.formattedNumber,
            appName: widget.appName,
          ),
        ),
      ),
    );
  }
}

class _HadithShareCard extends StatelessWidget {
  final Hadith hadith;
  final String formattedNumber;
  final String appName;

  const _HadithShareCard({
    required this.hadith,
    required this.formattedNumber,
    required this.appName,
  });

  static const double _w = 380;
  static const _ink = Color(0xFF14201A);
  static const _paper = Color(0xFFF7F4EC);
  static const _primary = Color(0xFF0F3D26);
  static const _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final arabic = hadith.hadithArabic.trim();
    final urdu = hadith.hadithUrdu.trim();
    final english = hadith.hadithEng.trim();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _w, maxWidth: _w),
      child: Container(
        color: _paper,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top ribbon ──
            Row(
              children: [
                Container(width: 20, height: 2, color: _gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hadith.reference.isNotEmpty
                        ? hadith.reference
                        : 'HADITH $formattedNumber',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: _primary,
                    ),
                  ),
                ),
                if (hadith.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      hadith.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _paper,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Arabic ──
            if (arabic.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  arabic,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 19,
                    height: 2.0,
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            // ── Divider ──
            if (arabic.isNotEmpty && urdu.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _gold.withValues(alpha: 0),
                              _gold.withValues(alpha: 0.55),
                              _gold.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Transform.rotate(
                        angle: 0.785,
                        child: Container(width: 6, height: 6, color: _gold),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _gold.withValues(alpha: 0),
                              _gold.withValues(alpha: 0.55),
                              _gold.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Urdu ──
            if (urdu.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  urdu,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 14,
                    height: 2.3,
                    color: _ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // ── Divider ──
            if (urdu.isNotEmpty && english.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: _ink.withValues(alpha: 0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Transform.rotate(
                        angle: 0.785,
                        child: Container(
                          width: 4,
                          height: 4,
                          color: _gold.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: _ink.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),

            // ── English ──
            if (english.isNotEmpty)
              Text(
                english,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.7,
                  color: const Color(0xFF2A2A2A),
                ),
              ),

            const SizedBox(height: 22),

            // ── Footer ──
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gold.withValues(alpha: 0.0),
                    _gold.withValues(alpha: 0.4),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 14,
                    color: _gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Authentic Hadith Collection',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: _ink.withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '#$formattedNumber',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
