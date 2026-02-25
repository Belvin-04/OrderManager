import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/utils/change_theme_switch.dart';
import 'package:order_manager/utils/navigation_drawer.dart' as drawer;
import 'package:order_manager/views/items/items.dart';
import 'package:order_manager/views/quick_orders.dart';
import 'package:order_manager/views/tables/tables.dart';
import 'package:order_manager/views/types/types.dart';

Future<void> pumpDrawer(WidgetTester tester) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const drawer.NavigationDrawer(),
          body: const Center(child: Text('Home')),
        ),
      ),
    ),
  );

  scaffoldKey.currentState!.openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('navigation drawer shows all menu items', (tester) async {
    await pumpDrawer(tester);

    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Tables'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('Quick Orders'), findsOneWidget);
    expect(find.text('Dark Theme'), findsOneWidget);
  });

  testWidgets('tapping Items navigates to Items screen', (tester) async {
    await pumpDrawer(tester);

    await tester.tap(find.text('Items'));
    await tester.pumpAndSettle();

    expect(find.byType(Items), findsOneWidget);
  });

  testWidgets('tapping Tables navigates to Tables screen', (tester) async {
    await pumpDrawer(tester);

    await tester.tap(find.text('Tables'));
    await tester.pumpAndSettle();

    expect(find.byType(Tables), findsOneWidget);
  });

  testWidgets('tapping Types navigates to Types screen', (tester) async {
    await pumpDrawer(tester);

    await tester.tap(find.text('Types'));
    await tester.pumpAndSettle();

    expect(find.byType(Types), findsOneWidget);
  });

  testWidgets('tapping Quick Orders navigates to Quick Orders screen', (
    tester,
  ) async {
    await pumpDrawer(tester);

    await tester.tap(find.text('Quick Orders'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickOrders), findsOneWidget);
  });

  testWidgets('dark theme switch is shown', (tester) async {
    await pumpDrawer(tester);

    expect(find.byType(ChangeThemeSwitch), findsOneWidget);
  });
}
