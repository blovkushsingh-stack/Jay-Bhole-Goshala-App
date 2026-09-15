import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/cow_record.dart';
import 'firebase_backend.dart';

class GoshalaCloudRepository {
  GoshalaCloudRepository({FirebaseBackend? backend})
    : _backend = backend ?? FirebaseBackend.instance;

  final FirebaseBackend _backend;

  bool get canSync => _backend.isAvailable && _backend.auth.currentUser != null;

  Future<void> saveRecord({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (!canSync) return;

    final user = _backend.auth.currentUser;
    final docPath = '$collection/$id';
    debugPrint(
      'GoshalaCloudRepository.saveRecord: userUid=${user?.uid}, email=${user?.email}, path=$docPath',
    );

    try {
      await _backend.firestore.collection(collection).doc(id).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user!.uid,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint(
        'GoshalaCloudRepository.saveRecord: Firestore error for $docPath: code=${e.code}, message=${e.message}',
      );
      rethrow;
    }
  }

  Future<void> deleteRecord({
    required String collection,
    required String id,
  }) async {
    if (!canSync) return;
    await _backend.firestore.collection(collection).doc(id).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection(
    String collection,
  ) {
    if (!canSync) return const Stream.empty();
    return _backend.firestore.collection(collection).snapshots();
  }

  Future<List<CowRecord>> fetchCows() async {
    if (!canSync) return const <CowRecord>[];
    final snapshot = await _backend.firestore
        .collection('cows')
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CowRecord.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Stream<List<CowRecord>> watchCows() {
    if (!canSync) return const Stream.empty();
    return _backend.firestore
        .collection('cows')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CowRecord.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Future<void> saveCow({
    required String id,
    required Map<String, dynamic> data,
  }) => saveRecord(collection: 'cows', id: id, data: data);

  Future<void> deleteCow(String id) => deleteRecord(collection: 'cows', id: id);
}
