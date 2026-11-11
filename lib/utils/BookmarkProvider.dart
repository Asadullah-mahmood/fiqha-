import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/Bookmark.dart';
import '../services/BookmarkCloudService.dart';
import '../services/BookmarkLocalService.dart';

class BookmarkProvider extends ChangeNotifier {
  final _local = BookmarkLocalService();
  final _cloud = BookmarkCloudService();

  List<Bookmark> _items = [];
  bool _loading = false;
  bool _syncing = false;
  String? _error;
  String? _uid;
  Timer? _syncRetryTimer;
  bool _refreshRequested = false;

  List<Bookmark> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get syncing => _syncing;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty && !_loading;

  /// Call once after Firebase Auth signs the user in.
  Future<void> bindUser(String? uid) async {
    if (_uid != uid) {
      _uid = uid;
      _items = [];
      _error = null;
      _loading = false;
      _syncRetryTimer?.cancel();
      _syncRetryTimer = null;
      notifyListeners();
    }
    if (uid == null) return;
    _syncRetryTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => _replayPending(),
    );
    await refresh();
  }

  // ═════════════════════════════════════════════════════════════
  // READ
  // ═════════════════════════════════════════════════════════════
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) {
      _items = [];
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final local = await _local.getForUser(uid);
      if (_uid != uid) return;
      _items = local;
      notifyListeners();

      // Local data is immediately visible; merge cloud data and sync offline
      // writes in the background rather than blocking the screen.
      unawaited(_replayPending());
    } catch (e) {
      if (_uid != uid) return;
      _error = e.toString();
      debugPrint('Failed to load local bookmarks for $uid: $e');
    }

    _loading = false;
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════
  // WRITE — local first, then cloud
  // ═════════════════════════════════════════════════════════════
  Future<bool> add({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    required String surahEnglishName,
    required String ayahPreview,
  }) async {
    final uid = _uid;
    if (uid == null) {
      _error = 'Sign in to save bookmarks.';
      notifyListeners();
      return false;
    }

    final bookmarkId = Bookmark.makeId(uid, surahNumber, ayahNumber);
    Bookmark? existing;
    for (final item in _items) {
      if (item.id == bookmarkId) {
        existing = item;
        break;
      }
    }
    if (existing != null) return true;

    try {
      final savedLocally = await _local.getActiveById(uid, bookmarkId);
      if (_uid != uid) return false;
      if (savedLocally != null) {
        _items = [savedLocally, ..._items];
        notifyListeners();
        return true;
      }
    } catch (error) {
      _error = 'Could not check local bookmarks: $error';
      debugPrint(_error);
      notifyListeners();
      return false;
    }

    final b = Bookmark(
      id: bookmarkId,
      userId: uid,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      surahEnglishName: surahEnglishName,
      ayahPreview: ayahPreview.length > 120
          ? '${ayahPreview.substring(0, 120)}…'
          : ayahPreview,
      createdAt: DateTime.now(),
    );

    // ── 1. Local first — instant UI update ──
    try {
      await _local.upsert(b, syncState: 1);
    } catch (error) {
      _error = 'Could not save bookmark locally: $error';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
    if (_uid != uid) return false;
    _items = [b, ..._items.where((x) => x.id != b.id)];
    _error = null;
    notifyListeners();

    // Cloud writes remain asynchronous. The local pending row is retried if
    // Firestore is currently offline.
    unawaited(_pushToCloud(b));
    return true;
  }

  Future<void> _pushToCloud(Bookmark b) async {
    try {
      await _cloud.upsert(b);
      await _local.markSynced(
        b.id,
        createdAt: b.createdAt.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Bookmark push failed (will retry): $e');
    }
  }

  Future<void> remove(String id) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _local.deleteById(id);
    } catch (error) {
      _error = 'Could not remove bookmark locally: $error';
      debugPrint(_error);
      notifyListeners();
      return;
    }
    if (_uid != uid) return;
    _items = _items.where((x) => x.id != id).toList();
    notifyListeners();

    unawaited(_replayPending());
  }

  /// Remove all bookmarks for a specific surah+ayah quickly.
  Future<void> removeByAyah(int surahNumber, int ayahNumber) async {
    final uid = _uid;
    if (uid == null) return;
    final id = Bookmark.makeId(uid, surahNumber, ayahNumber);
    await remove(id);
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    final uid = _uid;
    if (uid == null) return false;
    final id = Bookmark.makeId(uid, surahNumber, ayahNumber);
    return _items.any((b) => b.id == id);
  }

  // ═════════════════════════════════════════════════════════════
  // RETRY PENDING OFFLINE OPS
  // ═════════════════════════════════════════════════════════════
  Future<void> _replayPending() async {
    final uid = _uid;
    if (uid == null) return;
    if (_syncing) {
      _refreshRequested = true;
      return;
    }
    _syncing = true;
    _refreshRequested = false;
    notifyListeners();

    try {
      final remoteIds = <String>{};
      try {
        final remote = await _cloud
            .fetchAll(uid)
            .timeout(const Duration(seconds: 8));
        if (_uid != uid) return;
        remoteIds.addAll(remote.map((item) => item.id));

        final localItems = await _local.getForUser(uid);
        final localIds = localItems.map((item) => item.id).toSet();
        final deletedIds = (await _local.pendingDeletes(uid)).toSet();
        for (final item in remote) {
          if (_uid != uid) return;
          if (deletedIds.contains(item.id)) continue;
          if (!localIds.contains(item.id)) {
            await _local.upsert(item, syncState: 0);
            _items = [item, ..._items.where((x) => x.id != item.id)];
          } else {
            await _local.markSynced(
              item.id,
              createdAt: item.createdAt.millisecondsSinceEpoch,
            );
          }
        }
        notifyListeners();
      } catch (error) {
        debugPrint(
          'Bookmark cloud fetch failed; will sync local changes: '
          '$error',
        );
      }

      final pendingCreates = await _local.pendingUploads(uid);
      for (final bookmark in pendingCreates) {
        if (_uid != uid) return;
        try {
          if (!remoteIds.contains(bookmark.id)) {
            await _cloud.upsert(bookmark);
          }
          await _local.markSynced(
            bookmark.id,
            createdAt: bookmark.createdAt.millisecondsSinceEpoch,
          );
        } catch (error) {
          debugPrint(
            'Bookmark ${bookmark.id} sync failed (will retry): '
            '$error',
          );
        }
      }

      final pendingDeletes = await _local.pendingDeletes(uid);
      for (final id in pendingDeletes) {
        if (_uid != uid) return;
        try {
          await _cloud.delete(uid, id);
          await _local.deleteSynced(id);
        } catch (error) {
          debugPrint('Bookmark delete $id sync failed (will retry): $error');
        }
      }
    } finally {
      _syncing = false;
      notifyListeners();
      if (_refreshRequested && _uid != null) {
        unawaited(_replayPending());
      }
    }
  }

  @override
  void dispose() {
    _syncRetryTimer?.cancel();
    super.dispose();
  }
}
