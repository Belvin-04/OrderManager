import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/views/business/delete_business_dialog.dart';

void main() {
  late Business business;

  setUp(() {
    business = const Business(
      id: '1',
      name: 'Test Business',
      ownerId: 'owner_1',
    );
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Future<void> Function(Business) onDelete,
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
                      builder: (_) => DeleteBusinessDialog(
                        initialBusiness: business,
                        onDelete: onDelete,
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

  testWidgets('renders dialog title and content', (tester) async {
    await pumpDialog(tester, onDelete: (_) async {});

    expect(find.text('Delete Business'), findsOneWidget);

    expect(
      find.text(
        'Delete "Test Business" and all its orders, '
        'types, items, and tables?',
      ),
      findsOneWidget,
    );

    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('calls onDelete with correct business', (tester) async {
    Business? deletedBusiness;

    await pumpDialog(
      tester,
      onDelete: (business) async {
        deletedBusiness = business;
      },
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deletedBusiness, isNotNull);
    expect(deletedBusiness!.id, '1');
    expect(deletedBusiness!.name, 'Test Business');
  });

  testWidgets('closes dialog after delete', (tester) async {
    await pumpDialog(tester, onDelete: (_) async {});

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('awaits async delete before closing dialog', (tester) async {
    bool deleteCompleted = false;

    await pumpDialog(
      tester,
      onDelete: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));

        deleteCompleted = true;
      },
    );

    await tester.tap(find.text('Delete'));

    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(deleteCompleted, isFalse);

    await tester.pumpAndSettle();

    expect(deleteCompleted, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
