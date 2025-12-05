import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workhive/main.dart';

void main() {
  group('WorkHive App Tests', () {
    testWidgets('WorkHiveApp loads and shows login page', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const WorkHiveApp());

      // Verify that the login page loads
      expect(find.text('WorkHive Tracker'), findsOneWidget);
      expect(find.text('SECURE LOGIN'), findsOneWidget);
      expect(find.byType(CustomInputField), findsWidgets);
    });

    testWidgets('Login page has admin toggle switch', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Find the switch for admin/employee toggle
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Login as Admin (Owner)'), findsOneWidget);
    });

    testWidgets('Registration link navigates to registration page', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Find and tap the registration link
      final registrationLink = find.text('New Employee? Register Here!');
      expect(registrationLink, findsOneWidget);

      await tester.tap(registrationLink);
      await tester.pumpAndSettle();

      // Verify registration page loaded
      expect(find.text('Join WorkHive'), findsOneWidget);
      expect(find.text('REGISTER & REQUEST APPROVAL'), findsOneWidget);
    });

    testWidgets('Admin login with correct credentials navigates to admin panel', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Toggle to admin mode
      final switchWidget = find.byType(Switch);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // Enter admin credentials
      final nameFields = find.byType(TextFormField);
      await tester.enterText(nameFields.at(0), 'Ashutosh');
      await tester.enterText(nameFields.at(1), 'ashu@gmail.com');
      await tester.enterText(nameFields.at(2), '805030');
      await tester.enterText(nameFields.at(3), 'aurasecret');

      // Tap login button
      await tester.tap(find.text('SECURE LOGIN'));
      await tester.pumpAndSettle();

      // Verify admin panel loaded
      expect(find.text('WorkHive Admin Panel'), findsOneWidget);
      expect(find.text('Live Worker Location Feed (3 Active)'), findsOneWidget);
    });

    testWidgets('Admin panel has FloatingActionButton (Add button)', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Login as admin first
      final switchWidget = find.byType(Switch);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      final nameFields = find.byType(TextFormField);
      await tester.enterText(nameFields.at(0), 'Ashutosh');
      await tester.enterText(nameFields.at(1), 'ashu@gmail.com');
      await tester.enterText(nameFields.at(2), '805030');
      await tester.enterText(nameFields.at(3), 'aurasecret');

      await tester.tap(find.text('SECURE LOGIN'));
      await tester.pumpAndSettle();

      // Verify FloatingActionButton exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Admin panel shows initial workers', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Login as admin
      final switchWidget = find.byType(Switch);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      final nameFields = find.byType(TextFormField);
      await tester.enterText(nameFields.at(0), 'Ashutosh');
      await tester.enterText(nameFields.at(1), 'ashu@gmail.com');
      await tester.enterText(nameFields.at(2), '805030');
      await tester.enterText(nameFields.at(3), 'aurasecret');

      await tester.tap(find.text('SECURE LOGIN'));
      await tester.pumpAndSettle();

      // Verify worker names are displayed
      expect(find.textContaining('Alia Khan'), findsOneWidget);
      expect(find.textContaining('Rohan Sharma'), findsOneWidget);
      expect(find.textContaining('Sara Jones'), findsOneWidget);
    });

    testWidgets('Employee login with approved account succeeds', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Enter employee credentials (Alia Khan is pre-approved)
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Alia Khan');
      await tester.enterText(fields.at(1), 'alia@company.com');
      await tester.enterText(fields.at(2), 'password123');

      await tester.tap(find.text('SECURE LOGIN'));
      await tester.pumpAndSettle();

      // Verify employee dashboard loaded
      expect(find.text('Worker Dashboard'), findsOneWidget);
      expect(find.textContaining('Welcome, Alia Khan'), findsOneWidget);
    });

    testWidgets('Employee dashboard has START, HOLD, STOP buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Login as employee
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Alia Khan');
      await tester.enterText(fields.at(1), 'alia@company.com');
      await tester.enterText(fields.at(2), 'password123');

      await tester.tap(find.text('SECURE LOGIN'));
      await tester.pumpAndSettle();

      // Verify control buttons exist
      expect(find.text('START'), findsOneWidget);
      expect(find.text('HOLD'), findsOneWidget);
      expect(find.text('STOP'), findsOneWidget);
    });

    testWidgets('Registration form validates empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(const WorkHiveApp());

      // Navigate to registration
      await tester.tap(find.text('New Employee? Register Here!'));
      await tester.pumpAndSettle();

      // Try to register without filling fields
      await tester.tap(find.text('REGISTER & REQUEST APPROVAL'));
      await tester.pumpAndSettle();

      // Should show error message (SnackBar)
      expect(find.text('Please fill in all fields.'), findsOneWidget);
    });

    testWidgets('WorkerManager maintains worker state', (WidgetTester tester) async {
      // Test the WorkerManager directly
      expect(workerManager.workers.length, equals(3));
      expect(workerManager.workers[0].name, equals('Alia Khan'));
      expect(workerManager.workers[0].isApproved, isTrue);

      // Test finding a worker
      final worker = workerManager.findWorker('w001');
      expect(worker, isNotNull);
      expect(worker!.name, equals('Alia Khan'));
    });
  });
}