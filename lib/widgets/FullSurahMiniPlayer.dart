import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/FullSurahReciter.dart';
import '../screens/FullAudioPlayerScreen.dart';
import '../services/FullSurahDownloadProvider.dart';
import '../utils/AppTheme.dart';
import '../utils/FullSurahPlayer.dart';

class FullSurahMiniPlayer extends StatefulWidget {
  const FullSurahMiniPlayer({super.key});

  @override
  State<FullSurahMiniPlayer> createState() => _FullSurahMiniPlayerState();

  static Future<void> _nextSurah(
    BuildContext context,
    FullSurahDownloadProvider dl,
    FullSurahPlayer player,
  ) async {
    final cur = player.currentSurah;
    final rec = player.currentReciterId;
    if (cur == null || rec == null || cur >= 114) return;
    await _play(context, cur + 1, rec, player, dl);
  }

  static Future<void> _prevSurah(
    BuildContext context,
    FullSurahDownloadProvider dl,
    FullSurahPlayer player,
  ) async {
    final cur = player.currentSurah;
    final rec = player.currentReciterId;
    if (cur == null || rec == null || cur <= 1) return;
    await _play(context, cur - 1, rec, player, dl);
  }

  static Future<void> _play(
    BuildContext context,
    int surahNumber,
    String reciterId,
    FullSurahPlayer player,
    FullSurahDownloadProvider dl,
  ) async {
    final rec = fullSurahReciters.firstWhere(
      (r) => r.id == reciterId,
      orElse: () => fullSurahReciters.first,
    );

    final isDownloaded = await dl.isSurahDownloaded(
      surahNumber,
      reciterId: reciterId,
    );

    if (isDownloaded) {
      await player.playDownloaded(
        surahNumber: surahNumber,
        reciterId: reciterId,
        surahName: null,
      );
    } else {
      await player.playStreaming(
        surahNumber: surahNumber,
        url: rec.urlBuilder(surahNumber),
        reciterId: reciterId,
        surahName: null,
      );
      dl.downloadSurah(surahNumber, reciterId: reciterId);
    }
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _FullSurahMiniPlayerState extends State<FullSurahMiniPlayer> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<FullSurahPlayer, FullSurahDownloadProvider>(
      builder: (context, player, dl, _) {
        // Hide when nothing has ever played
        if (player.currentSurah == null || _dismissed)
          return const SizedBox.shrink();

        final surahNum = player.currentSurah!;
        final surahName = player.currentSurahName ?? 'Surah $surahNum';
        final reciter = fullSurahReciters.firstWhere(
          (r) => r.id == player.currentReciterId,
          orElse: () => fullSurahReciters.first,
        );

        final dur = player.duration;
        final hasDur = dur.inMilliseconds > 0;

        return SafeArea(
          child: Dismissible(
            key: ValueKey('mini_$surahNum'),
            direction: DismissDirection.down,
            onDismissed: (_) => player.stop(),
            confirmDismiss: (direction) async {
              await player.stop();
              return true;
            },
            background: Container(
              color: AppTheme.primaryDark,
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
            child: Material(
              elevation: 12,
              color: AppTheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FullAudioPlayerScreen(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Drag handle ──
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // ── Row: avatar | names | prev | play | next | close ──
                      Row(
                        children: [
                          ClipOval(
                            child: Image.network(
                              reciter.imageAsset,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 38,
                                height: 38,
                                color: Colors.white12,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  surahName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  reciter.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSansArabic(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _MiniIconButton(
                            icon: Icons.skip_previous_rounded,
                            size: 24,
                            onTap: () => FullSurahMiniPlayer._prevSurah(
                              context,
                              dl,
                              player,
                            ),
                          ),
                          _MiniIconButton(
                            icon: player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 30,
                            onTap: () async {
                              if (player.isPlaying) {
                                await player.pause();
                              } else {
                                await player.resume();
                              }
                            },
                          ),
                          _MiniIconButton(
                            icon: Icons.skip_next_rounded,
                            size: 24,
                            onTap: () => FullSurahMiniPlayer._nextSurah(
                              context,
                              dl,
                              player,
                            ),
                          ),
                          _MiniIconButton(
                            icon: Icons.close_rounded,
                            size: 20,
                            onTap: () => player.stop(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // ── Progress row (StreamBuilder → ticks every second) ──
                      StreamBuilder<Duration>(
                        stream: player.positionStream,
                        initialData: player.position,
                        builder: (context, snap) {
                          final pos = snap.data ?? Duration.zero;
                          final progress = hasDur
                              ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 0.0;

                          return Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  FullSurahMiniPlayer._fmt(pos),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  textScaler: TextScaler.linear(1),
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 10,
                                    ),
                                    activeTrackColor: AppTheme.gold,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppTheme.gold,
                                    overlayColor: AppTheme.gold.withOpacity(
                                      0.2,
                                    ),
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
                              ),
                              SizedBox(
                                width: 34,
                                child: Text(
                                  hasDur
                                      ? FullSurahMiniPlayer._fmt(dur)
                                      : '--:--',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9.5,
                                  ),
                                  textScaler: TextScaler.linear(1),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      radius: 24,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
