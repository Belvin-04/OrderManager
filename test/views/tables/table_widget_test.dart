import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/utils/table_popup_overlay.dart';
import 'package:order_manager/utils/tap_functions.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart'
    show TableOrderStatus;
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';
import 'package:order_manager/views/tables/table_widget.dart';
import 'package:order_manager/views/ui_utils.dart' show getBackgroundColor;

Future<void> pumpTableWidget(WidgetTester tester, Table1 table) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tableOrderStatus(
          table.tableNo.toString(),
        ).overrideWith((ref) => const AsyncData(TableOrderStatus.pending)),
      ],
      child: MaterialApp(
        home: Scaffold(body: TableWidget(table: table)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(TablePopupOverlay.hide);
  testWidgets('tapping table opens popup menu', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await pumpTableWidget(tester, table);

    expect(find.byType(TablePopupMenu), findsNothing);

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);
  });

  testWidgets('tapping table twice closes popup menu', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await pumpTableWidget(tester, table);

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsNothing);
  });

  testWidgets('long press starts drag and shows feedback', (tester) async {
    final table = Table1(id: 't1', tableNo: 3);

    await pumpTableWidget(tester, table);

    final icon = find.byIcon(Icons.table_restaurant);
    final gesture = await tester.startGesture(tester.getCenter(icon));
    await tester.pump(const Duration(milliseconds: 600));

    await gesture.moveBy(const Offset(10, 10));
    await tester.pump();

    expect(find.byIcon(Icons.table_restaurant), findsWidgets);

    await gesture.up();
  });

  testWidgets('shows table number label', (tester) async {
    final table = Table1(id: 't9', tableNo: 9);

    await pumpTableWidget(tester, table);

    expect(find.text('T9'), findsOneWidget);
  });

  testWidgets('selecting take order from popup navigates to Orders page', (
    tester,
  ) async {
    final table = Table1(id: 't1', tableNo: 1);

    await pumpTableWidget(tester, table);

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Take Order'));
    await tester.pumpAndSettle();

    expect(find.byType(Orders), findsOneWidget);
  });

  testWidgets('selecting swap triggers swapTableOrder', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    bool swapCalled = false;

    swapTableOrder = (_, __, ___) async {
      swapCalled = true;
    };

    await pumpTableWidget(tester, table);

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Swap Table Order'));
    await tester.pumpAndSettle();

    expect(swapCalled, isTrue);
  });

  testWidgets('selecting clear triggers clearTable', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    bool clearCalled = false;

    clearTable = (_, __, ___) async {
      clearCalled = true;
    };

    await pumpTableWidget(tester, table);

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear Table'));
    await tester.pumpAndSettle();

    expect(clearCalled, isTrue);
  });

  testWidgets('popup closes after selecting an action', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await pumpTableWidget(tester, table);

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);

    await tester.tap(find.byTooltip('Swap Table Order'));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsNothing);
  });

  testWidgets('shows correct color for no order', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tableOrderStatus(
            table.tableNo.toString(),
          ).overrideWith((ref) => const AsyncData(TableOrderStatus.empty)),
        ],
        child: MaterialApp(
          home: Scaffold(body: TableWidget(table: table)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.table_restaurant));

    const expectedColor = Colors.blue;

    expect(icon.color, expectedColor);
  });

  testWidgets('shows correct color for pending status', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tableOrderStatus(
            table.tableNo.toString(),
          ).overrideWith((ref) => const AsyncData(TableOrderStatus.pending)),
        ],
        child: MaterialApp(
          home: Scaffold(body: TableWidget(table: table)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.table_restaurant));

    final expectedColor = getBackgroundColor(TableOrderStatus.pending);

    expect(icon.color, expectedColor);
  });

  testWidgets('shows correct color for completed status', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tableOrderStatus(
            table.tableNo.toString(),
          ).overrideWith((ref) => const AsyncData(TableOrderStatus.completed)),
        ],
        child: MaterialApp(
          home: Scaffold(body: TableWidget(table: table)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.table_restaurant));

    final expectedColor = getBackgroundColor(TableOrderStatus.completed);

    expect(icon.color, expectedColor);
  });

  testWidgets('shows correct color for canceled status', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tableOrderStatus(
            table.tableNo.toString(),
          ).overrideWith((ref) => const AsyncData(TableOrderStatus.canceled)),
        ],
        child: MaterialApp(
          home: Scaffold(body: TableWidget(table: table)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.table_restaurant));

    final expectedColor = getBackgroundColor(TableOrderStatus.canceled);

    expect(icon.color, expectedColor);
  });

  testWidgets('shows loading indicator while status is loading', (
    tester,
  ) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tableOrderStatus(
            table.tableNo.toString(),
          ).overrideWith((ref) => const AsyncLoading()),
        ],
        child: MaterialApp(
          home: Scaffold(body: TableWidget(table: table)),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error UI when provider throws error', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tableOrderStatus(table.tableNo.toString()).overrideWith(
            (ref) => AsyncError(Exception('failed'), StackTrace.empty),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: TableWidget(table: table)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
  });
}
