import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/utils_provider.dart';
import 'package:order_manager/views/bills/split_orders_dialog.dart';
import '../../test_helper.dart';

import '../utils.dart';

void main() {
  Future<void> pumpSplitOrdersDialog(
    WidgetTester tester, {
    required List<Order> orders,
    required void Function(Order order) onSelect,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeProvider.overrideWith(() => FakeThemeNotifier(themeMode)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          SplitOrdersDialog(orders: orders, onSelect: onSelect),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets("split orders dialog shows split orders", (
    WidgetTester tester,
  ) async {
    await pumpSplitOrdersDialog(
      tester,
      orders: [baseOrder(id: "1", splitNo: 1)],
      onSelect: (_) {},
    );

    expect(find.text("Split Orders"), findsOneWidget);
    expect(find.textContaining("Burger"), findsOneWidget);
  });

  testWidgets("tapping a split order calls onSelect and closes dialog", (
    WidgetTester tester,
  ) async {
    Order? selectedOrder;
    await pumpSplitOrdersDialog(
      tester,
      orders: [baseOrder(id: "1", splitNo: 1)],
      onSelect: (Order order) {
        selectedOrder = order;
      },
    );
    await tester.tap(find.textContaining("Burger"));
    await tester.pumpAndSettle();
    expect(selectedOrder!.item.name, "Burger");
    expect(find.byType(SplitOrdersDialog), findsNothing);
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    await pumpSplitOrdersDialog(
      tester,
      orders: [baseOrder()],
      onSelect: (_) {},
      themeMode: ThemeMode.dark,
    );

    expect(find.text('Split Orders'), findsOneWidget);
  });
}
