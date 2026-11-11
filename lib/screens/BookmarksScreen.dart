import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/models/Bookmark.dart';
import 'package:quranpak/screens/SurahReaderScreen.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/BookmarkProvider.dart';
import 'package:quranpak/widgets/customIcons.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookmarkProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            tooltip: 'Sync bookmarks',
            icon: const Icon(Icons.sync),
            onPressed: () => context.read<BookmarkProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (provider.error != null && provider.items.isEmpty) {
            return _buildError(provider);
          }

          if (provider.items.isEmpty) {
            return _buildEmpty();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final bookmark = provider.items[index];
              return _AnimatedBookmarkCard(
                key: ValueKey(bookmark.id),
                bookmark: bookmark,
                index: index,
                onTap: () => _openBookmark(bookmark),
                onDelete: () => provider.remove(bookmark.id),
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────── Empty / Error ───────────────────────────

  Widget _buildEmpty() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                customIcons.Save,
                size: 56,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No bookmarks yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the bookmark icon while reading\nthe Quran to save an ayah',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BookmarkProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.primary,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookmark(Bookmark bookmark) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: bookmark.surahNumber,
          scrollToAyah: bookmark.ayahNumber,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  ANIMATED BOOKMARK CARD
// ═══════════════════════════════════════════════════════════════════════

class _AnimatedBookmarkCard extends StatefulWidget {
  final Bookmark bookmark;
  final int index;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _AnimatedBookmarkCard({
    super.key,
    required this.bookmark,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_AnimatedBookmarkCard> createState() => _AnimatedBookmarkCardState();
}

class _AnimatedBookmarkCardState extends State<_AnimatedBookmarkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _pressed = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Stagger each card slightly for a cascading entrance.
    final stagger = (widget.index.clamp(0, 8)) * 60;
    Future.delayed(Duration(milliseconds: stagger), () {
      if (mounted) _entryCtrl.forward();
    });

    _fade = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // Accent color derived from surah number — same surah always same color.
  Color get _accent {
    const palette = [
      Color(0xFF1B5E20), // forest green
      Color(0xFF8B6F2C), // gold
      Color(0xFF6D4C41), // brown
      Color(0xFF2E7D32), // deeper green
      Color(0xFF9E7B3C), // amber
      Color(0xFF4E342E), // dark brown
    ];
    return palette[widget.bookmark.surahNumber % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bookmark;
    final surahTitle = b.surahEnglishName.isNotEmpty
        ? b.surahEnglishName
        : b.surahName;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _dismissed
            ? const SizedBox.shrink()
            : Dismissible(
                key: ValueKey('dismiss_${b.id}'),
                direction: DismissDirection.endToStart,
                background: _buildDismissBackground(),
                confirmDismiss: (_) async {
                  HapticFeedback.mediumImpact();
                  // Let the dismissal animation finish, then remove.
                  return true;
                },
                onDismissed: (_) async {
                  setState(() => _dismissed = true);
                  await widget.onDelete();
                },
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTap: widget.onTap,
                  child: AnimatedScale(
                    scale: _pressed ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(
                                alpha: _pressed ? 0.18 : 0.10),
                            blurRadius: _pressed ? 16 : 10,
                            offset: Offset(0, _pressed ? 6 : 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Gradient accent bar ──
                              Container(
                                width: 5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      _accent,
                                      _accent.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),

                              // ── Main content ──
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 14, 8, 14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSurahBadge(b.surahNumber),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Title row
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    surahTitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                                _buildAyahPill(b.ayahNumber,
                                                    _accent),
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            // Arabic name (if present)
                                            if (b.surahName.isNotEmpty &&
                                                b.surahName != surahTitle)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        bottom: 6),
                                                child: Text(
                                                  b.surahName,
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: _accent
                                                        .withValues(
                                                            alpha: 0.75),
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              ),

                                            // Ayah preview
                                            if (b.ayahPreview.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(
                                                        10),
                                                decoration: BoxDecoration(
                                                  color: _accent
                                                      .withValues(
                                                          alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                ),
                                                child: Text(
                                                  b.ayahPreview,
                                                  maxLines: 2,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    height: 1.55,
                                                    color: AppTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // ── Delete button ──
                                      _buildDeleteButton(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSurahBadge(int number) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.16),
            _accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accent.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: _accent,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAyahPill(int ayahNumber, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Ayah $ayahNumber',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          HapticFeedback.mediumImpact();
          _confirmDelete();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            customIcons.delete,
            color: Colors.redAccent.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            customIcons.delete,
            color: Colors.redAccent.withValues(alpha: 0.85),
            size: 22,
          ),
          const SizedBox(width: 8),
          const Text(
            'Remove',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Remove bookmark?'),
        content: Text(
          'This will delete your bookmark for '
          'Surah ${widget.bookmark.surahEnglishName} '
          '(Ayah ${widget.bookmark.ayahNumber}).',
          style: const TextStyle(height: 1.5, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _dismissed = true);
      await widget.onDelete();
    }
  }
}