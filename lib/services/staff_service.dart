import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/staff_member.dart';
import 'firebase_backend.dart';

class StaffService {
  StaffService({FirebaseBackend? backend})
    : _backend = backend ?? FirebaseBackend.instance;

  final FirebaseBackend _backend;

  CollectionReference<Map<String, dynamic>> get _staffCollection =>
      _backend.firestore.collection('staff');

  Future<bool> isCurrentUserAdmin() async {
    final user = _backend.auth.currentUser;
    if (user == null || !_backend.isAvailable) {
      debugPrint(
        'StaffService.isCurrentUserAdmin: no authenticated user or backend unavailable',
      );
      return false;
    }

    final docPath = 'admins/${user.uid}';
    debugPrint(
      'StaffService.isCurrentUserAdmin: checking admin doc at $docPath for uid=${user.uid}',
    );

    try {
      final doc = await _backend.firestore
          .collection('admins')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role']?.toString().trim().toLowerCase();
      debugPrint(
        'StaffService.isCurrentUserAdmin: docExists=${doc.exists}, role=$role, path=$docPath',
      );
      return doc.exists && role == 'admin';
    } on FirebaseException catch (e) {
      debugPrint(
        'StaffService.isCurrentUserAdmin: Firestore permission error for $docPath: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint(
        'StaffService.isCurrentUserAdmin: unexpected error for $docPath: $e',
      );
      return false;
    }
  }

  bool get canManageStaff {
    final user = _backend.auth.currentUser;
    if (user == null || !_backend.isAvailable) return false;
    return true;
  }

  Future<List<StaffMember>> fetchStaff() async {
    if (!_backend.isAvailable) return const <StaffMember>[];
    final snapshot = await _staffCollection
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => StaffMember.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Stream<List<StaffMember>> watchStaff() {
    if (!_backend.isAvailable) return const Stream.empty();
    return _staffCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffMember.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Future<void> saveStaff(StaffMember staff) async {
    if (!_backend.isAvailable) return;
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw StateError('Admin access required to manage staff records.');
    }
    final payload = staff.toJson();
    await _staffCollection.doc(staff.id).set({
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _backend.auth.currentUser?.uid ?? 'local-admin',
    }, SetOptions(merge: true));
  }

  Future<void> deleteStaff(String id) async {
    if (!_backend.isAvailable) return;
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw StateError('Admin access required to manage staff records.');
    }
    await _staffCollection.doc(id).delete();
  }

  String generateId() => '${DateTime.now().millisecondsSinceEpoch}';

  Stream<List<StaffMember>> filterByRole(String role) {
    if (!_backend.isAvailable) return const Stream.empty();
    final query = role.trim().isEmpty
        ? _staffCollection.orderBy('updatedAt', descending: true)
        : _staffCollection
              .where('role', isEqualTo: role)
              .orderBy('updatedAt', descending: true);
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => StaffMember.fromJson({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  Stream<List<StaffAttendanceEntry>> attendanceForDate(
    String staffId,
    DateTime date,
  ) {
    return _staffCollection.doc(staffId).snapshots().map((snapshot) {
      if (!snapshot.exists) return const <StaffAttendanceEntry>[];
      final data = snapshot.data() ?? {};
      final entries =
          (data['attendance'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (entry) => StaffAttendanceEntry.fromJson(
                  entry as Map<String, dynamic>,
                ),
              )
              .where((item) => _isSameDay(item.date, date))
              .toList();
      return entries;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> updateAttendance(
    String staffId,
    DateTime date,
    StaffAttendanceStatus status,
  ) async {
    final staffDoc = await _staffCollection.doc(staffId).get();
    if (!staffDoc.exists) return;

    final data = staffDoc.data() ?? {};
    final list = (data['attendance'] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => entry as Map<String, dynamic>)
        .toList();

    final existingIndex = list.indexWhere((entry) {
      final itemDate = StaffAttendanceEntry.fromJson(entry).date;
      return itemDate.year == date.year &&
          itemDate.month == date.month &&
          itemDate.day == date.day;
    });

    final newEntry = StaffAttendanceEntry(date: date, status: status).toJson();
    if (existingIndex >= 0) {
      list[existingIndex] = newEntry;
    } else {
      list.add(newEntry);
    }

    await _staffCollection.doc(staffId).update({'attendance': list});
  }
}
