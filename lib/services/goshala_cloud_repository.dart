import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/cow_record.dart';
import '../models/feed_item.dart';
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

  // -------------------------------------------------------------
  // Feed Stock & Inventory Methods
  // -------------------------------------------------------------

  Future<List<FeedItem>> fetchFeedStock() async {
    if (!canSync) return const <FeedItem>[];
    final snapshot = await _backend.firestore
        .collection('feedStock')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => FeedItem.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Stream<List<FeedItem>> watchFeedStock() {
    if (!canSync) return const Stream.empty();
    return _backend.firestore
        .collection('feedStock')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedItem.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Future<void> saveFeedItem(FeedItem item) =>
      saveRecord(collection: 'feedStock', id: item.id, data: item.toJson());

  Future<void> deleteFeedItem(String id) =>
      deleteRecord(collection: 'feedStock', id: id);

  // -------------------------------------------------------------
  // Feed Transactions (Consumption, Purchase, Donation)
  // -------------------------------------------------------------

  Future<List<FeedTransaction>> fetchFeedTransactions({int limit = 50}) async {
    if (!canSync) return const <FeedTransaction>[];
    final snapshot = await _backend.firestore
        .collection('feedTransactions')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => FeedTransaction.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Stream<List<FeedTransaction>> watchFeedTransactions({int limit = 50}) {
    if (!canSync) return const Stream.empty();
    return _backend.firestore
        .collection('feedTransactions')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedTransaction.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Future<void> logFeedTransaction(
    FeedTransaction tx, {
    required double updatedStock,
  }) async {
    if (!canSync) return;
    await saveRecord(
      collection: 'feedTransactions',
      id: tx.id,
      data: tx.toJson(),
    );
    // Update the parent feed stock quantity
    await _backend.firestore.collection('feedStock').doc(tx.feedItemId).set({
      'currentStock': updatedStock,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastRestockedDate': tx.isPurchase || tx.isDonation
          ? FieldValue.serverTimestamp()
          : null,
    }, SetOptions(merge: true));
  }
}
