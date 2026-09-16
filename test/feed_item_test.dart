import 'package:flutter_test/flutter_test.dart';
import 'package:jay_bhole_goshala/models/feed_item.dart';

void main() {
  group('FeedItem & FeedTransaction Model Tests', () {
    test('FeedItem json serialization & deserialization works properly', () {
      final json = {
        'id': 'FEED-BHUSA',
        'name': 'सूखा भूसा',
        'category': 'dryFodder',
        'currentStock': 450.5,
        'unit': 'kg',
        'minimumThreshold': 100.0,
        'costPerUnit': 12.5,
        'goshalaId': 'jay-bhole-goshala',
        'notes': 'दैनिक आवश्यकता',
        'lastRestockedDate': '2026-09-10T10:00:00.000',
        'createdAt': '2026-09-01T10:00:00.000',
        'updatedAt': '2026-09-15T10:00:00.000',
      };

      final item = FeedItem.fromJson(json);

      expect(item.id, 'FEED-BHUSA');
      expect(item.name, 'सूखा भूसा');
      expect(item.category, FeedCategory.dryFodder);
      expect(item.currentStock, 450.5);
      expect(item.isLowStock, false);
      expect(item.isOutOfStock, false);

      final serialized = item.toJson();
      expect(serialized['category'], 'dryFodder');
      expect(serialized['currentStock'], 450.5);
      expect(serialized['goshalaId'], 'jay-bhole-goshala');
    });

    test('FeedItem low stock and out of stock flags work accurately', () {
      final lowStockItem = FeedItem(
        id: 'FEED-1',
        name: 'हरा चारा',
        category: FeedCategory.greenFodder,
        currentStock: 40.0,
        minimumThreshold: 50.0,
      );
      expect(lowStockItem.isLowStock, true);
      expect(lowStockItem.isOutOfStock, false);

      final outOfStockItem = FeedItem(
        id: 'FEED-2',
        name: 'दाना',
        category: FeedCategory.concentrate,
        currentStock: 0.0,
        minimumThreshold: 20.0,
      );
      expect(outOfStockItem.isLowStock, true);
      expect(outOfStockItem.isOutOfStock, true);
    });

    test(
      'FeedTransaction json serialization & deserialization works properly',
      () {
        final txJson = {
          'id': 'TX-101',
          'feedItemId': 'FEED-BHUSA',
          'feedName': 'सूखा भूसा',
          'type': 'consumption',
          'quantity': 50.0,
          'unit': 'kg',
          'totalCost': 0.0,
          'donorName': '',
          'recordedBy': 'रमेश सेवक',
          'notes': 'सुबह का चारा',
          'goshalaId': 'jay-bhole-goshala',
          'date': '2026-09-16T08:00:00.000',
          'createdAt': '2026-09-16T08:00:00.000',
        };

        final tx = FeedTransaction.fromJson(txJson);

        expect(tx.id, 'TX-101');
        expect(tx.isConsumption, true);
        expect(tx.isPurchase, false);
        expect(tx.quantity, 50.0);
        expect(tx.recordedBy, 'रमेश सेवक');
      },
    );

    test('FeedTransaction handles purchase and donation types', () {
      final purchaseTx = FeedTransaction(
        id: 'TX-PUR-1',
        feedItemId: 'FEED-DANA',
        feedName: 'पशु आहार',
        type: FeedTransactionType.purchase,
        quantity: 200.0,
        totalCost: 5600.0,
      );
      expect(purchaseTx.isPurchase, true);
      expect(purchaseTx.totalCost, 5600.0);

      final donationTx = FeedTransaction(
        id: 'TX-DON-1',
        feedItemId: 'FEED-GREEN',
        feedName: 'हरा चारा',
        type: FeedTransactionType.donation,
        quantity: 100.0,
        donorName: 'सुरेश कुमार',
      );
      expect(donationTx.isDonation, true);
      expect(donationTx.donorName, 'सुरेश कुमार');
    });
  });
}
