import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/views/business/add_business_dialog.dart';

void main() {
  late Business business;

  setUp(() {
    business = const Business(id: 'b1', name: 'Test Business');
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Business initialBusiness,
    required Future<void> Function(Business) onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddBusinessDialog(
                        initalBusiness: initialBusiness,
                        onSave: onSave,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders dialog title and text field', (tester) async {
    await pumpDialog(tester, initialBusiness: business, onSave: (_) async {});

    expect(find.text('Create Business'), findsOneWidget);

    expect(find.byType(TextFormField), findsOneWidget);

    expect(find.text('Save'), findsOneWidget);

    expect(find.text('Business name'), findsOneWidget);
  });

  testWidgets('shows initial business name in text field', (tester) async {
    await pumpDialog(tester, initialBusiness: business, onSave: (_) async {});

    expect(find.text('Test Business'), findsOneWidget);
  });

  testWidgets('shows validation error when business name is empty', (
    tester,
  ) async {
    await pumpDialog(tester, initialBusiness: business, onSave: (_) async {});

    await tester.enterText(find.byType(TextFormField), '');

    await tester.tap(find.text('Save'));

    await tester.pumpAndSettle();

    expect(find.text('Business name is required'), findsOneWidget);
  });

  testWidgets('calls onSave with updated business', (tester) async {
    Business? savedBusiness;

    await pumpDialog(
      tester,
      initialBusiness: business,
      onSave: (business) async {
        savedBusiness = business;
      },
    );

    await tester.enterText(find.byType(TextFormField), 'Updated Business');

    await tester.tap(find.text('Save'));

    await tester.pumpAndSettle();

    expect(savedBusiness, isNotNull);

    expect(savedBusiness!.name, 'Updated Business');

    expect(savedBusiness!.id, 'b1');
  });

  testWidgets('closes dialog after successful save', (tester) async {
    await pumpDialog(tester, initialBusiness: business, onSave: (_) async {});

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Save'));

    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('awaits async save before closing dialog', (tester) async {
    bool saveCompleted = false;

    await pumpDialog(
      tester,
      initialBusiness: business,
      onSave: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));

        saveCompleted = true;
      },
    );

    await tester.tap(find.text('Save'));

    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);

    expect(saveCompleted, isFalse);

    await tester.pumpAndSettle();

    expect(saveCompleted, isTrue);

    expect(find.byType(AlertDialog), findsNothing);
  });
}
