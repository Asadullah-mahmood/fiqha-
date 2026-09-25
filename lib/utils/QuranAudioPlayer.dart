import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../services/AudioServices.dart';

class Reciter {
  final String id;
  final String name;
  final String arabicName;
  final String baseUrl;
  final String imageAsset;

  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.baseUrl,
    required this.imageAsset,
  });

  String ayahUrl(int surah, int ayah) {
    String s = surah.toString().padLeft(3, '0');
    String a = ayah.toString().padLeft(3, '0');
    return '$baseUrl$s$a.mp3';
  }
}

enum SurahDownloadState { idle, downloading, ready, playing, error }

class QuranAudioPlayer extends ChangeNotifier {
  // ── TWO players: one plays the current ayah while the other has the NEXT
  //    ayah already loaded. When the current ayah ends we just call resume()
  //    on the ready player, so there is no load/stop/play gap. ──
  final List<AudioPlayer> _players = [AudioPlayer(), AudioPlayer()];
  int _activeIdx = 0;
  AudioPlayer get _active => _players[_activeIdx];
  AudioPlayer get _standby => _players[1 - _activeIdx];

  final AudioDownloadService _downloader = AudioDownloadService();

  // Which playlist index is (being) loaded in the standby player
  int? _standbyIdx;
  Future<bool>? _standbyLoad;

  // ── State streams (exposed for mini-player) ──
  final StreamController<Duration> _positionCtrl =
  StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationCtrl =
  StreamController<Duration?>.broadcast();

  Stream<Duration> get positionStream => _positionCtrl.stream;
  Stream<Duration?> get durationStream => _durationCtrl.stream;

  Duration _position = Duration.zero;
  Duration? _duration;
  Duration get position => _position;


  // ── Subscriptions ──
  final List<StreamSubscription<dynamic>> _subs = [];

  static const List<Reciter> reciters = [
    Reciter(
      id: 'alafasy',
      name: 'Mishary Alafasy',
      arabicName: 'مشاري العفاسي',
      baseUrl: 'https://everyayah.com/data/Alafasy_128kbps/',
      imageAsset:
      'https://i.scdn.co/image/ab6761610000e5ebac381d07bb60d7bfd3be1fe0',
    ),
    Reciter(
      id: 'abdulbasit',
      name: 'Abdul Basit (Murattal)',
      arabicName: 'عبد الباسط',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRTHTDKqW2kyNGnF0fS_TBQM-o6JpK_1wqbJ0gYNf1nXg&s=10',
      baseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/',
    ),
    Reciter(
      id: 'sudais',
      name: 'Abdurrahman As-Sudais',
      arabicName: 'عبدالرحمن السديس',
      baseUrl: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTF0X-RQPnP6IuRq7K1kVbWN_1O5lDreVPHZrvZ9_r5Zg&s=10',
    ),
    Reciter(
      id: 'shuraim',
      name: 'Saud Ash-Shuraim',
      arabicName: 'سعود الشريم',
      baseUrl: 'https://everyayah.com/data/Saud_Al-Shuraim_192kbps/',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQso56EZhqzvNqdJw5_NB6tOacRHLXLAfLyO3lgsBv5mA&s=10',
    ),
    Reciter(
      id: 'ghamdi',
      name: 'Saad Al-Ghamdi',
      arabicName: 'سعد الغامدي',
      baseUrl: 'https://everyayah.com/data/Ghamadi_40kbps/',
      imageAsset: '',
    ),
    Reciter(
      id: 'minshawi',
      name: 'Al-Minshawi',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ78ExZjkfdOq7k87l4YvbYsZxfMGtR8OcrBRv__z74j0MRA_IlAYcYAjVq&s=10',
      arabicName: 'المنشاوي',
      baseUrl: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/',
    ),
    // ── Extra verified reciters ──
    Reciter(
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTABHOHVHBgVatFqGvS-1EN0q-swJMgMwfTZ5Y3D5CvHA&s=10',
      id: 'husary',
      name: 'Mahmoud Khalil Al-Husary',
      arabicName: 'محمود خليل الحصري',
      baseUrl: 'https://everyayah.com/data/Husary_128kbps/',
    ),
    Reciter(
      id: 'shaatree',
      name: 'Abu Bakr Ash-Shaatree',
      arabicName: 'أبو بكر الشاطري',
      baseUrl: 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/',
      imageAsset:
      'https://quran.com/_next/image?url=https%3A%2F%2Fstatic.qurancdn.com%2Fimages%2Freciters%2F3%2Fabu-bakr-al-shatri-pofile.jpeg%3Fv%3D1&w=256&q=75',
    ),
    Reciter(
      id: 'ajamy',
      name: 'Ahmed ibn Ali al-Ajamy',
      arabicName: 'أحمد بن علي العجمي',
      baseUrl: 'https://everyayah.com/data/ahmed_ibn_ali_al_ajamy_128kbps/',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTbPNu7gS843umNubyFl__FA97g-s-Vb5EmPIIdQPkdpg&s=10',
    ),
    Reciter(
      id: 'huzaify',
      name: 'Ali Al-Huzaify',
      arabicName: 'علي الحذيفي',
      baseUrl: 'https://everyayah.com/data/Ali_Al_Huzaify_128kbps/',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRH7kkWJvm_uJrP4j60-n4uREl0X_gqVTkCQrf-vqAHtA&s=10',
    ),
    Reciter(
      id: 'qatami',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT53JgEKpyDen0hKkObd2z43UetFb-N53meWpYkrw4FlEWs3VQPbXfeMmM&s=10',
      name: 'Nasser Al-Qatami',
      arabicName: 'ناصر القطامي',
      baseUrl: 'https://everyayah.com/data/Nasser_Alqatami_128kbps/',
    ),
    Reciter(
      id: 'yasser',
      name: 'Yasser Ad-Dussary',
      arabicName: 'ياسر الدوسري',
      baseUrl: 'https://everyayah.com/data/Yasser_Ad-Dussary_128kbps/',
      imageAsset:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQKyv4R9y3MZlbecOm1mSeNpd_kM9iFDsn0iiuor_X0Qg&s',
    ),
  ];

