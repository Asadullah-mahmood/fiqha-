import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Bookmark.dart';

class BookmarkCloudService {
  static final BookmarkCloudService _i = BookmarkCloudService._();
  factory BookmarkCloudService() => _i;
  BookmarkCloudService._();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _fs.collection('bookmarks').doc(uid).collection('data');

  CollectionReference<Map<String, dynamic>> _legacyCol(String uid) =>
      _fs.collection('users').doc(uid).collection('bookmarks');

  Future<void> upsert(Bookmark b) async {
    await _col(b.userId).doc(b.id).set(
      b.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<void> delete(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }

  Future<List<Bookmark>> fetchAll(String uid) async {
    final snap = await _col(uid)
        .orderBy('createdAt', descending: true)
        .get();
    final bookmarks = <String, Bookmark>{
      for (final doc in snap.docs)
        doc.id: Bookmark.fromFirestore({...doc.data(), 'id': doc.id}),
    };

    try {
      final legacy = await _legacyCol(uid).get();
      for (final doc in legacy.docs) {
        if (bookmarks.containsKey(doc.id)) continue;
        final bookmark =
            Bookmark.fromFirestore({...doc.data(), 'id': doc.id});
        await upsert(bookmark);
        bookmarks[bookmark.id] = bookmark;
      }
    } catch (error, stackTrace) {
      debugPrint('Could not import bookmarks from the previous Firestore '
          'location: $error\n$stackTrace');
    }

    return bookmarks.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}