import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/cow_record.dart';
import '../models/feed_item.dart';
import 'firebase_backend.dart';

class GoshalaCloudRepository {
  GoshalaCloudRepository({FirebaseBackend? backend})
    : _backend = backend ?? FirebaseBackend.instance;

  final FirebaseBackend _backend;

  bool get isAvailable => _backend.isAvailable;
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
    if (!_backend.isAvailable) return const <CowRecord>[];
    try {
      final snapshot = await _backend.firestore.collection('cows').get();
      final cows = snapshot.docs
          .map((doc) => CowRecord.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      cows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return cows;
    } catch (e) {
      debugPrint('GoshalaCloudRepository.fetchCows error: $e');
      return const <CowRecord>[];
    }
  }

  Future<CowRecord?> fetchCowById(String id) async {
    if (!_backend.isAvailable) return null;
    try {
      final doc = await _backend.firestore.collection('cows').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return CowRecord.fromJson({...doc.data()!, 'id': doc.id});
      }
    } catch (e) {
      debugPrint('GoshalaCloudRepository.fetchCowById error: $e');
    }
    return null;
  }

  Stream<List<CowRecord>> watchCows() {
    if (!_backend.isAvailable) return const Stream.empty();
    return _backend.firestore
        .collection('cows')
        .snapshots()
        .map((snapshot) {
          final cows = snapshot.docs
              .map((doc) => CowRecord.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          cows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return cows;
        });
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

  // -------------------------------------------------------------
  // Income & Expense / Ledger Methods
  // -------------------------------------------------------------

  Future<void> saveLedgerEntry({
    required String id,
    required Map<String, dynamic> data,
    required bool isIncome,
  }) async {
    final collection = isIncome ? 'donations' : 'expenses';
    await saveRecord(collection: collection, id: id, data: data);
  }

  Future<void> deleteLedgerEntry({
    required String id,
    required bool isIncome,
  }) async {
    final collection = isIncome ? 'donations' : 'expenses';
    await deleteRecord(collection: collection, id: id);
  }

  // -------------------------------------------------------------
  // Donation Operations
  // -------------------------------------------------------------

  Future<void> saveDonation({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (!_backend.isAvailable) return;
    final user = _backend.auth.currentUser;
    await _backend.firestore.collection('donations').doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user?.uid ?? 'guest-donor',
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> fetchDonations() async {
    if (!_backend.isAvailable) return const <Map<String, dynamic>>[];
    try {
      final snapshot = await _backend.firestore
          .collection('donations')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('GoshalaCloudRepository.fetchDonations error: $e');
      return const <Map<String, dynamic>>[];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDonations() {
    if (!_backend.isAvailable) return const Stream.empty();
    return _backend.firestore
        .collection('donations')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> deleteDonation(String id) async {
    if (!_backend.isAvailable) return;
    await _backend.firestore.collection('donations').doc(id).delete();
  }

  // -------------------------------------------------------------
  // Product Operations
  // -------------------------------------------------------------

  Future<void> saveProduct({
    required String id,
    required Map<String, dynamic> data,
  }) => saveRecord(collection: 'products', id: id, data: data);

  Future<void> deleteProduct(String id) =>
      deleteRecord(collection: 'products', id: id);

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    if (!canSync) return const <Map<String, dynamic>>[];
    try {
      final snapshot = await _backend.firestore
          .collection('products')
          .get();
      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('GoshalaCloudRepository.fetchProducts error: $e');
      return const <Map<String, dynamic>>[];
    }
  }

  Future<String> uploadProductPhoto({
    required String productId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'products/${productId}_$timestamp.jpg';
    return _backend.uploadFile(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Uploads a cow photo to Firebase Storage and returns its download URL.
  Future<String> uploadCowPhoto({
    required String cowId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final cleanId = cowId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'cows/${cleanId}_$timestamp.jpg';
    return _backend.uploadFile(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Migrates legacy Firestore cow documents containing large Base64 photoData
  /// to Firebase Storage, then removes the bloated photoData field to prevent
  /// SQLiteBlobTooBigException: Row too big to fit into CursorWindow.
  Future<int> migrateLegacyCowPhotos() async {
    if (!canSync) return 0;
    int migratedCount = 0;
    try {
      final snapshot = await _backend.firestore.collection('cows').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawData = data['photoData'];
        final existingUrl = data['photoUrl'] as String?;

        if (rawData == null) continue;

        // Case 1: photoData already contains an HTTP/HTTPS URL
        if (rawData is String &&
            (rawData.startsWith('http://') || rawData.startsWith('https://'))) {
          await doc.reference.update({
            if (existingUrl == null || existingUrl.isEmpty) 'photoUrl': rawData,
            'photoData': FieldValue.delete(),
          });
          migratedCount++;
          continue;
        }

        // Case 2: photoData contains a Base64 string
        if (rawData is String && rawData.trim().isNotEmpty) {
          // If a photoUrl already exists, simply delete the redundant Base64 payload
          if (existingUrl != null && existingUrl.isNotEmpty) {
            await doc.reference.update({
              'photoData': FieldValue.delete(),
            });
            migratedCount++;
            continue;
          }

          // Otherwise, attempt to upload the Base64 bytes to Firebase Storage
          try {
            final cleanBase64 = rawData
                .replaceFirst(RegExp(r'^data:image\/[a-zA-Z0-9]+;base64,'), '')
                .replaceAll(RegExp(r'\s+'), '');
            final bytes = base64Decode(cleanBase64);
            final downloadUrl = await uploadCowPhoto(
              cowId: doc.id,
              bytes: bytes,
            );
            await doc.reference.update({
              'photoUrl': downloadUrl,
              'photoData': FieldValue.delete(),
            });
            migratedCount++;
          } catch (e) {
            debugPrint('Failed to migrate Base64 photo for cow ${doc.id}: $e');
            // Remove bloated field even if upload fails to guarantee Android CursorWindow safety
            await doc.reference.update({
              'photoData': FieldValue.delete(),
            });
            migratedCount++;
          }
        } else {
          // Empty or non-string photoData, safely remove
          await doc.reference.update({
            'photoData': FieldValue.delete(),
          });
          migratedCount++;
        }
      }
    } catch (e) {
      debugPrint('GoshalaCloudRepository.migrateLegacyCowPhotos error: $e');
    }
    return migratedCount;
  }
}
