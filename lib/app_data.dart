import 'package:flutter/material.dart';

import 'branding/brand_config.dart';
import 'models/cow_record.dart';
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
  });

  final String name;
  final String description;
  final int price;
  final int stock;
  final IconData icon;
}

class LedgerEntry {
  const LedgerEntry({
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
  });

  final String title;
  final int amount;
  final String category;
  final bool isIncome;
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

class DonorRecord {
  const DonorRecord({
    required this.name,
    required this.mobile,
    required this.amount,
  });

  final String name;
  final String mobile;
  final int amount;
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
  bool initialized = false;

  final committee = const CommitteeConfig();
  final cows = <CowRecord>[];
  final volunteers = <VolunteerRecord>[
    VolunteerRecord(
      name: 'रमेश शर्मा',
      phone: 'संपर्क जल्द जोड़ें',
      present: true,
    ),
    VolunteerRecord(name: 'सीमा देवी', phone: 'संपर्क जल्द जोड़ें'),
  ];
  final products = const <ProductRecord>[
    ProductRecord(
      name: 'नीम पाउडर',
      description: 'प्राकृतिक देखभाल के लिए',
      price: 120,
      stock: 18,
      icon: Icons.eco_outlined,
    ),
    ProductRecord(
      name: 'गौमूत्र अर्क',
      description: 'गौ आधारित जैविक उत्पाद',
      price: 180,
      stock: 12,
      icon: Icons.local_drink_outlined,
    ),
    ProductRecord(
      name: 'गोबर कंडे',
      description: 'पूजा और हवन उपयोग के लिए',
      price: 80,
      stock: 30,
      icon: Icons.local_fire_department_outlined,
    ),
    ProductRecord(
      name: 'जैविक खाद',
      description: 'बगीचे और खेत के लिए',
      price: 250,
      stock: 9,
      icon: Icons.grass_rounded,
    ),
    ProductRecord(
      name: 'वर्मी कम्पोस्ट',
      description: 'पोषक प्राकृतिक खाद',
      price: 320,
      stock: 6,
      icon: Icons.spa_outlined,
    ),
  ];
  final ledger = <LedgerEntry>[
    const LedgerEntry(
      title: 'स्थानीय सेवा सहयोग',
      amount: 5100,
      category: 'दान',
      isIncome: true,
    ),
    const LedgerEntry(
      title: 'चारे की मासिक खरीद',
      amount: 2800,
      category: 'चारा',
      isIncome: false,
    ),
    const LedgerEntry(
      title: 'दवा और प्राथमिक उपचार',
      amount: 750,
      category: 'दवा',
      isIncome: false,
    ),
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

  Future<void> initialize() async {
    _storage = await LocalStorageService.create();
    cows
      ..clear()
      ..addAll(_storage!.loadCows());
    initialized = true;
    notifyListeners();
  }

  Future<void> syncLocalDataToCloud() async {
    for (final cow in cows) {
      await _cloud.saveCow(id: cow.id, data: cow.toJson());
    }
    for (final volunteer in volunteers) {
      await _cloud.saveRecord(
        collection: 'volunteers',
        id: volunteer.name,
        data: {
          'name': volunteer.name,
          'phone': volunteer.phone,
          'present': volunteer.present,
          'task': volunteer.task,
        },
      );
    }
    for (final product in products) {
      await _cloud.saveRecord(
        collection: 'products',
        id: product.name,
        data: {
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'stock': product.stock,
        },
      );
    }
    for (var index = 0; index < ledger.length; index++) {
      final entry = ledger[index];
      await _cloud.saveRecord(
        collection: entry.isIncome ? 'donations' : 'expenses',
        id: '${entry.title}-$index',
        data: {
          'title': entry.title,
          'amount': entry.amount,
          'category': entry.category,
          'isIncome': entry.isIncome,
        },
      );
    }
    await _cloud.saveRecord(
      collection: 'goshala',
      id: 'profile',
      data: {
        'name': committee.name,
        'address': committee.address,
        'mobile': committee.mobile,
        'whatsapp': committee.whatsapp,
      },
    );
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

  Future<void> _saveCows() async {
    await _storage?.saveCows(cows);
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
    donors.add(DonorRecord(name: name, mobile: mobile, amount: amount));
    notifyListeners();
  }

  void toggleAttendance(VolunteerRecord volunteer) {
    volunteer.present = !volunteer.present;
    notifyListeners();
  }
}
