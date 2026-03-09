import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/views/auth_gate.dart';
import 'package:order_manager/views/login_page.dart';
import 'package:order_manager/views/startup/preferred_startup_screen.dart';

class MockUser extends Mock implements User {}

void main() {
  testWidgets('shows loading while auth state is unresolved', (tester) async {
    final authController = StreamController<User?>();
    addTearDown(authController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => authController.stream),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows LoginPage when auth user is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('shows PreferredStartupScreen when auth user exists', (
    tester,
  ) async {
    final user = MockUser();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          tablesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PreferredStartupScreen), findsOneWidget);
  });

  testWidgets('shows error UI when auth stream emits error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream<User?>.error(Exception('auth error')),
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Exception: auth error'), findsOneWidget);
  });
}
