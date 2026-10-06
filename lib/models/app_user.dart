import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin('admin', 'Admin (व्यवस्थापक)'),
  staff('staff', 'Staff (कर्मचारी / सेवक)'),
  user('viewer', 'User (दर्शक / श्रद्धालु)');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  bool get isAdmin => this == UserRole.admin;
  bool get isStaff => this == UserRole.staff;
  bool get isUser => this == UserRole.user;
  bool get isViewer => isUser;

  static const UserRole viewer = UserRole.user;

  static UserRole fromString(dynamic value) {
    final str = value?.toString().trim().toLowerCase() ?? '';
    return switch (str) {
      'admin' => UserRole.admin,
      'staff' => UserRole.staff,
      'user' || 'viewer' => UserRole.user,
      _ => UserRole.user,
    };
  }
}

class AppPermission {
  static const String cows = 'cows';
  static const String feed = 'feed';
  static const String finance = 'finance';
  static const String donations = 'donations';
  static const String health = 'health';
  static const String volunteers = 'volunteers';
  static const String staff = 'staff';
  static const String settings = 'settings';

  static const List<String> all = [
    cows,
    feed,
    finance,
    donations,
    health,
    volunteers,
    staff,
    settings,
  ];

  static const Map<String, String> labels = {
    cows: 'गौवंश देखभाल (Cows)',
    feed: 'चारा एवं स्टॉक (Feed Stock)',
    finance: 'आय-व्यय (Finance)',
    donations: 'दान प्रबंधन (Donations)',
    health: 'चिकित्सा रिकॉर्ड (Health)',
    volunteers: 'सेवक/श्रमदान (Volunteers)',
    staff: 'कर्मचारी प्रबंधन (Staff)',
    settings: 'सेटिंग्स (Settings)',
  };
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.permissions = const <String>[],
    this.phoneNumber = '',
    this.goshalaId = 'jay-bhole-goshala',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final List<String> permissions;
  final String phoneNumber;
  final String goshalaId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role.isAdmin && isActive;
  bool get isStaff => role.isStaff && isActive;
  bool get isUser => role.isUser;
  bool get isViewer => isUser;

  /// Check if user has permission for a specific module
  bool hasPermission(String permission) {
    if (!isActive) return false;
    if (isAdmin) return true;
    if (!isStaff) return false;
    return permissions.contains(permission);
  }

  /// Can user edit general records (Admin or Staff with edit access)
  bool get canEditRecords => (isAdmin || isStaff) && isActive;

  bool get canManageUsers => isAdmin;

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    List<String>? permissions,
    String? phoneNumber,
    String? goshalaId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      goshalaId: goshalaId ?? this.goshalaId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'role': role.value,
    'permissions': permissions,
    'phoneNumber': phoneNumber,
    'goshalaId': goshalaId,
    'isActive': isActive,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toFirestore() => toJson();

  factory AppUser.fromJson(Map<String, dynamic> json, {String? uid}) {
    final rawPermissions = json['permissions'];
    final perms = <String>[];
    if (rawPermissions is List) {
      for (final p in rawPermissions) {
        if (p != null) {
          perms.add(p.toString().trim());
        }
      }
    }

    final dynamic rawRole =
        json['role'] ?? json['userRole'] ?? json['userType'] ?? json['type'];
    final bool isAdminFlag = json['isAdmin'] == true || json['admin'] == true;
    final UserRole role = isAdminFlag
        ? UserRole.admin
        : UserRole.fromString(rawRole);
    final effectivePermissions = role == UserRole.admin && perms.isEmpty
        ? AppPermission.all
        : perms;

    return AppUser(
      uid: uid ?? _stringValue(json['uid']),
      email: _stringValue(json['email']),
      name: _stringValue(json['name']).isNotEmpty
          ? _stringValue(json['name'])
          : _stringValue(json['displayName']),
      role: role,
      permissions: effectivePermissions,
      phoneNumber: _stringValue(json['phoneNumber']).isNotEmpty
          ? _stringValue(json['phoneNumber'])
          : _stringValue(json['phone']),
      goshalaId: _stringValue(json['goshalaId']).isNotEmpty
          ? _stringValue(json['goshalaId'])
          : 'jay-bhole-goshala',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser.fromJson(data, uid: doc.id);
  }

  static String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
