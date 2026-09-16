import 'package:flutter_test/flutter_test.dart';
import 'package:jay_bhole_goshala/models/cow_record.dart';

void main() {
  group('CowRecord Model Verification Tests', () {
    test(
      'parses legacy JSON without new fields safely with default values',
      () {
        final legacyJson = {
          'id': 'COW-OLD-101',
          'tag': 'TAG-101',
          'name': 'गौरी',
          'age': 5,
          'breed': 'गिर',
          'gender': 'मादा',
          'arrivalDate': '2025-05-10T00:00:00.000',
          'health': 'स्वस्थ',
          'status': 'स्वस्थ',
          'notes': 'पुरानी गाय',
          'color': 'सफेद',
          'sourceDetails': 'दान',
          'weight': '300 kg',
          'vaccination': 'पूर्ण',
          'disease': '',
          'photoData': null,
        };

        final cow = CowRecord.fromJson(legacyJson);

        expect(cow.id, 'COW-OLD-101');
        expect(cow.name, 'गौरी');
        expect(cow.goshalaId, 'jay-bhole-goshala');
        expect(cow.isMilking, false);
        expect(cow.pregnancyStatus, 'गैर-गर्भवती');
        expect(cow.dailyMilkYield, '');
        expect(cow.expectedCalvingDate, isNull);
      },
    );

    test('parses new JSON with milking and pregnancy fields correctly', () {
      final newJson = {
        'id': 'COW-NEW-202',
        'tag': 'TAG-202',
        'name': 'कावेरी',
        'age': 4,
        'breed': 'साहीवाल',
        'gender': 'मादा',
        'arrivalDate': '2026-01-01T00:00:00.000',
        'health': 'गर्भवती',
        'status': 'गर्भवती',
        'notes': 'दुधारू एवं गर्भवती',
        'color': 'लाल',
        'sourceDetails': 'खरीद',
        'weight': '340 kg',
        'vaccination': 'FMD',
        'disease': '',
        'goshalaId': 'jay-bhole-goshala',
        'isMilking': true,
        'pregnancyStatus': 'गर्भवती',
        'dailyMilkYield': '10 लीटर',
        'expectedCalvingDate': '2026-10-15T00:00:00.000',
      };

      final cow = CowRecord.fromJson(newJson);

      expect(cow.isMilking, true);
      expect(cow.pregnancyStatus, 'गर्भवती');
      expect(cow.dailyMilkYield, '10 लीटर');
      expect(cow.expectedCalvingDate, DateTime(2026, 10, 15));

      final serialized = cow.toJson();
      expect(serialized['goshalaId'], 'jay-bhole-goshala');
      expect(serialized['isMilking'], true);
      expect(serialized['pregnancyStatus'], 'गर्भवती');
      expect(serialized['dailyMilkYield'], '10 लीटर');
      expect(serialized['expectedCalvingDate'], contains('2026-10-15'));
    });

    test('copyWith updates new fields properly without mutating original', () {
      final cow = CowRecord(
        id: 'COW-3',
        tag: 'TAG-3',
        name: 'श्यामा',
        age: 3,
        breed: 'थारपारकर',
        gender: 'मादा',
        arrivalDate: DateTime(2026, 2, 1),
        health: 'स्वस्थ',
        notes: '',
      );

      final updatedCow = cow.copyWith(
        isMilking: true,
        dailyMilkYield: '7 लीटर',
        pregnancyStatus: 'संभावित',
      );

      expect(cow.isMilking, false);
      expect(updatedCow.isMilking, true);
      expect(updatedCow.dailyMilkYield, '7 लीटर');
      expect(updatedCow.pregnancyStatus, 'संभावित');
    });
  });
}
