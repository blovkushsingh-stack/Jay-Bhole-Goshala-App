import 'package:cloud_firestore/cloud_firestore.dart';

class CowRecord {
  CowRecord({
    required this.id,
    required this.tag,
    required this.name,
    required this.age,
    required this.breed,
    required this.gender,
    required this.arrivalDate,
    required this.health,
    required this.notes,
    String? status,
    this.color = '',
    this.sourceDetails = '',
    this.weight = '',
    this.vaccination = '',
    this.disease = '',
    this.photoData,
    this.goshalaId = 'jay-bhole-goshala',
    this.isMilking = false,
    this.pregnancyStatus = 'गैर-गर्भवती',
    this.dailyMilkYield = '',
    this.expectedCalvingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : status = status ?? health,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String tag;
  final String name;
  final int age;
  final String breed;
  final String gender;
  final DateTime arrivalDate;
  final String health;
  final String status;
  final String notes;
  final String color;
  final String sourceDetails;
  final String weight;
  final String vaccination;
  final String disease;
  final String? photoData;
  final String goshalaId;
  final bool isMilking;
  final String pregnancyStatus;
  final String dailyMilkYield;
  final DateTime? expectedCalvingDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const List<String> healthStatusOptions = [
    'स्वस्थ',
    'उपचार चल रहा है',
    'गर्भवती',
    'नया आगमन',
    'अन्य',
  ];

  static const List<String> pregnancyStatusOptions = [
    'गैर-गर्भवती',
    'गर्भवती',
    'संभावित',
    'लागू नहीं',
  ];

  String get statusLabel => status.isEmpty ? health : status;

  CowRecord copyWith({
    String? id,
    String? tag,
    String? name,
    int? age,
    String? breed,
    String? gender,
    DateTime? arrivalDate,
    String? health,
    String? status,
    String? notes,
    String? color,
    String? sourceDetails,
    String? weight,
    String? vaccination,
    String? disease,
    String? photoData,
    String? goshalaId,
    bool? isMilking,
    String? pregnancyStatus,
    String? dailyMilkYield,
    DateTime? expectedCalvingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CowRecord(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      name: name ?? this.name,
      age: age ?? this.age,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      health: health ?? this.health,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      sourceDetails: sourceDetails ?? this.sourceDetails,
      weight: weight ?? this.weight,
      vaccination: vaccination ?? this.vaccination,
      disease: disease ?? this.disease,
      photoData: photoData ?? this.photoData,
      goshalaId: goshalaId ?? this.goshalaId,
      isMilking: isMilking ?? this.isMilking,
      pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      dailyMilkYield: dailyMilkYield ?? this.dailyMilkYield,
      expectedCalvingDate: expectedCalvingDate ?? this.expectedCalvingDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tag': tag,
    'name': name,
    'age': age,
    'breed': breed,
    'gender': gender,
    'arrivalDate': arrivalDate.toIso8601String(),
    'health': health,
    'status': status,
    'notes': notes,
    'color': color,
    'sourceDetails': sourceDetails,
    'weight': weight,
    'vaccination': vaccination,
    'disease': disease,
    'photoData': photoData,
    'goshalaId': goshalaId,
    'isMilking': isMilking,
    'pregnancyStatus': pregnancyStatus,
    'dailyMilkYield': dailyMilkYield,
    'expectedCalvingDate': expectedCalvingDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CowRecord.fromJson(Map<String, dynamic> json) {
    final healthValue = _stringValue(json['health']).isNotEmpty
        ? _stringValue(json['health'])
        : _stringValue(json['status']);
    final statusValue = _stringValue(json['status']).isNotEmpty
        ? _stringValue(json['status'])
        : healthValue;

    final pregStatus = _stringValue(json['pregnancyStatus']);
    final fallbackPreg = statusValue == 'गर्भवती' ? 'गर्भवती' : 'गैर-गर्भवती';

    return CowRecord(
      id: _stringValue(json['id']),
      tag: _stringValue(json['tag']),
      name: _stringValue(json['name']),
      age: _intValue(json['age']),
      breed: _stringValue(json['breed']),
      gender: _stringValue(json['gender']),
      arrivalDate: _dateValue(json['arrivalDate'], fallback: DateTime.now()),
      health: healthValue.isNotEmpty ? healthValue : 'स्वस्थ',
      notes: _stringValue(json['notes']),
      status: statusValue.isNotEmpty ? statusValue : healthValue,
      color: _stringValue(json['color']),
      sourceDetails: _stringValue(json['sourceDetails']),
      weight: _stringValue(json['weight']),
      vaccination: _stringValue(json['vaccination']),
      disease: _stringValue(json['disease']),
      photoData: json['photoData'] as String?,
      goshalaId: _stringValue(json['goshalaId']).isNotEmpty
          ? _stringValue(json['goshalaId'])
          : 'jay-bhole-goshala',
      isMilking: json['isMilking'] is bool
          ? json['isMilking'] as bool
          : (json['isMilking']?.toString().toLowerCase() == 'true'),
      pregnancyStatus: pregStatus.isNotEmpty ? pregStatus : fallbackPreg,
      dailyMilkYield: _stringValue(json['dailyMilkYield']),
      expectedCalvingDate: _nullableDateValue(json['expectedCalvingDate']),
      createdAt: _dateValue(json['createdAt'], fallback: DateTime.now()),
      updatedAt: _dateValue(json['updatedAt'], fallback: DateTime.now()),
    );
  }

  static String _stringValue(dynamic value) => value?.toString() ?? '';

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _dateValue(dynamic value, {required DateTime fallback}) {
    if (value == null) return fallback;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  static DateTime? _nullableDateValue(dynamic value) {
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
