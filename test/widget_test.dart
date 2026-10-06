import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jay_bhole_goshala/app_data.dart';
import 'package:jay_bhole_goshala/home_screen.dart';
import 'package:jay_bhole_goshala/main.dart';
import 'package:jay_bhole_goshala/models/app_user.dart';
import 'package:jay_bhole_goshala/models/cow_record.dart';
import 'package:jay_bhole_goshala/screens/auth_screen.dart';
import 'package:jay_bhole_goshala/screens/cows_screen.dart';
import 'package:jay_bhole_goshala/screens/staff_management_screen.dart';
import 'package:jay_bhole_goshala/screens.dart';
import 'package:jay_bhole_goshala/services/firebase_backend.dart';
import 'package:jay_bhole_goshala/widgets/cow_avatar.dart';

void main() {
  testWidgets(
    'startup app with AuthGate renders AuthScreen when unauthenticated',
    (WidgetTester tester) async {
      await tester.pumpWidget(const JayBholeGoshalaApp());

      expect(find.byType(AuthGate), findsOneWidget);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Login'), findsWidgets);
    },
  );

  testWidgets('home screen renders the main sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JayBholeGoshalaApp(home: HomeScreen()));

    expect(find.text('जय भोले गौशाला समिति'), findsOneWidget);
    expect(find.text('गौ सेवा के प्रमुख कार्य'), findsOneWidget);
    expect(find.text('दान करें'), findsWidgets);
  });

  testWidgets('bottom navigation opens the donation screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JayBholeGoshalaApp(home: HomeScreen()));

    await tester.tap(find.text('दान').last);
    await tester.pumpAndSettle();

    expect(find.text('गौ सेवा में अपना योगदान दें'), findsOneWidget);
    expect(find.text('₹51'), findsOneWidget);
    expect(find.text('ऑनलाइन दान सुविधा जल्द उपलब्ध होगी।'), findsNothing);
  });

  testWidgets(
    'home quick action opens cow management screen and back returns home',
    (WidgetTester tester) async {
      await tester.pumpWidget(const JayBholeGoshalaApp(home: HomeScreen()));

      final cowAction = find.text('गौ जोड़ें');
      await tester.ensureVisible(cowAction);
      await tester.tap(cowAction);
      await tester.pumpAndSettle();
      expect(find.text('गाय सूची'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('जय भोले गौशाला समिति'), findsOneWidget);
    },
  );

  testWidgets('cow avatar falls back when stored photo data is invalid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CowAvatar(
            cow: CowRecord(
              id: 'COW-1',
              tag: 'TAG-1',
              name: 'गौमाता',
              age: 4,
              breed: 'द्वारिका',
              gender: 'मादा',
              arrivalDate: DateTime.now(),
              health: 'स्वस्थ',
              notes: 'demo',
              photoData: 'not-valid-base64!@@',
            ),
            size: 52,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
  });

  testWidgets('latest update opens its detail screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JayBholeGoshalaApp(home: HomeScreen()));

    final updateCard = find.text('चारा सेवा अभियान');
    await tester.ensureVisible(updateCard);
    await tester.tap(updateCard);
    await tester.pumpAndSettle();

    expect(find.text('दिनांक: जल्द उपलब्ध होगी'), findsOneWidget);
    expect(
      find.text('सेवा कार्य को और व्यवस्थित बनाने के लिए नई पहल।'),
      findsNothing,
    );
  });

  testWidgets('gaushala nav opens cow management section', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JayBholeGoshalaApp(home: HomeScreen()));

    await tester.tap(find.text('गौशाला').last);
    await tester.pumpAndSettle();

    expect(find.text('गाय सूची'), findsOneWidget);
    expect(find.text('गाय जोड़ें'), findsOneWidget);
  });

  testWidgets('auth screen shows login controls and no stale loading label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Please wait...'), findsNothing);
  });

  testWidgets('staff management screen renders its main controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StaffManagementScreen()));

    expect(find.text('Staff Management'), findsWidgets);
    expect(find.text('Add Staff'), findsWidgets);
  });

  testWidgets('cow detail screen renders public biodata, QR and barcode without edit for public', (
    WidgetTester tester,
  ) async {
    final testCow = CowRecord(
      id: 'COW-261002-99999',
      tag: 'TAG-999',
      name: 'कावेरी',
      age: 4,
      breed: 'साहीवाल',
      gender: 'मादा',
      arrivalDate: DateTime(2026, 1, 1),
      health: 'स्वस्थ',
      notes: 'दैनिक सेवा में',
      isMilking: true,
      dailyMilkYield: '8 लीटर',
    );

    await tester.pumpWidget(MaterialApp(home: CowDetailScreen(cow: testCow)));
    await tester.pumpAndSettle();

    expect(find.text('कावेरी'), findsOneWidget);
    expect(find.text('COW-261002-99999'), findsWidgets);
    expect(find.text('डिजिटल पहचान (QR Code & Barcode)'), findsOneWidget);
    expect(find.text('QR (बायोडेटा URL)'), findsOneWidget);
    expect(find.text('Barcode (Cow ID)'), findsOneWidget);
    expect(find.text('आईडी कार्ड प्रिंट'), findsOneWidget);
    expect(find.text('शेयर बायोडेटा'), findsOneWidget);

    // Unauthenticated/public visitor should not see edit/delete buttons
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('बायोडेटा संपादित करें (Edit / Update)'), findsNothing);
  });

  testWidgets('products screen renders responsive cards and opens detailed order dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProductsScreen()));
    await tester.pumpAndSettle();

    // 1. Verify hero banner and Hindi-first headings
    expect(find.text('गौशाला शुद्ध जैविक उत्पाद'), findsOneWidget);
    expect(find.text('सभी उत्पाद'), findsOneWidget);

    // 2. Verify products from LocalGoshalaStore are listed
    expect(find.text('नीम पाउडर'), findsOneWidget);
    expect(find.text('गौमूत्र अर्क'), findsOneWidget);
    expect(find.text('गोबर कंडे'), findsOneWidget);

    // 3. Verify price, stock and "ऑर्डर करें" buttons
    expect(find.text('₹120'), findsOneWidget);
    expect(find.text('ऑर्डर करें'), findsWidgets);

    // 4. Tap on "नीम पाउडर" card to open product detail
    final neemCard = find.text('नीम पाउडर');
    await tester.ensureVisible(neemCard);
    await tester.tap(neemCard);
    await tester.pumpAndSettle();

    // 5. Verify detail dialog contents
    expect(find.textContaining('100% शुद्ध देशी गौ उत्पाद'), findsOneWidget);
    expect(find.text('सहयोग मूल्य'), findsOneWidget);
    expect(find.text('उपलब्धता'), findsOneWidget);
    expect(find.text('WhatsApp पर ऑर्डर करें'), findsOneWidget);
    expect(find.text('कॉल संपर्क विवरण'), findsOneWidget);

    // Close detail dialog
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('WhatsApp पर ऑर्डर करें'), findsNothing);

    // Public / non-admin visitor should not see Admin buttons
    expect(find.text('नया उत्पाद जोड़ें (Add Product)'), findsNothing);
    expect(find.text('संपादित करें (Edit)'), findsNothing);
    expect(find.text('हटाएं (Delete)'), findsNothing);
  });

  testWidgets('admin sees add, edit and delete product controls', (
    WidgetTester tester,
  ) async {
    const adminUser = AppUser(
      uid: 'admin_test_1',
      email: 'admin@goshala.org',
      name: 'Admin Ji',
      role: UserRole.admin,
    );
    FirebaseBackend.instance.cachedCurrentUserProfile = adminUser;

    await tester.pumpWidget(
      const MaterialApp(
        home: ProductsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Admin sees Add Product button
    expect(find.text('नया उत्पाद जोड़ें (Add Product)'), findsOneWidget);

    // Verify Admin sees Edit and Delete on cards (Text 'Edit' and 'Delete' in desktop/tablet grid)
    expect(find.text('Edit'), findsWidgets);
    expect(find.text('Delete'), findsWidgets);

    // Tap Edit on first product
    final editButton = find.text('Edit').first;
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Verify Edit Dialog opens with existing data
    expect(find.text('उत्पाद संपादित करें'), findsOneWidget);
    expect(find.text('अपडेट करें'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('रद्द करें'));
    await tester.pumpAndSettle();

    // Reset cache for other tests
    FirebaseBackend.instance.cachedCurrentUserProfile = null;
  });

  test('ProductRecord update keeps existing document ID and updates all fields', () async {
    final store = LocalGoshalaStore.instance;
    final initialCount = store.products.length;

    const original = ProductRecord(
      id: 'PROD-TEST-EDIT-1',
      name: 'मूल उत्पाद',
      description: 'मूल विवरण',
      price: 100,
      stock: 10,
      icon: Icons.eco_outlined,
      category: 'जैविक खाद',
      photoUrl: 'https://example.com/old_photo.jpg',
    );

    // Add product
    await store.addProduct(original);
    expect(store.products.any((p) => p.id == 'PROD-TEST-EDIT-1'), isTrue);

    // Update same product with changed fields, without new photo (preserving old photoUrl)
    final updated = original.copyWith(
      name: 'संशोधित उत्पाद',
      description: 'नया विवरण',
      price: 150,
      stock: 25,
      category: 'आयुर्वेदिक / अर्क',
    );
    await store.updateProduct(updated);

    // Verify count did not increase (no duplicate created!)
    expect(store.products.where((p) => p.id == 'PROD-TEST-EDIT-1').length, 1);

    final retrieved = store.products.firstWhere((p) => p.id == 'PROD-TEST-EDIT-1');
    expect(retrieved.id, 'PROD-TEST-EDIT-1'); // Same document ID
    expect(retrieved.name, 'संशोधित उत्पाद');
    expect(retrieved.description, 'नया विवरण');
    expect(retrieved.price, 150);
    expect(retrieved.stock, 25);
    expect(retrieved.category, 'आयुर्वेदिक / अर्क');
    expect(retrieved.photoUrl, 'https://example.com/old_photo.jpg'); // Preserved

    // Clean up
    await store.deleteProduct('PROD-TEST-EDIT-1');
    expect(store.products.length, initialCount);
  });
}
