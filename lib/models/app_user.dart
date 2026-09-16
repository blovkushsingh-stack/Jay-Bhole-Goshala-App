import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin('admin', 'Admin (व्यवस्थापक)'),
  staff('staff', 'Staff (कर्मचारी / सेवक)'),
  viewer('viewer', 'Viewer (दर्शक / श्रद्धालु)');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  bool get isAdmin => this == UserRole.admin;
  bool get isStaff => this == UserRole.staff;
  bool get isViewer => this == UserRole.viewer;

  static UserRole fromString(dynamic value) {
    final str = value?.toString().trim().toLowerCase() ?? '';
    return switch (str) {
      'admin' => UserRole.admin,
      'staff' => UserRole.staff,
      'viewer' => UserRole.viewer,
      _ => UserRole.viewer,
    };
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
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
  final String phoneNumber;
  final String goshalaId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role.isAdmin;
  bool get isStaff => role.isStaff;
  bool get isViewer => role.isViewer;
  bool get canEditRecords => (isAdmin || isStaff) && isActive;
  bool get canManageUsers => isAdmin && isActive;

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
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
    return AppUser(
      uid: uid ?? _stringValue(json['uid']),
      email: _stringValue(json['email']),
      name: _stringValue(json['name']).isNotEmpty
          ? _stringValue(json['name'])
          : _stringValue(json['displayName']),
      role: UserRole.fromString(json['role']),
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