  Reciter _selectedReciter = reciters.first;
  Reciter get selectedReciter => _selectedReciter;

  // ── Current playing state ──
  int? _currentSurah;
  int? _currentAyah;
  String? _currentSurahName;
  bool _isPlaying = false;

  int? get currentSurah => _currentSurah;
  int? get currentAyah => _currentAyah;
  String? get currentSurahName => _currentSurahName;
  bool get isPlaying => _isPlaying;

  // ── Full-surah download state ──
  SurahDownloadState _downloadState = SurahDownloadState.idle;
  int _downloadedCount = 0;
  int _totalAyahsToDownload = 0;
  int? _downloadingSurahNumber;
  String? _lastError;
  bool _durationTrusted = false;
  Timer? _durationTimer;
  Duration? get duration =>
      _durationTrusted ? _duration : null;    // ← return null until trusted

  bool _cancelRequested = false;

  SurahDownloadState get downloadState => _downloadState;
  int get downloadedCount => _downloadedCount;
  int get totalAyahsToDownload => _totalAyahsToDownload;
  int? get downloadingSurahNumber => _downloadingSurahNumber;
  String? get lastError => _lastError;
  double get overallProgress =>
      _totalAyahsToDownload == 0 ? 0 : _downloadedCount / _totalAyahsToDownload;

  // ── Playlist state (parallel lists: ayah numbers + resolved file paths) ──
  List<int> _playlist = [];
  List<String> _paths = [];
  int _playlistIndex = 0;

  QuranAudioPlayer() {
    _wireListeners();
  }

  void _wireListeners() {
    for (int k = 0; k < _players.length; k++) {
      final p = _players[k];

      // Only the ACTIVE player is allowed to drive the UI state.
      _subs.add(p.onPositionChanged.listen((pos) {
        if (k != _activeIdx) return;
        _position = pos;
        _positionCtrl.add(pos);
        // Do NOT notifyListeners here — too frequent, stutters the UI
      }));

      _subs.add(p.onDurationChanged.listen((d) {if (k != _activeIdx) return;
      _duration = d;
      _durationCtrl.add(d);

      // ✅ Ignore tiny durations (metadata glitch); try again after 2s of playback
      if (d.inSeconds > 5) {
        _durationTrusted = true;
        notifyListeners();
      } else {
        _durationTrusted = false;
        _durationTimer?.cancel();

        // Add 'async' to the Timer callback here
        _durationTimer = Timer(const Duration(seconds: 2), () async {
          if (k != _activeIdx) return;

          // FIX: Change 'p.duration' to 'await p.getDuration()'
          final real = await p.getDuration();
          if (real != null && real.inSeconds > 5) {
            _duration = real;
            _durationTrusted = true;
            _durationCtrl.add(real);
            notifyListeners();
          }
        });
      }
      }));


      _subs.add(p.onPlayerComplete.listen((_) {
        if (k != _activeIdx) return;
        _onAyahComplete();
      }));

      _subs.add(p.onPlayerStateChanged.listen((s) {
        if (k != _activeIdx) return;
        // "completed" is deliberately ignored: while moving to the next ayah
        // the state must stay "playing" so the UI does not flicker.
        if (s == PlayerState.playing) {
          if (!_isPlaying) {
            _isPlaying = true;
            notifyListeners();
          }
        } else if (s == PlayerState.paused || s == PlayerState.stopped) {
          if (_isPlaying) {
            _isPlaying = false;
            notifyListeners();
          }
        }
      }));
    }
  }



