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
      bool needsResave = false;
      final cows = <CowRecord>[];
      for (final item in records) {
        if (item is Map<String, dynamic>) {
          final photoData = item['photoData'];
          // If legacy photoData contains a huge Base64 string, strip it from local cache
          if (photoData is String &&
              !photoData.startsWith('http://') &&
              !photoData.startsWith('https://')) {
            item['photoData'] = null;
            needsResave = true;
          }
          cows.add(CowRecord.fromJson(item));
        }
      }
      if (needsResave) {
        saveCows(cows);
      }
      return cows;
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
