import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedCategory {
  dryFodder('dryFodder', 'सूखा भूसा (Dry Fodder)'),
  greenFodder('greenFodder', 'हरा चारा (Green Fodder)'),
  concentrate('concentrate', 'पशु आहार / दाना (Concentrate)'),
  mineral('mineral', 'मिनरल मिक्स / सप्लीमेंट (Mineral Mix)'),
  other('other', 'अन्य चारा (Other Feed)');

  const FeedCategory(this.value, this.label);

  final String value;
  final String label;

  static FeedCategory fromString(dynamic value) {
    final str = value?.toString().trim().toLowerCase() ?? '';
    return switch (str) {
      'dryfodder' || 'dry_fodder' || 'भूसा' => FeedCategory.dryFodder,
      'greenfodder' || 'green_fodder' || 'हरा चारा' => FeedCategory.greenFodder,
      'concentrate' || 'दाना' || 'चोकर' => FeedCategory.concentrate,
      'mineral' || 'mineralmix' || 'मिनरल' => FeedCategory.mineral,
      _ => FeedCategory.other,
    };
  }
}

enum FeedTransactionType {
  consumption('consumption', 'दैनिक खपत (Consumed)'),
  purchase('purchase', 'खरीद आवक (Purchased)'),
  donation('donation', 'दान आवक (Donated)'),
  adjustment('adjustment', 'स्टॉक समायोजन (Adjusted)');

  const FeedTransactionType(this.value, this.label);

  final String value;
  final String label;

  static FeedTransactionType fromString(dynamic value) {
    final str = value?.toString().trim().toLowerCase() ?? '';
    return switch (str) {
      'consumption' || 'खपत' => FeedTransactionType.consumption,
      'purchase' || 'खरीद' => FeedTransactionType.purchase,
      'donation' || 'दान' => FeedTransactionType.donation,
      'adjustment' || 'समायोजन' => FeedTransactionType.adjustment,
      _ => FeedTransactionType.consumption,
    };
  }
}

class FeedItem {
  FeedItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    this.unit = 'kg',
    this.minimumThreshold = 50.0,
    this.costPerUnit = 0.0,
    this.goshalaId = 'jay-bhole-goshala',
    this.notes = '',
    DateTime? lastRestockedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : lastRestockedDate = lastRestockedDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final FeedCategory category;
  final double currentStock;
  final String unit;
  final double minimumThreshold;
  final double costPerUnit;
  final String goshalaId;
  final String notes;
  final DateTime lastRestockedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => currentStock <= minimumThreshold;
  bool get isOutOfStock => currentStock <= 0.0;

  FeedItem copyWith({
    String? id,
    String? name,
    FeedCategory? category,
    double? currentStock,
    String? unit,
    double? minimumThreshold,
    double? costPerUnit,
    String? goshalaId,
    String? notes,
    DateTime? lastRestockedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      goshalaId: goshalaId ?? this.goshalaId,
      notes: notes ?? this.notes,
      lastRestockedDate: lastRestockedDate ?? this.lastRestockedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.value,
    'currentStock': currentStock,
    'unit': unit,
    'minimumThreshold': minimumThreshold,
    'costPerUnit': costPerUnit,
    'goshalaId': goshalaId,
    'notes': notes,
    'lastRestockedDate': lastRestockedDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FeedItem.fromJson(Map<String, dynamic> json, {String? docId}) {
    return FeedItem(
      id: docId ?? _stringValue(json['id']),
      name: _stringValue(json['name']),
      category: FeedCategory.fromString(json['category']),
      currentStock: _doubleValue(json['currentStock']),
      unit: _stringValue(json['unit']).isNotEmpty
          ? _stringValue(json['unit'])
          : 'kg',
      minimumThreshold: _doubleValue(json['minimumThreshold'], fallback: 50.0),
      costPerUnit: _doubleValue(json['costPerUnit']),
      goshalaId: _stringValue(json['goshalaId']).isNotEmpty
          ? _stringValue(json['goshalaId'])
          : 'jay-bhole-goshala',
      notes: _stringValue(json['notes']),
      lastRestockedDate: _dateValue(
        json['lastRestockedDate'],
        fallback: DateTime.now(),
      ),
      createdAt: _dateValue(json['createdAt'], fallback: DateTime.now()),
      updatedAt: _dateValue(json['updatedAt'], fallback: DateTime.now()),
    );
  }

  static String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  static double _doubleValue(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
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
}

class FeedTransaction {
  FeedTransaction({
    required this.id,
    required this.feedItemId,
    required this.feedName,
    required this.type,
    required this.quantity,
    this.unit = 'kg',
    this.totalCost = 0.0,
    this.donorName = '',
    this.recordedBy = 'व्यवस्थापक',
    this.notes = '',
    this.goshalaId = 'jay-bhole-goshala',
    DateTime? date,
    DateTime? createdAt,
  }) : date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String feedItemId;
  final String feedName;
  final FeedTransactionType type;
  final double quantity;
  final String unit;
  final double totalCost;
  final String donorName;
  final String recordedBy;
  final String notes;
  final String goshalaId;
  final DateTime date;
  final DateTime createdAt;

  bool get isConsumption => type == FeedTransactionType.consumption;
  bool get isPurchase => type == FeedTransactionType.purchase;
  bool get isDonation => type == FeedTransactionType.donation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'feedItemId': feedItemId,
    'feedName': feedName,
    'type': type.value,
    'quantity': quantity,
    'unit': unit,
    'totalCost': totalCost,
    'donorName': donorName,
    'recordedBy': recordedBy,
    'notes': notes,
    'goshalaId': goshalaId,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory FeedTransaction.fromJson(Map<String, dynamic> json, {String? docId}) {
    return FeedTransaction(
      id: docId ?? _stringValue(json['id']),
      feedItemId: _stringValue(json['feedItemId']),
      feedName: _stringValue(json['feedName']),
      type: FeedTransactionType.fromString(json['type']),
      quantity: _doubleValue(json['quantity']),
      unit: _stringValue(json['unit']).isNotEmpty
          ? _stringValue(json['unit'])
          : 'kg',
      totalCost: _doubleValue(json['totalCost']),
      donorName: _stringValue(json['donorName']),
      recordedBy: _stringValue(json['recordedBy']).isNotEmpty
          ? _stringValue(json['recordedBy'])
          : 'व्यवस्थापक',
      notes: _stringValue(json['notes']),
      goshalaId: _stringValue(json['goshalaId']).isNotEmpty
          ? _stringValue(json['goshalaId'])
          : 'jay-bhole-goshala',
      date: _dateValue(json['date'], fallback: DateTime.now()),
      createdAt: _dateValue(json['createdAt'], fallback: DateTime.now()),
    );
  }

  static String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  static double _doubleValue(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
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
}