  void setReciter(Reciter reciter) {
    _selectedReciter = reciter;
    notifyListeners();
  }

  // ── Helpers for the UI ──
  bool isPlayingSurah(int surahNumber) =>
      _currentSurah == surahNumber &&
          _downloadState == SurahDownloadState.playing &&
          _isPlaying;

  bool isPausedSurah(int surahNumber) =>
      _currentSurah == surahNumber &&
          _downloadState == SurahDownloadState.playing &&
          !_isPlaying;

  bool isDownloadingSurah(int surahNumber) =>
      _downloadingSurahNumber == surahNumber &&
          _downloadState == SurahDownloadState.downloading;

  /// True if EVERY ayah of the surah is cached for the SELECTED reciter.
  Future<bool> isSurahFullyCached({
    required int surahNumber,
    required int totalAyahs,
    String? reciterId,
  }) async {
    final recId = reciterId ?? _selectedReciter.id;
    for (int i = 1; i <= totalAyahs; i++) {
      final ok = await _downloader.isDownloaded(
        reciterId: recId,
        surahNumber: surahNumber,
        ayahNumber: i,
      );
      if (!ok) return false;
    }
    return true;
  }

  /// Play an already-cached surah WITHOUT re-downloading (instant).
  Future<void> playCachedSurah({
    required int surahNumber,
    required int totalAyahs,
    String? surahName,
  }) async {
    _cancelRequested = false;
    _lastError = null;
    await _startPlaylist(
      surahNumber: surahNumber,
      totalAyahs: totalAyahs,
      surahName: surahName,
      verify: true,
    );
  }

  /// Pause if this surah is currently playing.
  Future<void> pauseIfPlaying(int surahNumber) async {
    if (_currentSurah == surahNumber && _isPlaying) {
      await pause();
    }
  }

