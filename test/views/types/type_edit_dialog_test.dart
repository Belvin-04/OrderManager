import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/views/types/type_edit_dialog.dart';

Future<void> pumpTypeEditDialog(
  WidgetTester tester, {
  required Type1 initialType,
  required Future<void> Function(Type1) onSave,
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
                  builder: (_) =>
                      TypeEditDialog(initialType: initialType, onSave: onSave),
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
  testWidgets('shows initial type name and price', (tester) async {
    final initial = Type1(id: 't1', type: 'Extra', price: 20);

    await pumpTypeEditDialog(
      tester,
      initialType: initial,
      onSave: (_) async {},
    );

    expect(find.text('Extra'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    final initial = Type1(id: 't1', type: '', price: 0);

    await pumpTypeEditDialog(
      tester,
      initialType: initial,
      onSave: (_) async {},
    );

    await tester.tap(find.text('Save Type'));
    await tester.pump();

    expect(find.text('Please Enter Type'), findsOneWidget);
    expect(find.text('Please Enter Type Price'), findsOneWidget);
  });

  testWidgets('calls onSave with updated type when form is valid', (
    tester,
  ) async {
    Type1? savedType;

    final initial = Type1(id: 't1', type: 'Extra', price: 20);

    await pumpTypeEditDialog(
      tester,
      initialType: initial,
      onSave: (type) async {
        savedType = type;
      },
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Premium');
    await tester.enterText(find.byType(TextFormField).at(1), '50');

    await tester.tap(find.text('Save Type'));
    await tester.pumpAndSettle();

    expect(savedType, isNotNull);
    expect(savedType!.type, 'Premium');
    expect(savedType!.price, 50);
  });

  testWidgets('dialog closes after successful save', (tester) async {
    final initial = Type1(id: 't1', type: 'Extra', price: 20);

    await pumpTypeEditDialog(
      tester,
      initialType: initial,
      onSave: (_) async {},
    );

    await tester.tap(find.text('Save Type'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows loading indicator and disables save button when saving', (
    tester,
  ) async {
    final completer = Completer<void>();
    bool called = false;

    await pumpTypeEditDialog(
      tester,
      initialType: Type1(id: 't1', type: 'Extra', price: 20),
      onSave: (_) async {
        called = true;
        await completer.future;
      },
    );

    await tester.tap(find.text('Save Type'));
    await tester.pump();

    expect(called, isTrue);

    expect(find.text('Save Type'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
