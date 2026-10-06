import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'branding/brand_config.dart';
import 'models/cow_record.dart';
import 'models/feed_item.dart';
import 'services/goshala_cloud_repository.dart';
import 'services/local_storage_service.dart';

class VolunteerRecord {
  VolunteerRecord({
    required this.name,
    required this.phone,
    this.present = false,
  });

  final String name;
  final String phone;
  bool present;
  String task = 'दैनिक सेवा';
}

class ProductRecord {
  const ProductRecord({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.icon,
    this.id = '',
    this.photoUrl = '',
    this.category = 'अन्य',
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final IconData icon;
  final String photoUrl;
  final String category;

  bool get hasPhoto => photoUrl.trim().isNotEmpty;

  ProductRecord copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    int? stock,
    IconData? icon,
    String? photoUrl,
    String? category,
  }) {
    return ProductRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      icon: icon ?? this.icon,
      photoUrl: photoUrl ?? this.photoUrl,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'photoUrl': photoUrl,
    'category': category,
    'iconCode': icon.codePoint,
  };

  factory ProductRecord.fromJson(Map<String, dynamic> json, {String? docId}) {
    final name = json['name']?.toString() ?? '';
    final IconData iconData;
    if (name.contains('नीम')) {
      iconData = Icons.eco_outlined;
    } else if (name.contains('अर्क')) {
      iconData = Icons.local_drink_outlined;
    } else if (name.contains('कंडे')) {
      iconData = Icons.local_fire_department_outlined;
    } else if (name.contains('खाद')) {
      iconData = Icons.grass_rounded;
    } else if (name.contains('कम्पोस्ट')) {
      iconData = Icons.spa_outlined;
    } else {
      iconData = Icons.shopping_bag_outlined;
    }

    return ProductRecord(
      id: docId ?? json['id']?.toString() ?? '',
      name: name,
      description: json['description']?.toString() ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toInt()
          : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      stock: (json['stock'] is num)
          ? (json['stock'] as num).toInt()
          : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      icon: iconData,
      photoUrl: json['photoUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? 'अन्य',
    );
  }
}

class LedgerEntry {
  const LedgerEntry({
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    this.id = '',
    this.date,
  });

  final String id;
  final String title;
  final int amount;
  final String category;
  final bool isIncome;
  final DateTime? date;

