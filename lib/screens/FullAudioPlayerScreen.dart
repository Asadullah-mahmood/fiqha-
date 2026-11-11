import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../models/FullSurahReciter.dart';
import '../services/FullSurahDownloadProvider.dart';
import '../utils/AppTheme.dart';
import '../utils/FullSurahPlayer.dart';

class FullAudioPlayerScreen extends StatelessWidget {
  const FullAudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primary,
        title: const Text(
          'Now Playing',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Consumer2<FullSurahPlayer, FullSurahDownloadProvider>(
        builder: (context, player, dl, _) {
          if (player.currentSurah == null) {
            return const Center(
              child: Text(
                'Nothing is playing',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final surahNum = player.currentSurah!;
          final surahName = player.currentSurahName ?? 'Surah $surahNum';
          final reciter = fullSurahReciters.firstWhere(
            (r) => r.id == player.currentReciterId,
            orElse: () => fullSurahReciters.first,
          );

          // ← wrap in StreamBuilder so the seek bar ticks
          return SafeArea(
            child: StreamBuilder<Duration>(
              stream: player.positionStream,
              initialData: player.position,
              builder: (context, snap) {
                final pos = snap.data ?? Duration.zero;
                final dur = player.duration;
                final hasDur = dur.inMilliseconds > 0;
                final progress = hasDur
                    ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;

                final dlProgress = dl.progress[surahNum];
                final isDownloading =
                    dlProgress?.status == SurahDlStatus.downloading;
                final downloadPct = dlProgress?.progress ?? 0.0;

                return Column(
                  children: [
                    // ── Scrollable middle section ──
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),

                            // Artwork
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                reciter.imageAsset,
                                width: 220,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 220,
                                  height: 220,
                                  color: AppTheme.surfaceContainer,
                                  child: const Icon(
                                    Icons.person,
                                    size: 90,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Surah + reciter
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    surahName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    reciter.name,
                                    style: GoogleFonts.notoSansArabic(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Seek bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 16,
                                          ),
                                      activeTrackColor: AppTheme.primary,
                                      inactiveTrackColor: Colors.black12,
                                      thumbColor: AppTheme.primary,
                                      overlayColor: AppTheme.primary
                                          .withOpacity(0.15),
                                    ),
                                    child: Slider(
                                      value: progress,
                                      onChanged: hasDur
                                          ? (v) => player.seek(
                                              Duration(
                                                milliseconds:
                                                    (v * dur.inMilliseconds)
                                                        .round(),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _fmt(pos),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          hasDur ? _fmt(dur) : '--:--',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _BigControl(
                                  icon: Icons.skip_previous_rounded,
                                  size: 42,
                                  onTap: () => _changeSurah(context, -1),
                                ),
                                const SizedBox(width: 12),
                                _BigControl(
                                  icon: Icons.replay_10_rounded,
                                  size: 34,
                                  onTap: () {
                                    final p =
                                        player.position -
                                        const Duration(seconds: 10);
                                    player.seek(
                                      p < Duration.zero ? Duration.zero : p,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () async {
                                    if (player.isPlaying) {
                                      await player.pause();
                                    } else {
                                      await player.resume();
                                    }
                                  },
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      player.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _BigControl(
                                  icon: Icons.forward_10_rounded,
                                  size: 34,
                                  onTap: () {
                                    final p =
                                        player.position +
                                        const Duration(seconds: 10);
                                    player.seek(p > dur && hasDur ? dur : p);
                                  },
                                ),
                                const SizedBox(width: 12),
                                _BigControl(
                                  icon: Icons.skip_next_rounded,
                                  size: 42,
                                  onTap: () => _changeSurah(context, 1),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // ── Pinned bottom buttons ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.record_voice_over_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Change Reciter',
                                textScaler: TextScaler.linear(1),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: BorderSide(
                                  color: AppTheme.primary.withOpacity(0.4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              onPressed: () =>
                                  _changeReciter(context, surahNum),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: isDownloading
                                ? OutlinedButton.icon(
                                    icon: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        value: downloadPct,
                                        strokeWidth: 2,
                                        color: AppTheme.gold,
                                      ),
                                    ),
                                    label: Text(
                                      '${(downloadPct * 100).round()}%',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.gold,
                                      side: BorderSide(
                                        color: AppTheme.gold.withOpacity(0.6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    onPressed: null,
                                  )
                                : FutureBuilder<bool>(
                                    future: dl.isSurahDownloaded(
                                      surahNum,
                                      reciterId: reciter.id,
                                    ),
                                    builder: (context, snap) {
                                      final isDownloaded = snap.data ?? false;
                                      return OutlinedButton.icon(
                                        icon: Icon(
                                          isDownloaded
                                              ? Icons.offline_pin
                                              : Icons.download_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isDownloaded ? 'Offline' : 'Download',
                                          textScaler: TextScaler.linear(1),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDownloaded
                                              ? Colors.green.shade700
                                              : AppTheme.gold,
                                          side: BorderSide(
                                            color:
                                                (isDownloaded
                                                        ? Colors.green.shade400
                                                        : AppTheme.gold)
                                                    .withOpacity(0.6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                        ),
                                        onPressed: isDownloaded
                                            ? null
                                            : () => _download(
                                                context,
                                                surahNum,
                                                reciter.id,
                                              ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  // ── Prev / next surah (downloaded only) ──
  static Future<void> _changeSurah(BuildContext context, int delta) async {
    final player = context.read<FullSurahPlayer>();
    final dl = context.read<FullSurahDownloadProvider>();
    final rec = player.currentReciterId;
    final cur = player.currentSurah;
    if (rec == null || cur == null) return;

    final downloaded = await dl.listDownloaded(reciterId: rec);
    if (downloaded.isEmpty) {
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          title: const Text('No offline surahs yet'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
      return;
    }

    int idx = downloaded.indexOf(cur);
    if (idx == -1) idx = 0;
    final nextIdx = (idx + delta).clamp(0, downloaded.length - 1);
    if (nextIdx == idx) return;

    await player.playDownloaded(
      surahNumber: downloaded[nextIdx],
      reciterId: rec,
      surahName: null,
    );
  }

  // ── Change reciter (re-picks and reloads current surah) ──
  static Future<void> _changeReciter(BuildContext context, int surahNum) async {
    final player = context.read<FullSurahPlayer>();
    final dl = context.read<FullSurahDownloadProvider>();

    final chosen = await showModalBottomSheet<FullSurahReciter>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ReciterPickerSheet(
        surahNumber: surahNum,
        currentReciterId: dl.selectedReciterId,
      ),
    );

    if (chosen == null || !context.mounted) return;

    // Remember as default
    await dl.setDefaultReciter(chosen.id);

    // Restart current surah with new reciter
    final isDownloaded = await dl.isSurahDownloaded(
      surahNum,
      reciterId: chosen.id,
    );
    final currentName = player.currentSurahName;

    if (isDownloaded) {
      await player.playDownloaded(
        surahNumber: surahNum,
        reciterId: chosen.id,
        surahName: currentName,
      );
    } else {
      await player.playStreaming(
        surahNumber: surahNum,
        url: chosen.urlBuilder(surahNum),
        reciterId: chosen.id,
        surahName: currentName,
      );
      dl.downloadSurah(surahNum, reciterId: chosen.id);
    }
  }

  static Future<void> _download(
    BuildContext context,
    int surahNum,
    String reciterId,
  ) async {
    final dl = context.read<FullSurahDownloadProvider>();
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: Text('Downloading surah $surahNum…'),
      autoCloseDuration: const Duration(seconds: 2),
    );
    await dl.downloadSurah(surahNum, reciterId: reciterId);
  }
}

// ── Small helper widgets ──
class _BigControl extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _BigControl({required this.icon, required this.onTap, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      radius: 40,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: size, color: AppTheme.primary),
      ),
    );
  }
}

// ── Reusable reciter picker sheet ──
class _ReciterPickerSheet extends StatelessWidget {
  final int surahNumber;
  final String currentReciterId;

  const _ReciterPickerSheet({
    required this.surahNumber,
    required this.currentReciterId,
  });

  @override
  Widget build(BuildContext context) {
    final dl = context.read<FullSurahDownloadProvider>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose a Qari (reciter)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                itemCount: fullSurahReciters.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 76),
                itemBuilder: (context, i) {
                  final rec = fullSurahReciters[i];
                  final isCurrent = currentReciterId == rec.id;

                  return ListTile(
                    leading: ClipOval(
                      child: Image.network(
                        rec.imageAsset,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 46,
                          height: 46,
                          color: AppTheme.surfaceContainer,
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      rec.name,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      rec.arabicName,
                      style: GoogleFonts.notoSansArabic(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, rec),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