  /// Resume if this surah is currently paused.
  Future<void> resumeIfPaused(int surahNumber) async {
    if (_currentSurah == surahNumber && !_isPlaying) {
      await resume();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CHECK CACHED AYAHS
  // ─────────────────────────────────────────────────────────────
  Future<int> countCachedAyahs({
    required int surahNumber,
    required int totalAyahs,
  }) async {
    int cached = 0;
    for (int i = 1; i <= totalAyahs; i++) {
      final ok = await _downloader.isDownloaded(
        reciterId: _selectedReciter.id,
        surahNumber: surahNumber,
        ayahNumber: i,
      );
      if (ok) cached++;
    }
    return cached;
  }

  // ─────────────────────────────────────────────────────────────
  // MAIN: Download whole surah then play
  // ─────────────────────────────────────────────────────────────
  Future<void> downloadAndPlaySurah({
    required int surahNumber,
    required int totalAyahs,
    String? surahName,
  }) async {
    try {
      _cancelRequested = false;
      _lastError = null;
      _downloadingSurahNumber = surahNumber;
      _currentSurahName = surahName;
      _downloadedCount = 0;
      _totalAyahsToDownload = totalAyahs;
      _downloadState = SurahDownloadState.downloading;
      notifyListeners();

      // ── STEP 1: Download every ayah that isn't already on disk ──
      for (int i = 1; i <= totalAyahs; i++) {
        if (_cancelRequested) {
          _downloadState = SurahDownloadState.idle;
          _downloadedCount = 0;
          _totalAyahsToDownload = 0;
          _downloadingSurahNumber = null;
          notifyListeners();
          return;
        }

        final already = await _downloader.isDownloaded(
          reciterId: _selectedReciter.id,
          surahNumber: surahNumber,
          ayahNumber: i,
        );
        if (!already) {
          final url = _selectedReciter.ayahUrl(surahNumber, i);
          await _downloader.downloadAyahAudio(
            url: url,
            reciterId: _selectedReciter.id,
            surahNumber: surahNumber,
            ayahNumber: i,
          );
        }
        _downloadedCount = i;
        notifyListeners();
      }

      // ── STEP 2: HARD VERIFY every file exists before playing ──
      final missing = <int>[];
      for (int i = 1; i <= totalAyahs; i++) {
        final ok = await _downloader.isDownloaded(
          reciterId: _selectedReciter.id,
          surahNumber: surahNumber,
          ayahNumber: i,
        );
        if (!ok) missing.add(i);
      }

      if (missing.isNotEmpty) {
        // Retry missing ayahs once
        for (final i in missing) {
          if (_cancelRequested) return;
          final url = _selectedReciter.ayahUrl(surahNumber, i);
          await _downloader.downloadAyahAudio(
            url: url,
            reciterId: _selectedReciter.id,
            surahNumber: surahNumber,
            ayahNumber: i,
          );
        }
        final stillMissing = <int>[];
        for (final i in missing) {
          final ok = await _downloader.isDownloaded(
            reciterId: _selectedReciter.id,
            surahNumber: surahNumber,
            ayahNumber: i,
          );
          if (!ok) stillMissing.add(i);
        }
        if (stillMissing.isNotEmpty) {
          throw Exception(
            'Failed to download ayahs: ${stillMissing.join(", ")}',
          );
        }
      }

      _downloadState = SurahDownloadState.ready;
      notifyListeners();

      // ── STEP 3: Play (everything verified, so skip re-checking) ──
      await _startPlaylist(
        surahNumber: surahNumber,
        totalAyahs: totalAyahs,
        surahName: surahName,
        verify: false,
      );
    } catch (e) {
      _lastError = e.toString();
      _downloadState = SurahDownloadState.error;
      notifyListeners();
      debugPrint('Surah download error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PLAYBACK
  // ─────────────────────────────────────────────────────────────

  /// Resolve all file paths once, then start at [startAyah].
  Future<void> _startPlaylist({
    required int surahNumber,
    required int totalAyahs,
    String? surahName,
    int startAyah = 1,
    bool verify = true,
  }) async {
    try {
      final reciter = _selectedReciter;
      final ayahs = <int>[];
      final paths = <String>[];

      for (int i = 1; i <= totalAyahs; i++) {
        if (verify) {
          final ok = await _downloader.isDownloaded(
            reciterId: reciter.id,
            surahNumber: surahNumber,
            ayahNumber: i,
          );
          if (!ok) {
            try {
              await _downloader.downloadAyahAudio(
                url: reciter.ayahUrl(surahNumber, i),
                reciterId: reciter.id,
                surahNumber: surahNumber,
                ayahNumber: i,
              );
            } catch (e) {
              debugPrint('❌ Skipping ayah $i (download failed): $e');
              continue;
            }
          }
        }
        paths.add(await _downloader.resolvePath(
          reciterId: reciter.id,
          surahNumber: surahNumber,
          ayahNumber: i,
        ));
        ayahs.add(i);
      }

      if (ayahs.isEmpty) {
        throw Exception('No audio available for surah $surahNumber');
      }

      // Reset both players and the preload state
      _standbyIdx = null;
      _standbyLoad = null;
      await Future.wait(_players.map((p) => p.stop()));
      await Future.wait(_players.map((p) => p.setReleaseMode(ReleaseMode.stop)));
      _activeIdx = 0;

      int startIdx = ayahs.indexOf(startAyah);
      if (startIdx < 0) startIdx = 0;

      _currentSurah = surahNumber;
      _currentSurahName = surahName;
      _playlist = ayahs;
      _paths = paths;

      await _playIndexDirect(startIdx);
    } catch (e) {
      _lastError = e.toString();
      _downloadState = SurahDownloadState.error;
      notifyListeners();
      debugPrint('Playback start error: $e');
      rethrow;
    }
  }

  /// Load + play [idx] on the active player (used for start / previous / jump).
  Future<void> _playIndexDirect(int idx) async {
    if (idx < 0 || idx >= _playlist.length) return;

    _playlistIndex = idx;
    _currentAyah = _playlist[idx];
    _position = Duration.zero;
    _downloadState = SurahDownloadState.playing;
    notifyListeners();

    try {
      await _active.play(DeviceFileSource(_paths[idx]));
    } catch (e) {
      debugPrint('❌ Play failed for ayah ${_playlist[idx]}: $e');
      // Skip ahead instead of dying
      if (idx + 1 < _playlist.length) {
        await _playIndexDirect(idx + 1);
      }
      return;
    }
    _preloadNext();
  }

  /// Load the NEXT ayah into the standby player while the current one plays.
  void _preloadNext() {
    final next = _playlistIndex + 1;
    if (next >= _playlist.length) {
      _standbyIdx = null;
      _standbyLoad = null;
      return;
    }
    if (_standbyIdx == next) return; // already loaded / loading

    final target = _standby;
    final prev = _standbyLoad;
    _standbyIdx = next;
    _standbyLoad = () async {
      if (prev != null) {
        try {
          await prev;
        } catch (_) {}
      }
      if (_standbyIdx != next) return false; // superseded
      try {
        await target.setSource(DeviceFileSource(_paths[next]));
        return true;
      } catch (e) {
        debugPrint('❌ Preload failed for index $next: $e');
        return false;
      }
    }();
  }

  /// Go to [idx]. Uses the preloaded standby player when possible (no gap).
  Future<void> _advanceTo(int idx) async {
    if (idx < 0 || idx >= _playlist.length) return;

    if (_standbyIdx == idx && _standbyLoad != null) {
      final ok = await _standbyLoad!;
      if (ok && _standbyIdx == idx) {
        final old = _active;
        _activeIdx = 1 - _activeIdx;
        _playlistIndex = idx;
        _currentAyah = _playlist[idx];
        _position = Duration.zero;
        _downloadState = SurahDownloadState.playing;
        _standbyIdx = null;
        _standbyLoad = null;

        // ✅ Try resume first (fast path), fall back to play() if needed
        try {
          await _active.resume();
        } catch (_) {
          await _active.play(DeviceFileSource(_paths[idx]));
        }

        notifyListeners();
        unawaited(old.stop());
        _preloadNext();
        return;
      }
    }
    await _playIndexDirect(idx);
  }

  Future<void> _onAyahComplete() async {
    if (_playlist.isEmpty) return;
    final nextIdx = _playlistIndex + 1;
    if (nextIdx >= _playlist.length) {
      // Whole surah finished
      _isPlaying = false;
      _downloadState = SurahDownloadState.ready;
      notifyListeners();
      return;
    }
    await _advanceTo(nextIdx);
  }

  // Add inside QuranAudioPlayer class:

  /// Play a surah that's already fully downloaded — no network, instant.
  Future<void> playDownloadedSurah({
    required int surahNumber,
    required int totalAyahs,
    String? surahName,
    String? reciterId,
  }) async {
    _cancelRequested = false;
    _lastError = null;

    // Switch reciter if specified
    if (reciterId != null && reciterId != _selectedReciter.id) {
      final rec = reciters.firstWhere(
            (r) => r.id == reciterId,
        orElse: () => _selectedReciter,
      );
      _selectedReciter = rec;
    }

    // ✅ Actually start the playlist
    await _startPlaylist(
      surahNumber: surahNumber,
      totalAyahs: totalAyahs,
      surahName: surahName,
      verify: true, // re-check each file exists, download missing ones
    );
  }

  Future<void> playAyahInCurrentSurah(int ayahNumber) async {
    final idx = _playlist.indexOf(ayahNumber);
    if (idx == -1) return;
    if (idx == _playlistIndex + 1) {
      await _advanceTo(idx);
    } else {
      await _playIndexDirect(idx);
    }
  }

  Future<void> next() async => _advanceTo(_playlistIndex + 1);

  Future<void> previous() async {
    if (_playlistIndex - 1 >= 0) {
      await _playIndexDirect(_playlistIndex - 1);
    }
  }

  Future<void> pause() async => _active.pause();
  Future<void> resume() async => _active.resume();
  Future<void> seek(Duration position) async => _active.seek(position);

  Future<void> stop() async {
    _standbyIdx = null;
    _standbyLoad = null;
    await Future.wait(_players.map((p) => p.stop()));
    _isPlaying = false;
    _currentAyah = null;
    _currentSurahName = null;
    _downloadState = SurahDownloadState.idle;
    notifyListeners();
  }

  Future<void> cancelDownload() async {
    _cancelRequested = true;
    _downloadState = SurahDownloadState.idle;
    _downloadedCount = 0;
    _totalAyahsToDownload = 0;
    _downloadingSurahNumber = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _positionCtrl.close();
    _durationTimer!.cancel();
    _durationCtrl.close();
    for (final p in _players) {
      p.dispose();
    }
    super.dispose();
  }
}