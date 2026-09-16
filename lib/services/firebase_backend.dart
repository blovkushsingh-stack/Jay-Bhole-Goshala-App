import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';

class FirebaseBackend {
  FirebaseBackend._();

  static final FirebaseBackend instance = FirebaseBackend._();

  bool isAvailable = false;
  String? initializationError;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  static String userFriendlyAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is invalid. Please enter a valid email.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact the administrator.';
        case 'user-not-found':
          return 'No account was found for that email. Please create an account first.';
        case 'wrong-password':
          return 'The password is incorrect. Please try again.';
        case 'email-already-in-use':
          return 'This email address is already in use. Please use a different email or login instead.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase Authentication.';
        case 'requires-recent-login':
          return 'Please sign in again to continue.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }

    if (error is FirebaseException) {
      final message = error.message;
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return 'Firebase configuration error. Please verify the Firebase project and Authentication settings.';
    }

    if (error is SocketException) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Firebase configuration error. Please verify the Firebase project and Authentication settings.';
  }

  Future<void> initialize() async {
    try {
      debugPrint('FirebaseBackend: initializing Firebase');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      isAvailable = true;
      initializationError = null;
      debugPrint('FirebaseBackend: Firebase initialized successfully');
    } on FirebaseException catch (error) {
      isAvailable = false;
      initializationError = error.message ?? error.code;
      debugPrint('FirebaseBackend: Firebase init failed: ${error.code}');
      rethrow;
    } catch (error) {
      isAvailable = false;
      initializationError = error.toString();
      debugPrint('FirebaseBackend: Firebase init exception: $error');
      rethrow;
    }
  }

  Future<String?> fetchUserRole(String uid) async {
    final profile = await fetchUserProfile(uid);
    return profile?.role.value;
  }

  Future<AppUser?> fetchUserProfile(String uid) async {
    if (!isAvailable) return null;
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return AppUser.fromFirestore(userDoc);
      }

      // Fallback for legacy admin document if not present in users collection
      final adminDoc = await firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        final adminData = adminDoc.data();
        final roleStr =
            adminData?['role']?.toString().trim().toLowerCase() ?? 'admin';
        return AppUser(
          uid: uid,
          email:
              adminData?['email']?.toString() ??
              (auth.currentUser?.email ?? ''),
          name: adminData?['name']?.toString() ?? 'Admin',
          role: UserRole.fromString(roleStr),
        );
      }
    } catch (e) {
      debugPrint('FirebaseBackend.fetchUserProfile error for uid=$uid: $e');
    }
    return null;
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final user = auth.currentUser;
    if (user == null) return null;
    return fetchUserProfile(user.uid);
  }

  Future<void> saveUserProfile(AppUser profile) async {
    if (!isAvailable) return;
    try {
      await firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseBackend.saveUserProfile error: $e');
      rethrow;
    }
  }

  Future<UserRole> getCurrentUserRole() async {
    final user = auth.currentUser;
    if (user == null || !isAvailable) return UserRole.viewer;

    final profile = await getCurrentUserProfile();
    if (profile != null) {
      return profile.role;
    }

    // Fallback: Check legacy admins collection
    final isLegacyAdmin = await _checkLegacyAdmin(user.uid);
    return isLegacyAdmin ? UserRole.admin : UserRole.viewer;
  }

  Future<bool> _checkLegacyAdmin(String uid) async {
    try {
      final adminDoc = await firestore.collection('admins').doc(uid).get();
      return adminDoc.exists &&
          adminDoc.data()?['role']?.toString().trim().toLowerCase() == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = auth.currentUser;
    if (user == null) {
      debugPrint('FirebaseBackend.isCurrentUserAdmin: no authenticated user');
      return false;
    }

    final role = await getCurrentUserRole();
    if (role == UserRole.admin) return true;

    // Direct check on admins collection for absolute backward compatibility
    return _checkLegacyAdmin(user.uid);
  }

  Future<bool> isCurrentUserStaff() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin || role == UserRole.staff;
  }

  Stream<AppUser?> userProfileChanges() {
    return authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getCurrentUserProfile();
    });
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => auth.signOut();

  Stream<User?> authStateChanges() => auth.authStateChanges();

  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    final reference = storage.ref(path);
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }
}