  LedgerEntry copyWith({
    String? id,
    String? title,
    int? amount,
    String? category,
    bool? isIncome,
    DateTime? date,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isIncome: isIncome ?? this.isIncome,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'isIncome': isIncome,
    'date': date?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json, {String? docId}) {
    final rawDate = json['date'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return LedgerEntry(
      id: docId ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toInt() : int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      category: json['category']?.toString() ?? 'अन्य',
      isIncome: json['isIncome'] == true,
      date: parsedDate,
    );
  }
}

class NoticeRecord {
  const NoticeRecord({
    required this.title,
    required this.type,
    required this.message,
  });

  final String title;
  final String type;
  final String message;
}

class DonationStatus {
  static const String pending = 'लंबित (Pending)';
  static const String completed = 'सफल (Completed)';
  static const String failed = 'विफल (Failed)';
  static const String cancelled = 'रद्द (Cancelled)';

  static bool isCompleted(String status) =>
      status == completed ||
      status.toLowerCase().contains('complete') ||
      status.contains('सफल');

  static bool isPending(String status) =>
      status == pending ||
      status.toLowerCase().contains('pending') ||
      status.contains('लंबित');

  static bool isFailed(String status) =>
      status == failed ||
      status.toLowerCase().contains('fail') ||
      status.contains('विफल');

  static bool isCancelled(String status) =>
      status == cancelled ||
      status.toLowerCase().contains('cancel') ||
      status.contains('रद्द');
}

class DonorRecord {
  DonorRecord({
    required this.name,
    required this.mobile,
    required this.amount,
    this.id = '',
    this.paymentMethod = 'UPI / Online QR',
    this.status = DonationStatus.pending,
    this.transactionRef = '',
    this.notes = '',
    DateTime? date,
    DateTime? createdAt,
  }) : date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String mobile;
  final int amount;
  final String paymentMethod;
  final String status;
  final String transactionRef;
  final String notes;
  final DateTime date;
  final DateTime createdAt;

  bool get isCompleted => DonationStatus.isCompleted(status);
  bool get isPending => DonationStatus.isPending(status);
  bool get isFailed => DonationStatus.isFailed(status);
  bool get isCancelled => DonationStatus.isCancelled(status);

  DonorRecord copyWith({
    String? id,
    String? name,
    String? mobile,
    int? amount,
    String? paymentMethod,
    String? status,
    String? transactionRef,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return DonorRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionRef: transactionRef ?? this.transactionRef,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': 'दान: $name',
    'name': name,
    'mobile': mobile,
    'amount': amount,
    'category': 'दान',
    'isIncome': isCompleted,
    'paymentMethod': paymentMethod,
    'status': status,
    'transactionRef': transactionRef,
    'notes': notes,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory DonorRecord.fromJson(Map<String, dynamic> json, {String? docId}) {
    final rawDate = json['date'] ?? json['createdAt'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate != null &&
        rawDate.runtimeType.toString() == 'Timestamp') {
      try {
        parsedDate = (rawDate as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return DonorRecord(
      id: docId ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'गुमनाम दानदाता',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toInt()
          : int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'UPI / Online QR',
      status: json['status']?.toString() ?? DonationStatus.pending,
      transactionRef: json['transactionRef']?.toString() ?? json['utr']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      date: parsedDate,
      createdAt: parsedDate,
    );
  }
}

class CommitteeConfig {
  const CommitteeConfig({
    this.name = BrandConfig.hindiCommitteeName,
    this.address = BrandConfig.address,
    this.mobile = BrandConfig.phone,
    this.whatsapp = BrandConfig.whatsapp,
    this.upiId = BrandConfig.upi,
    this.logoAsset = BrandConfig.logoAsset,
  });

  final String name;
  final String address;
  final String mobile;
  final String whatsapp;
  final String upiId;
  final String logoAsset;
}

class LocalGoshalaStore extends ChangeNotifier {
  LocalGoshalaStore._();

  static final LocalGoshalaStore instance = LocalGoshalaStore._();

  LocalStorageService? _storage;
  final _cloud = GoshalaCloudRepository();
  StreamSubscription<List<CowRecord>>? _cowsSubscription;
  StreamSubscription<List<FeedItem>>? _feedStockSubscription;
  StreamSubscription<List<FeedTransaction>>? _feedTransactionsSubscription;
  int _cowsListenerCount = 0;
  int _feedListenerCount = 0;
  bool initialized = false;

  /// Sample records exist only in debug/profile/test builds, never in release.
  static const bool seedDemoData = !kReleaseMode;

  final committee = const CommitteeConfig();
  final cows = <CowRecord>[];
  final feedStock = <FeedItem>[
    if (seedDemoData) ...[
      FeedItem(
        id: 'FEED-BHUSA',
        name: 'सूखा भूसा (Dry Fodder)',
        category: FeedCategory.dryFodder,
        currentStock: 450.0,
        unit: 'kg',
        minimumThreshold: 100.0,
        costPerUnit: 12.0,
      ),
      FeedItem(
        id: 'FEED-GREEN',
        name: 'हरा चारा (Green Fodder)',
        category: FeedCategory.greenFodder,
        currentStock: 300.0,
        unit: 'kg',
        minimumThreshold: 80.0,
        costPerUnit: 4.0,
      ),
      FeedItem(
        id: 'FEED-DANA',
        name: 'पशु आहार / दाना (Concentrate)',
        category: FeedCategory.concentrate,
        currentStock: 120.0,
        unit: 'kg',
        minimumThreshold: 40.0,
        costPerUnit: 28.0,
      ),
      FeedItem(
        id: 'FEED-MINERAL',
        name: 'मिनरल मिक्स / सप्लीमेंट',
        category: FeedCategory.mineral,
        currentStock: 25.0,
        unit: 'kg',
        minimumThreshold: 10.0,
        costPerUnit: 65.0,
      ),
    ],
  ];
  final feedTransactions = <FeedTransaction>[];
  final volunteers = <VolunteerRecord>[
    if (seedDemoData) ...[
      VolunteerRecord(
        name: 'रमेश शर्मा',
        phone: 'संपर्क जल्द जोड़ें',
        present: true,
      ),
      VolunteerRecord(name: 'सीमा देवी', phone: 'संपर्क जल्द जोड़ें'),
    ],
  ];
  final products = <ProductRecord>[
    if (seedDemoData) ...[
      const ProductRecord(
        id: 'PROD-001',
        name: 'नीम पाउडर',
        description: 'प्राकृतिक देखभाल के लिए',
        price: 120,
        stock: 18,
        icon: Icons.eco_outlined,
        category: 'आयुर्वेदिक / अर्क',
      ),
      const ProductRecord(
        id: 'PROD-002',
        name: 'गौमूत्र अर्क',
        description: 'गौ आधारित जैविक उत्पाद',
        price: 180,
        stock: 12,
        icon: Icons.local_drink_outlined,
        category: 'आयुर्वेदिक / अर्क',
      ),
      const ProductRecord(
        id: 'PROD-003',
        name: 'गोबर कंडे',
        description: 'पूजा और हवन उपयोग के लिए',
        price: 80,
        stock: 30,
        icon: Icons.local_fire_department_outlined,
        category: 'पूजा सामग्री',
      ),
      const ProductRecord(
        id: 'PROD-004',
        name: 'जैविक खाद',
        description: 'बगीचे और खेत के लिए',
        price: 250,
        stock: 9,
        icon: Icons.grass_rounded,
        category: 'जैविक खाद',
      ),
      const ProductRecord(
        id: 'PROD-005',
        name: 'वर्मी कम्पोस्ट',
        description: 'पोषक प्राकृतिक खाद',
        price: 320,
        stock: 6,
        icon: Icons.spa_outlined,
        category: 'जैविक खाद',
      ),
    ],
  ];
  final ledger = <LedgerEntry>[
    if (seedDemoData) ...[
      const LedgerEntry(
        id: 'LEDGER-001',
        title: 'स्थानीय सेवा सहयोग',
        amount: 5100,
        category: 'दान',
        isIncome: true,
      ),
      const LedgerEntry(
        id: 'LEDGER-002',
        title: 'चारे की मासिक खरीद',
        amount: 2800,
        category: 'चारा',
        isIncome: false,
      ),
      const LedgerEntry(
        id: 'LEDGER-003',
        title: 'दवा और प्राथमिक उपचार',
        amount: 750,
        category: 'दवा',
        isIncome: false,
      ),
    ],
  ];
  final notices = const <NoticeRecord>[
    NoticeRecord(
      title: 'रविवार श्रमदान',
      type: 'श्रमदान',
      message: 'रविवार सुबह 7 बजे सेवा परिसर में मिलें।',
    ),
    NoticeRecord(
      title: 'मासिक बैठक',
      type: 'बैठक',
      message: 'मासिक सेवा समीक्षा की तारीख जल्द साझा होगी।',
    ),
    NoticeRecord(
      title: 'चिकित्सा शिविर',
      type: 'चिकित्सा',
      message: 'पशु चिकित्सक की अगली विजिट की तैयारी चल रही है।',
    ),
  ];
  final donors = <DonorRecord>[];
  final checklist = <String, bool>{
    'चारा': true,
    'पानी': true,
    'सफाई': false,
    'चिकित्सा': false,
  };

  int get healthyCows => cows.where((cow) => cow.health == 'स्वस्थ').length;
  int get presentVolunteers =>
      volunteers.where((volunteer) => volunteer.present).length;
  int get income => ledger
      .where((entry) => entry.isIncome)
      .fold(0, (sum, entry) => sum + entry.amount);
  int get expense => ledger
      .where((entry) => !entry.isIncome)
      .fold(0, (sum, entry) => sum + entry.amount);
  int get completedChecklist => checklist.values.where((value) => value).length;

  double get totalFeedStockKg =>
      feedStock.fold(0.0, (sum, item) => sum + item.currentStock);
  int get lowStockFeedCount =>
      feedStock.where((item) => item.isLowStock).length;

  Future<void> initialize() async {
    _storage = await LocalStorageService.create();
    cows
      ..clear()
      ..addAll(_storage!.loadCows());
    initialized = true;
    notifyListeners();
    _subscribeCows();
  }

  /// Call from a screen's initState; pair with [stopCowsSync] in dispose.
  void startCowsSync() {
    _cowsListenerCount++;
    _subscribeCows();
  }

  void stopCowsSync() {
    if (_cowsListenerCount > 0) _cowsListenerCount--;
  }

  void _subscribeCows() {
    if (!_cloud.isAvailable) return;

    _cowsSubscription?.cancel();
    _cowsSubscription = _cloud.watchCows().listen(
      (cloudCows) {
        cows
          ..clear()
          ..addAll(cloudCows);
        _saveCows();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('LocalGoshalaStore realtime cows sync error: $error');
      },
    );

    _runMigrationIfPending();
  }

  Future<void> _runMigrationIfPending() async {
    if (!_cloud.canSync) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('cow_photos_migrated_v1') ?? false)) {
        final count = await _cloud.migrateLegacyCowPhotos();
        if (count > 0) {
          debugPrint('LocalGoshalaStore: Auto-migrated $count cows with legacy photoData.');
          final fresh = await _cloud.fetchCows();
          if (fresh.isNotEmpty) {
            cows
              ..clear()
              ..addAll(fresh);
            await _saveCows();
            notifyListeners();
          }
        }
        await prefs.setBool('cow_photos_migrated_v1', true);
      }
    } catch (e) {
      debugPrint('LocalGoshalaStore: _runMigrationIfPending error: $e');
    }
  }

  /// Call from a screen's initState; pair with [stopFeedSync] in dispose.
  void startFeedSync() {
    _feedListenerCount++;
    _subscribeFeed();
  }

  void stopFeedSync() {
    if (_feedListenerCount > 0) _feedListenerCount--;
    if (_feedListenerCount == 0) {
      _feedStockSubscription?.cancel();
      _feedStockSubscription = null;
      _feedTransactionsSubscription?.cancel();
      _feedTransactionsSubscription = null;
    }
  }

  void _subscribeFeed() {
    if (!_cloud.canSync) return;

    _feedStockSubscription ??= _cloud.watchFeedStock().listen(
      (cloudFeed) {
        if (cloudFeed.isNotEmpty) {
          feedStock
            ..clear()
            ..addAll(cloudFeed);
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('LocalGoshalaStore realtime feed stock sync error: $error');
        _feedStockSubscription?.cancel();
        _feedStockSubscription = null;
      },
    );

    _feedTransactionsSubscription ??= _cloud.watchFeedTransactions().listen(
      (cloudTxs) {
        if (cloudTxs.isNotEmpty) {
          feedTransactions
            ..clear()
            ..addAll(cloudTxs);
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint(
          'LocalGoshalaStore realtime feed transactions sync error: $error',
        );
        _feedTransactionsSubscription?.cancel();
        _feedTransactionsSubscription = null;
      },
    );
  }

  /// Restarts listeners with live Firestore data.
  void refreshRealtimeListeners() {
    _subscribeCows();
    _feedStockSubscription?.cancel();
    _feedStockSubscription = null;
    _feedTransactionsSubscription?.cancel();
    _feedTransactionsSubscription = null;
    if (_feedListenerCount > 0) _subscribeFeed();
  }

  @override
  void dispose() {
    _cowsSubscription?.cancel();
    _feedStockSubscription?.cancel();
    _feedTransactionsSubscription?.cancel();
    super.dispose();
  }

  /// Uploads only user-entered local records (cows). Hardcoded demo data
  /// (volunteers, products, ledger, default feed, committee profile) is never
  /// written so existing Firebase data is not overwritten.
  Future<void> syncLocalDataToCloud() async {
    final writes = <Future<void>>[
      for (final cow in cows) _cloud.saveCow(id: cow.id, data: cow.toJson()),
    ];
    // Waits for every write, then rethrows the first error (if any).
    await Future.wait(writes);
  }

  Future<void> addCow(CowRecord cow) async {
    cows.add(cow);
    await _saveCows();
    await _cloud.saveCow(id: cow.id, data: cow.toJson());
    notifyListeners();
  }

  Future<void> updateCow(CowRecord cow) async {
    final index = cows.indexWhere((item) => item.id == cow.id);
    if (index == -1) return;
    cows[index] = cow;
    await _saveCows();
    await _cloud.saveCow(id: cow.id, data: cow.toJson());
    notifyListeners();
  }

  Future<void> deleteCow(String id) async {
    cows.removeWhere((cow) => cow.id == id);
    await _saveCows();
    await _cloud.deleteCow(id);
    notifyListeners();
  }

  /// Finds cow in local list or fetches directly from Firestore by ID or tag
  Future<CowRecord?> getCowById(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    final index = cows.indexWhere(
      (c) =>
          c.id.toLowerCase() == cleanId.toLowerCase() ||
          c.tag.toLowerCase() == cleanId.toLowerCase(),
    );
    if (index >= 0) return cows[index];

    final cloudCow = await _cloud.fetchCowById(cleanId);
    if (cloudCow != null) {
      final existingIdx = cows.indexWhere((c) => c.id == cloudCow.id);
      if (existingIdx >= 0) {
        cows[existingIdx] = cloudCow;
      } else {
        cows.add(cloudCow);
      }
      notifyListeners();
      return cloudCow;
    }
    return null;
  }

  Future<void> _saveCows() async {
    await _storage?.saveCows(cows);
  }

  // -------------------------------------------------------------
  // Feed & Stock Operations
  // -------------------------------------------------------------

  Future<void> saveFeedItem(FeedItem item) async {
    final index = feedStock.indexWhere((f) => f.id == item.id);
    if (index >= 0) {
      feedStock[index] = item;
    } else {
      feedStock.add(item);
    }
    await _cloud.saveFeedItem(item);
    notifyListeners();
  }

  Future<void> deleteFeedItem(String id) async {
    feedStock.removeWhere((f) => f.id == id);
    await _cloud.deleteFeedItem(id);
    notifyListeners();
  }

  Future<void> logFeedConsumption({
    required String feedItemId,
    required double consumedQty,
    String notes = '',
    String recordedBy = 'कर्मचारी',
  }) async {
    final index = feedStock.indexWhere((f) => f.id == feedItemId);
    if (index == -1) return;

    final current = feedStock[index];
    final updatedStock = (current.currentStock - consumedQty).clamp(
      0.0,
      999999.0,
    );
    final updatedFeed = current.copyWith(
      currentStock: updatedStock,
      updatedAt: DateTime.now(),
    );

    feedStock[index] = updatedFeed;

    final tx = FeedTransaction(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      feedItemId: feedItemId,
      feedName: current.name,
      type: FeedTransactionType.consumption,
      quantity: consumedQty,
      unit: current.unit,
      notes: notes,
      recordedBy: recordedBy,
      date: DateTime.now(),
    );

    feedTransactions.insert(0, tx);
    await _cloud.logFeedTransaction(tx, updatedStock: updatedStock);
    notifyListeners();
  }

  Future<void> logFeedPurchaseOrDonation({
    required String feedItemId,
    required double addedQty,
    required FeedTransactionType type,
    double totalCost = 0.0,
    String donorName = '',
    String notes = '',
    String recordedBy = 'व्यवस्थापक',
  }) async {
    final index = feedStock.indexWhere((f) => f.id == feedItemId);
    if (index == -1) return;

    final current = feedStock[index];
    final updatedStock = current.currentStock + addedQty;
    final updatedFeed = current.copyWith(
      currentStock: updatedStock,
      lastRestockedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    feedStock[index] = updatedFeed;

    final tx = FeedTransaction(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      feedItemId: feedItemId,
      feedName: current.name,
      type: type,
      quantity: addedQty,
      unit: current.unit,
      totalCost: totalCost,
      donorName: donorName,
      notes: notes,
      recordedBy: recordedBy,
      date: DateTime.now(),
    );

    feedTransactions.insert(0, tx);
    await _cloud.logFeedTransaction(tx, updatedStock: updatedStock);
    notifyListeners();
  }

  void toggleChecklist(String key) {
    checklist[key] = !(checklist[key] ?? false);
    notifyListeners();
  }

  void addVolunteer(String name) {
    if (name.trim().isEmpty) return;
    volunteers.add(
      VolunteerRecord(name: name.trim(), phone: 'संपर्क जल्द जोड़ें'),
    );
    notifyListeners();
  }

  void addPendingDonation({
    required String name,
    required String mobile,
    required int amount,
  }) {
    final entry = DonorRecord(
      id: 'DON-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      mobile: mobile,
      amount: amount,
    );
    donors.insert(0, entry);
    notifyListeners();
  }

  Future<void> addDonation(DonorRecord donation) async {
    final record = donation.id.isEmpty
        ? donation.copyWith(id: 'DON-${DateTime.now().millisecondsSinceEpoch}')
        : donation;

    final existingIndex = donors.indexWhere((d) => d.id == record.id);
    if (existingIndex >= 0) {
      donors[existingIndex] = record;
    } else {
      donors.insert(0, record);
    }

    // Only record in ledger as income if payment status is verified/completed!
    final ledgerId = 'LEDGER-${record.id}';
    final ledgerIndex = ledger.indexWhere((l) => l.id == ledgerId || l.id == record.id);
    if (record.isCompleted) {
      final ledgerEntry = LedgerEntry(
        id: ledgerId,
        title: 'दान: ${record.name}',
        amount: record.amount,
        category: 'दान',
        isIncome: true,
        date: record.date,
      );
      if (ledgerIndex >= 0) {
        ledger[ledgerIndex] = ledgerEntry;
      } else {
        ledger.insert(0, ledgerEntry);
      }
    } else {
      // If payment is pending, failed, or cancelled, remove from income ledger
      if (ledgerIndex >= 0) {
        ledger.removeAt(ledgerIndex);
      }
    }

    await _cloud.saveDonation(id: record.id, data: record.toJson());
    notifyListeners();
  }

  Future<void> deleteDonation(String id) async {
    donors.removeWhere((d) => d.id == id);
    ledger.removeWhere((l) => l.id == 'LEDGER-$id' || l.id == id);
    await _cloud.deleteDonation(id);
    notifyListeners();
  }

  Future<void> loadDonationsFromCloud() async {
    final list = await _cloud.fetchDonations();
    if (list.isNotEmpty) {
      for (final json in list) {
        final donor = DonorRecord.fromJson(json, docId: json['id'] as String?);
        final existingIdx = donors.indexWhere((d) => d.id == donor.id);
        if (existingIdx >= 0) {
          donors[existingIdx] = donor;
        } else {
          donors.add(donor);
        }

        // Only verified completed donations contribute to ledger income
        if (donor.isCompleted) {
          final ledgerId = 'LEDGER-${donor.id}';
          if (!ledger.any((l) => l.id == ledgerId)) {
            ledger.insert(
              0,
              LedgerEntry(
                id: ledgerId,
                title: 'दान: ${donor.name}',
                amount: donor.amount,
                category: 'दान',
                isIncome: true,
                date: donor.date,
              ),
            );
          }
        }
      }
      notifyListeners();
    }
  }

  void toggleAttendance(VolunteerRecord volunteer) {
    volunteer.present = !volunteer.present;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Income & Expense Operations
  // -------------------------------------------------------------

  Future<void> addLedgerEntry(LedgerEntry entry) async {
    final newEntry = entry.id.isEmpty
        ? entry.copyWith(id: 'LEDGER-${DateTime.now().millisecondsSinceEpoch}')
        : entry;
    ledger.insert(0, newEntry);
    await _cloud.saveLedgerEntry(
      id: newEntry.id,
      data: newEntry.toJson(),
      isIncome: newEntry.isIncome,
    );
    notifyListeners();
  }

  Future<void> updateLedgerEntry(LedgerEntry entry) async {
    final index = ledger.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      ledger[index] = entry;
      await _cloud.saveLedgerEntry(
        id: entry.id,
        data: entry.toJson(),
        isIncome: entry.isIncome,
      );
      notifyListeners();
    }
  }

  Future<void> deleteLedgerEntry(String id) async {
    final index = ledger.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final entry = ledger.removeAt(index);
      await _cloud.deleteLedgerEntry(id: id, isIncome: entry.isIncome);
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // Product Operations
  // -------------------------------------------------------------

  Future<void> addProduct(ProductRecord product) async {
    final record = product.id.isEmpty
        ? product.copyWith(id: 'PROD-${DateTime.now().millisecondsSinceEpoch}')
        : product;
    final index = products.indexWhere((p) => p.id == record.id);
    if (index >= 0) {
      products[index] = record;
    } else {
      products.insert(0, record);
    }
    await _cloud.saveProduct(id: record.id, data: record.toJson());
    notifyListeners();
  }

  Future<void> updateProduct(ProductRecord product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }
    await _cloud.saveProduct(id: product.id, data: product.toJson());
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    await _cloud.deleteProduct(id);
    notifyListeners();
  }

  Future<void> loadProductsFromCloud() async {
    final list = await _cloud.fetchProducts();
    if (list.isNotEmpty) {
      for (final json in list) {
        final product = ProductRecord.fromJson(json, docId: json['id'] as String?);
        final existingIdx = products.indexWhere((p) => p.id == product.id);
        if (existingIdx >= 0) {
          products[existingIdx] = product;
        } else {
          products.add(product);
        }
      }
      notifyListeners();
    }
  }

  Future<String> uploadProductPhoto({
    required String productId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    return _cloud.uploadProductPhoto(
      productId: productId,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<String> uploadCowPhoto({
    required String cowId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    return _cloud.uploadCowPhoto(
      cowId: cowId,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<int> migrateLegacyCowPhotos() async {
    final count = await _cloud.migrateLegacyCowPhotos();
    if (count > 0) {
      final fresh = await _cloud.fetchCows();
      if (fresh.isNotEmpty) {
        cows
          ..clear()
          ..addAll(fresh);
        await _saveCows();
        notifyListeners();
      }
    }
    return count;
  }
}
