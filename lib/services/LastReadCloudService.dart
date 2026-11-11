import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/LastReadProgress.dart';

class LastReadCloudService {
  static final LastReadCloudService _instance = LastReadCloudService._();

  factory LastReadCloudService() => _instance;

  LastReadCloudService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _document(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('last-read')
          .doc('current');

  Future<LastReadProgress?> fetch(String userId) async {
    final snapshot = await _document(userId).get();
    if (!snapshot.exists) return null;
    return LastReadProgress.fromFirestore(snapshot.data()!);
  }

  Future<void> save(String userId, LastReadProgress progress) async {
    await _document(userId).set(
      progress.toFirestore(),
      SetOptions(merge: true),
    );
  }
}
