import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/BukhariModels.dart';

Future<void> shareHadithAsCard(
    BuildContext context,
    Hadith hadith, {
      required String formattedNumber,
      String appName = 'Fiqah',
    }) async {
  // ═══════════════════════════════════════════════════════════
  // STEP 1 — Preload ALL Google Fonts the card will use.
  // This is the critical fix. Without this, Nastaliq renders
  // as blank/boxes because the font hasn't been fetched yet.
  // ═══════════════════════════════════════════════════════════
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoNastaliqUrdu(),
    GoogleFonts.amiri(),
    GoogleFonts.inter(),
  ]);

  final overlay = Overlay.of(context);
  final completer = Completer<Uint8List?>();

  final entry = OverlayEntry(
    builder: (_) => _OffscreenRenderer(
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

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/hadith_${formattedNumber}_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png')],
    text: 'Hadith $formattedNumber — shared from $appName',
  );
}

// ─────────────────────────────────────────────────────────────
class _OffscreenRenderer extends StatefulWidget {
  final Hadith hadith;
  final String formattedNumber;
  final String appName;
  final ValueChanged<Uint8List?> onDone;

  const _OffscreenRenderer({
    required this.hadith,
    required this.formattedNumber,
    required this.appName,
    required this.onDone,
  });

  @override
  State<_OffscreenRenderer> createState() => _OffscreenRendererState();
}

class _OffscreenRendererState extends State<_OffscreenRenderer> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    try {
      // Wait two full frames — one to lay out, one to paint glyphs
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) {
        widget.onDone(null);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      widget.onDone(byteData?.buffer.asUint8List());
    } catch (e) {
      debugPrint('Share card capture failed: $e');
      widget.onDone(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -2000,
      top: -2000,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: Material(
          color: Colors.transparent,
          child: HadithShareCard(
            hadith: widget.hadith,
            formattedNumber: widget.formattedNumber,
            appName: widget.appName,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// The card
// ─────────────────────────────────────────────────────────────
class HadithShareCard extends StatelessWidget {
  final Hadith hadith;
  final String formattedNumber;
  final String appName;

  const HadithShareCard({
    super.key,
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
        child: Stack(
          children: [
            Positioned(top: -50, right: -50, child: _ornament()),
            Positioned(
              bottom: -50,
              left: -50,
              child: Transform.rotate(angle: math.pi, child: _ornament()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topRibbon(),
                  const SizedBox(height: 22),

                  // ── Arabic ──
                  if (arabic.isNotEmpty)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        arabic,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: 19,
                          height: 2.0,
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  // ── Divider ──
                  if (arabic.isNotEmpty && urdu.isNotEmpty)
                    _ornamentDivider(),

                  // ── Urdu (always shown if present) ──
                  if (urdu.isNotEmpty)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        urdu,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.notoNastaliqUrdu(
                          fontSize: 14,
                          height: 2.3, // Nastaliq needs tall lines
                          color: _ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // ── Divider ──
                  if (urdu.isNotEmpty && english.isNotEmpty)
                    _ornamentDivider(),

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

                  const SizedBox(height: 24),
                  _footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topRibbon() {
    return Row(
      children: [
        Container(width: 20, height: 2, color: _gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hadith.reference.isNotEmpty
                ? hadith.reference
                : 'HADITH $formattedNumber',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _primary,
              letterSpacing: 1.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hadith.category.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
      ],
    );
  }

  Widget _ornamentDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _gold.withValues(alpha: 0),
                  _gold.withValues(alpha: 0.55),
                  _gold.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _gold.withValues(alpha: 0),
                  _gold.withValues(alpha: 0.55),
                  _gold.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _gold.withValues(alpha: 0.0),
              _gold.withValues(alpha: 0.4),
              _gold.withValues(alpha: 0.0),
            ]),
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
              child:
              SvgPicture.asset('assets/image/fiqha_logo.svg', color: _gold, fit: BoxFit.contain),
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
    );
  }

  Widget _ornament() {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _OrnamentPainter(color: _gold.withValues(alpha: 0.06)),
      ),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  final Color color;
  _OrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final center = Offset(size.width, 0);
    for (double r = 20; r <= 120; r += 14) {
      canvas.drawCircle(center, r, paint);
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 4 + (math.pi / 2) * (i / 6);
      final dx = center.dx - (size.width * 0.9) * math.cos(angle);
      final dy = center.dy + (size.height * 0.9) * math.sin(angle);
      canvas.drawLine(center, Offset(dx, dy), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter old) => old.color != color;
}