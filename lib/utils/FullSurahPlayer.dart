import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/FullSurahReciter.dart';
import '../services/FullSurahAudioService.dart';

class FullSurahPlayer extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final FullSurahAudioService _svc = FullSurahAudioService();

  int? _currentSurah;
  String? _currentSurahName;
  String? currentReciterId;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _durationTrusted = false;

  int? get currentSurah => _currentSurah;
  String? get currentSurahName => _currentSurahName;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _durationTrusted ? _duration : Duration.zero;
  bool get hasSurah => _currentSurah != null;

  final StreamController<Duration> _posCtrl =
  StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durCtrl =
  StreamController<Duration?>.broadcast();
  Stream<Duration> get positionStream => _posCtrl.stream;
  Stream<Duration?> get durationStream => _durCtrl.stream;

  final List<StreamSubscription<dynamic>> _subs = [];

  FullSurahPlayer() {
    _wire();
  }

  void _wire() {
    _subs.add(_player.onPositionChanged.listen((p) {
      _position = p;
      _posCtrl.add(p);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      _duration = d;
      _durationTrusted = d.inSeconds > 5;
      _durCtrl.add(_durationTrusted ? d : null);
      notifyListeners();
    }));
    // _subs.add(_player.onPlayerComplete.listen((_) async {
    //   _isPlaying = false;
    //   _position = Duration.zero;
    //   notifyListeners();
    //
    //   // Auto-advance to next downloaded surah (optional)
    //   await _autoAdvance();
    // }));

    // In FullSurahPlayer constructor:
    _player.onPlayerComplete.listen((_) async {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();

      final cur = _currentSurah;
      final rec = currentReciterId;
      if (cur == null || rec == null || cur >= 114) return;

      final next = cur + 1;
      final reciter = fullSurahReciters.firstWhere(
            (r) => r.id == rec,
        orElse: () => fullSurahReciters.first,
      );

      // Check if downloaded
      final isDownloaded = await _svc.isDownloaded(
        reciterId: rec,
        surahNumber: next,
      );

      try {
        if (isDownloaded) {
          final path = await _svc.resolvePath(
            reciterId: rec,
            surahNumber: next,
          );
          _currentSurah = next;
          _currentSurahName = 'Surah $next';
          _position = Duration.zero;
          _duration = Duration.zero;
          _durationTrusted = false;
          notifyListeners();
          await _player.play(DeviceFileSource(path));
        } else {
          _currentSurah = next;
          _currentSurahName = 'Surah $next';
          _position = Duration.zero;
          _duration = Duration.zero;
          _durationTrusted = false;
          notifyListeners();
          await _player
              .play(UrlSource(reciter.urlBuilder(next)))
              .timeout(const Duration(seconds: 20));
        }
      } on TimeoutException {
        debugPrint('⚠️ Auto-advance to $next timed out, trying fallback');
        try {
          await _player.play(UrlSource(_fallbackUrlFor(rec, next, currentSurahName ?? '')))
              .timeout(const Duration(seconds: 20));
        } catch (e) {
          debugPrint('❌ Auto-advance fallback failed: $e');
        }
      } catch (e) {
        debugPrint('❌ Auto-advance failed: $e');
      }
    });

    _subs.add(_player.onPlayerStateChanged.listen((s) {
      final playing = s == PlayerState.playing;
      if (playing != _isPlaying) {
        _isPlaying = playing;
        notifyListeners();
      }
    }));
  }

  Future<void> _autoAdvance() async {
    final cur = _currentSurah;
    final rec = currentReciterId;
    if (cur == null || rec == null) return;
    if (cur >= 114) return;

    // Find the next downloaded surah > cur
    final downloaded = await _svc.listDownloadedSurahs(rec);
    final next = downloaded.firstWhere((s) => s > cur, orElse: () => -1);
    if (next == -1) return;

    await playDownloaded(
      surahNumber: next,
      reciterId: rec,
    );
  }

  /// Play an already-downloaded surah from disk.
  Future<void> playDownloaded({
    required int surahNumber,
    required String reciterId,
    String? surahName,
  }) async {
    final path = await _svc.resolvePath(
      reciterId: reciterId,
      surahNumber: surahNumber,
    );
    _currentSurah = surahNumber;
    _currentSurahName = surahName;
    currentReciterId = reciterId;
    _position = Duration.zero;
    _duration = Duration.zero;
    _durationTrusted = false;
    notifyListeners();

    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  /// Play directly from a URL (streaming) — useful before download completes.
  Future<void> playStreaming({
    required int surahNumber,
    required String url,
    required String reciterId,
    String? surahName,
  }) async {
    _currentSurah = surahNumber;
    _currentSurahName = surahName;
    currentReciterId = reciterId;
    _position = Duration.zero;
    _duration = Duration.zero;
    _durationTrusted = false;
    _isPlaying = false;
    notifyListeners();

    await _player.stop();


    try{
      await _player.play(UrlSource(url)).timeout(const Duration(seconds: 20));

    }catch(e){
      print("Primary URL Failed: $url - trying fallback");

      final rec = fullSurahReciters.firstWhere((r) => r.id == reciterId,
      orElse: ()=> fullSurahReciters.first
      );

      final fallback = _fallbackUrlFor(rec.id, surahNumber, surahName ?? '');
      try{
        await _player.play(UrlSource(fallback)).timeout(const Duration(seconds: 20));

      } catch(e2){
        print('Fallback also failed: $e2');
        _isPlaying = false;
        notifyListeners();
        rethrow;
      }
    }

    _isPlaying = true;
    notifyListeners();
 //   await _player.play(UrlSource(url));
  }

  static String _fallbackUrlFor(String reciterId, int surahNumber, String surahName) {
    const map = {
      'alafasy_full':  'afs',
      'abdulbasit_full': 'basit',
      'sudais_full':   'sds',
      'shuraim_full':  'shur',
      'minshawi_full': 'minsh',
      'husary_full':   'husr',
      'shaatree_full': 'shatri',
      'ajamy_full':    'ajm',
      'huzaify_full':  'hthfi',
      'yasser_full':   'yasser',
    };
    final folder = map[reciterId] ?? 'afs';
    return 'https://server8.mp3quran.net/$folder/${surahNumber.toString().padLeft(3, '0')}.mp3';
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.resume();
  Future<void> seek(Duration d) => _player.seek(d);

  Future<void> stop() async {
    // Synchronous state change FIRST — so the Consumer rebuilds without
    // the mini player in the very next frame.
    _currentSurah = null;
    _currentSurahName = null;
    currentReciterId = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _durationTrusted = false;
    _isPlaying = false;
    notifyListeners();

    // Then do the async audio teardown.
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('stop error: $e');
    }
  }


  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _posCtrl.close();
    _durCtrl.close();
    _player.dispose();
    super.dispose();
  }
}