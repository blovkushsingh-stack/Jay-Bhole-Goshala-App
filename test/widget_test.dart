import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jay_bhole_goshala/main.dart';
import 'package:jay_bhole_goshala/models/cow_record.dart';
import 'package:jay_bhole_goshala/screens/auth_screen.dart';
import 'package:jay_bhole_goshala/screens/staff_management_screen.dart';
import 'package:jay_bhole_goshala/widgets/cow_avatar.dart';

void main() {
  testWidgets('home screen renders the main sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JayBholeGoshalaApp());

    expect(find.text('जय भोले गौशाला समिति'), findsOneWidget);
    expect(find.text('गौ सेवा के प्रमुख कार्य'), findsOneWidget);
    expect(find.text('दान करें'), findsWidgets);
  });

  testWidgets('bottom navigation opens the donation screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JayBholeGoshalaApp());

    await tester.tap(find.text('दान').last);
    await tester.pumpAndSettle();

    expect(find.text('गौ सेवा में अपना योगदान दें'), findsOneWidget);
    expect(find.text('₹51'), findsOneWidget);
    expect(find.text('ऑनलाइन दान सुविधा जल्द उपलब्ध होगी।'), findsNothing);
  });

  testWidgets(
    'home quick action opens cow management screen and back returns home',
    (WidgetTester tester) async {
      await tester.pumpWidget(const JayBholeGoshalaApp());

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
    await tester.pumpWidget(const JayBholeGoshalaApp());

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
    await tester.pumpWidget(const JayBholeGoshalaApp());

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
}
