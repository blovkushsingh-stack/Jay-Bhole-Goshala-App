import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffAttendanceStatus {
  present('Present'),
  absent('Absent'),
  leave('Leave');

  const StaffAttendanceStatus(this.label);

  final String label;

  String get value => name;
}

class StaffAttendanceEntry {
  StaffAttendanceEntry({required this.date, required this.status});

  final DateTime date;
  final StaffAttendanceStatus status;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'status': status.value,
  };

  static StaffAttendanceEntry fromJson(Map<String, dynamic> json) {
    final date = _dateValue(json['date']);
    final statusValue = _stringValue(json['status']);
    final status = switch (statusValue) {
      'present' => StaffAttendanceStatus.present,
      'leave' => StaffAttendanceStatus.leave,
      _ => StaffAttendanceStatus.absent,
    };

    return StaffAttendanceEntry(date: date, status: status);
  }

  static DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _stringValue(dynamic value) => value?.toString() ?? '';
}

class StaffMember {
  StaffMember({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.address,
    required this.role,
    required this.joiningDate,
    required this.assignedDuties,
    required this.isActive,
    String? profilePhotoData,
    String? salary,
    List<StaffAttendanceEntry>? attendance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : profilePhotoData = profilePhotoData ?? '',
       salary = salary ?? '',
       attendance = attendance ?? const <StaffAttendanceEntry>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String fullName;
  final String mobileNumber;
  final String address;
  final String role;
  final DateTime joiningDate;
  final String assignedDuties;
  final bool isActive;
  final String profilePhotoData;
  final String salary;
  final List<StaffAttendanceEntry> attendance;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayRole => role.trim().isEmpty ? 'Staff' : role.trim();

  String get profileInitials {
    final names = fullName.trim().split(RegExp(r'\s+'));
    if (names.isEmpty) return 'S';
    final initials = names.take(2).map((word) => word[0].toUpperCase()).join();
    return initials.isEmpty ? 'S' : initials;
  }

  bool get hasProfilePhoto => profilePhotoData.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'mobileNumber': mobileNumber,
    'address': address,
    'role': role,
    'joiningDate': joiningDate.toIso8601String(),
    'assignedDuties': assignedDuties,
    'isActive': isActive,
    'profilePhotoData': profilePhotoData,
    'salary': salary,
    'attendance': attendance.map((entry) => entry.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final attendanceList = (json['attendance'] as List<dynamic>? ?? const [])
        .map(
          (entry) =>
              StaffAttendanceEntry.fromJson(entry as Map<String, dynamic>),
        )
        .toList();

    final dateValue = _dateValue(json['joiningDate']);

    return StaffMember(
      id: _stringValue(json['id']),
      fullName: _stringValue(json['fullName']),
      mobileNumber: _stringValue(json['mobileNumber']),
      address: _stringValue(json['address']),
      role: _stringValue(json['role']),
      joiningDate: dateValue,
      assignedDuties: _stringValue(json['assignedDuties']),
      isActive: json['isActive'] == true,
      profilePhotoData: _stringValue(json['profilePhotoData']),
      salary: _stringValue(json['salary']),
      attendance: attendanceList,
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
    );
  }

  StaffMember copyWith({
    String? id,
    String? fullName,
    String? mobileNumber,
    String? address,
    String? role,
    DateTime? joiningDate,
    String? assignedDuties,
    bool? isActive,
    String? profilePhotoData,
    String? salary,
    List<StaffAttendanceEntry>? attendance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      role: role ?? this.role,
      joiningDate: joiningDate ?? this.joiningDate,
      assignedDuties: assignedDuties ?? this.assignedDuties,
      isActive: isActive ?? this.isActive,
      profilePhotoData: profilePhotoData ?? this.profilePhotoData,
      salary: salary ?? this.salary,
      attendance: attendance ?? this.attendance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _stringValue(dynamic value) => value?.toString() ?? '';

  static DateTime _dateValue(dynamic value, {DateTime? fallback}) {
    final base = fallback ?? DateTime.now();
    if (value == null) return base;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return base;
      }
    }
    return base;
  }
}

String base64ImageFromBytes(List<int> bytes) => base64Encode(bytes);
