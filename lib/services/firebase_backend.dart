import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';

class FirebaseBackend {
  FirebaseBackend._();

  static final FirebaseBackend instance = FirebaseBackend._();

  bool isAvailable = false;
  String? initializationError;

  AppUser? cachedCurrentUserProfile;
  Future<AppUser?>? _profileRequest;
  String? _profileRequestUid;
  final Map<String, bool> _legacyAdminCache = {};

  void _clearUserCache() {
    cachedCurrentUserProfile = null;
    _profileRequest = null;
    _profileRequestUid = null;
    _legacyAdminCache.clear();
  }

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  static String userFriendlyAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'अमान्य Email पता दर्ज किया गया है (Invalid email)।';
        case 'user-disabled':
          return 'यह खाता निष्क्रिय कर दिया गया है। व्यवस्थापक से संपर्क करें।';
        case 'user-not-found':
          return 'इस Email से कोई खाता नहीं मिला। कृपया सही Email डालें या नया खाता बनाएं।';
        case 'wrong-password':
          return 'गलत Password दर्ज किया गया है। कृपया पुनः प्रयास करें।';
        case 'invalid-credential':
          return 'Email अथवा Password गलत है। कृपया पुनः जाँच कर प्रयास करें।';
        case 'email-already-in-use':
          return 'यह Email पहले से पंजीकृत है। कृपया लॉगिन करें या दूसरा Email उपयोग करें।';
        case 'weak-password':
          return 'Password बहुत कमजोर है। कम से कम 6 अक्षरों का उपयोग करें।';
        case 'network-request-failed':
          return 'इंटरनेट कनेक्शन में समस्या है। कृपया नेटवर्क जांचें।';
        case 'too-many-requests':
          return 'बहुत अधिक असफल प्रयास। कृपया कुछ क्षण प्रतीक्षा करें।';
        case 'operation-not-allowed':
          return 'Firebase में Email/Password लॉगिन सक्षम नहीं है।';
        case 'requires-recent-login':
          return 'सत्र पुराना हो चुका है। कृपया दोबारा लॉगिन करें।';
        default:
          return error.message ??
              'प्रमाणीकरण विफल (Authentication failed)। कृपया पुनः प्रयास करें।';
      }
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'इस कार्य के लिए आवश्यक अधिकार (Permission) नहीं हैं।';
      }
      if (error.code == 'unavailable') {
        return 'Firebase सर्वर अनुपलब्ध है। कृपया इंटरनेट जांचें।';
      }
      final message = error.message;
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return 'Firebase configuration error. कृपया सेटिंग्स जांचें।';
    }

    if (error is SocketException) {
      return 'इंटरनेट कनेक्शन में समस्या है। कृपया नेटवर्क जांचें।';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Firebase configuration error. कृपया सेटिंग्स जांचें।';
  }

  Future<void> initialize() async {
    try {
      debugPrint('FirebaseBackend: initializing Firebase');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool('sqlite_cache_sanitized_v1') ?? false)) {
          await FirebaseFirestore.instance.clearPersistence();
          await prefs.setBool('sqlite_cache_sanitized_v1', true);
          debugPrint(
            'FirebaseBackend: Cleared legacy SQLite persistence cache to prevent CursorWindow overflow.',
          );
        }
      } catch (e) {
        debugPrint('FirebaseBackend: clearPersistence skipped/ignorable: $e');
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

  /// Always reads from Firestore and refreshes the session cache.
  Future<AppUser?> fetchUserProfile(String uid) async {
    final profile = await _readUserProfile(uid);
    if (profile != null && uid == auth.currentUser?.uid) {
      cachedCurrentUserProfile = profile;
    }
    return profile;
  }

  Future<AppUser?> _readUserProfile(String uid) async {
    if (!isAvailable) return null;
    try {
      // 1. Fetch user document from users/{uid}
      DocumentSnapshot<Map<String, dynamic>>? userDoc;
      try {
        userDoc = await firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        try {
          userDoc = await firestore
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.cache))
              .timeout(const Duration(seconds: 1));
        } catch (_) {
          userDoc = null;
        }
      }

      // If user document exists, evaluate it directly without redundant queries
      if (userDoc != null && userDoc.exists && userDoc.data() != null) {
        final profile = AppUser.fromFirestore(userDoc);
        if (profile.role == UserRole.admin) {
          _legacyAdminCache[uid] = true;
          return profile.copyWith(
            role: UserRole.admin,
            permissions: AppPermission.all,
          );
        }
        final isLegacyAdmin =
            _legacyAdminCache[uid] ?? await _checkLegacyAdmin(uid);
        if (isLegacyAdmin) {
          return profile.copyWith(
            role: UserRole.admin,
            permissions: AppPermission.all,
          );
        }
        return profile;
      }

      // 2. Fallback for admin document if not present in users collection
      final isLegacyAdmin =
          _legacyAdminCache[uid] ?? await _checkLegacyAdmin(uid);
      if (isLegacyAdmin) {
        return AppUser(
          uid: uid,
          email: auth.currentUser?.email ?? '',
          name: auth.currentUser?.displayName ?? 'Admin',
          role: UserRole.admin,
          permissions: AppPermission.all,
        );
      }
    } catch (e) {
      debugPrint('FirebaseBackend.fetchUserProfile error for uid=$uid: $e');
    }
    return null;
  }

  /// Returns the cached profile for this session; reads Firestore only once.
  Future<AppUser?> getCurrentUserProfile({bool forceRefresh = false}) async {
    if (!isAvailable) return null;
    final user = auth.currentUser;
    if (user == null) {
      _clearUserCache();
      return null;
    }

    final cached = cachedCurrentUserProfile;
    if (!forceRefresh && cached != null && cached.uid == user.uid) {
      return cached;
    }

    final pending = _profileRequest;
    if (!forceRefresh && pending != null && _profileRequestUid == user.uid) {
      return pending;
    }

    final request = fetchUserProfile(user.uid);
    _profileRequest = request;
    _profileRequestUid = user.uid;
    try {
      return await request;
    } finally {
      if (identical(_profileRequest, request)) {
        _profileRequest = null;
        _profileRequestUid = null;
      }
    }
  }

  Future<void> saveUserProfile(AppUser profile) async {
    if (!isAvailable) return;
    try {
      await firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));
      if (profile.uid == auth.currentUser?.uid) {
        cachedCurrentUserProfile = profile;
      }
    } catch (e) {
      debugPrint('FirebaseBackend.saveUserProfile error: $e');
      rethrow;
    }
  }

  Future<UserRole> getCurrentUserRole() async {
    final user = auth.currentUser;
    if (user == null || !isAvailable) return UserRole.viewer;

    final isLegacyAdmin =
        _legacyAdminCache[user.uid] ?? await _checkLegacyAdmin(user.uid);
    if (isLegacyAdmin) return UserRole.admin;

    final profile = await getCurrentUserProfile();
    if (profile != null) {
      return profile.role;
    }

    return UserRole.viewer;
  }

  Future<bool> _checkLegacyAdmin(String uid) async {
    final cached = _legacyAdminCache[uid];
    if (cached != null) return cached;
    try {
      DocumentSnapshot<Map<String, dynamic>>? adminDoc;
      try {
        adminDoc = await firestore
            .collection('admins')
            .doc(uid)
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(seconds: 1));
      } catch (_) {
        adminDoc = null;
      }
      if (adminDoc == null || !adminDoc.exists) {
        try {
          adminDoc = await firestore
              .collection('admins')
              .doc(uid)
              .get()
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          adminDoc = null;
        }
      }
      final isAdmin =
          adminDoc != null &&
          adminDoc.exists &&
          (adminDoc.data()?['role'] == null ||
              adminDoc.data()?['role']?.toString().trim().toLowerCase() ==
                  'admin' ||
              adminDoc.data()?['isAdmin'] == true ||
              adminDoc.data()?['admin'] == true);
      _legacyAdminCache[uid] = isAdmin;
      return isAdmin;
    } catch (_) {
      _legacyAdminCache[uid] = false;
      return false;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = auth.currentUser;
    if (user == null) {
      debugPrint('FirebaseBackend.isCurrentUserAdmin: no authenticated user');
      return false;
    }

    final isLegacy = await _checkLegacyAdmin(user.uid);
    if (isLegacy) return true;

    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  Future<bool> isCurrentUserStaff() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin || role == UserRole.staff;
  }

  Stream<AppUser?> userProfileChanges() {
    if (cachedCurrentUserProfile != null) {
      return Stream.value(cachedCurrentUserProfile);
    }
    if (!isAvailable) {
      return Stream.value(null);
    }
    return authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getCurrentUserProfile();
    });
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _clearUserCache();
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

  Future<void> signOut() {
    _clearUserCache();
    if (!isAvailable) return Future.value();
    return auth.signOut();
  }

  Stream<User?> authStateChanges() {
    if (!isAvailable) {
      return Stream.value(null);
    }
    return auth.authStateChanges();
  }

  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    final reference = storage.ref(path);
    final task = reference.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    await task.timeout(const Duration(seconds: 15));
    return reference.getDownloadURL().timeout(const Duration(seconds: 10));
  }
}
