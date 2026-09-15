import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cow_record.dart';

class LocalStorageService {
  LocalStorageService._(this._preferences);

  static const _cowsKey = 'cows';
  final SharedPreferences _preferences;

  static Future<LocalStorageService> create() async {
    return LocalStorageService._(await SharedPreferences.getInstance());
  }

  List<CowRecord> loadCows() {
    final raw = _preferences.getString(_cowsKey);
    if (raw == null) return [];
    try {
      final records = jsonDecode(raw) as List<dynamic>;
      return records
          .map((item) => CowRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> saveCows(List<CowRecord> cows) async {
    await _preferences.setString(
      _cowsKey,
      jsonEncode(cows.map((cow) => cow.toJson()).toList()),
    );
  }
}
