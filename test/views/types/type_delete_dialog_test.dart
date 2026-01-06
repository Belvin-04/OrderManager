import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/views/types/type_delete_dialog.dart';

Future<void> pumpTypeDeleteDialog(
  WidgetTester tester, {
  required Type1 initialType,
  required Future<void> Function(Type1) onDelete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => TypeDeleteDialog(
                    initialType: initialType,
                    onDelete: onDelete,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows delete confirmation dialog', (tester) async {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    await pumpTypeDeleteDialog(
      tester,
      initialType: type,
      onDelete: (_) async {},
    );

    expect(find.text('Delete Type ?'), findsOneWidget);
    expect(find.text('This action cannot be undone...'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('calls onDelete with the given type', (tester) async {
    Type1? deletedType;
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    await pumpTypeDeleteDialog(
      tester,
      initialType: type,
      onDelete: (t) async {
        deletedType = t;
      },
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(deletedType, isNotNull);
    expect(deletedType, type);
  });

  testWidgets('dialog closes after delete', (tester) async {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    await pumpTypeDeleteDialog(
      tester,
      initialType: type,
      onDelete: (_) async {},
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
