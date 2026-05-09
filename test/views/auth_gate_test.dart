import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/app_user_repository.dart';
import 'package:order_manager/views/auth_gate.dart';
import 'package:order_manager/views/business/businesses_page.dart';
import 'package:order_manager/views/login_page.dart';

class MockUser extends Mock implements firebase_auth.User {}

class MockAppUserRepository extends Mock implements AppUserRepository {}

void main() {
  late MockAppUserRepository mockAppUserRepository;
  late MockUser mockUser;

  setUp(() {
    mockAppUserRepository = MockAppUserRepository();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('test-uid');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.displayName).thenReturn('Test User');

    registerFallbackValue(const AppUser(id: '', email: '', name: ''));
  });

  testWidgets('AuthGate shows loading indicator when auth state is loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWithValue(const AsyncLoading())],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AuthGate shows LoginPage when user is not logged in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWithValue(const AsyncData(null))],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('AuthGate shows error message when auth state has error', (
    tester,
  ) async {
    const errorMessage = 'Auth Error';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(
            const AsyncError(errorMessage, StackTrace.empty),
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    expect(find.text(errorMessage), findsOneWidget);
  });

  testWidgets(
    'AuthGate shows BusinessGate when user is logged in and app user exists',
    (tester) async {
      when(() => mockAppUserRepository.queryById('test-uid')).thenAnswer(
        (_) async => const AppUser(
          id: 'test-uid',
          email: 'test@example.com',
          name: 'Test User',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(AsyncData(mockUser)),
            appUserRepositoryProvider.overrideWithValue(mockAppUserRepository),
          ],
          child: const MaterialApp(home: AuthGate()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(BusinessGate), findsOneWidget);
      verify(() => mockAppUserRepository.queryById('test-uid')).called(1);
      verifyNever(() => mockAppUserRepository.saveUser(any()));
    },
  );

  testWidgets(
    'AuthGate saves user and shows BusinessGate when app user does not exist',
    (tester) async {
      when(
        () => mockAppUserRepository.queryById('test-uid'),
      ).thenAnswer((_) async => null);
      when(
        () => mockAppUserRepository.saveUser(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(AsyncData(mockUser)),
            appUserRepositoryProvider.overrideWithValue(mockAppUserRepository),
          ],
          child: const MaterialApp(home: AuthGate()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BusinessGate), findsOneWidget);
      verify(() => mockAppUserRepository.queryById('test-uid')).called(1);
      verify(() => mockAppUserRepository.saveUser(any())).called(1);
    },
  );

  testWidgets('AuthGate shows error when app user query fails', (tester) async {
    const errorMessage = 'Database Error';
    when(
      () => mockAppUserRepository.queryById('test-uid'),
    ).thenAnswer((_) async => throw errorMessage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(AsyncData(mockUser)),
          appUserRepositoryProvider.overrideWithValue(mockAppUserRepository),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text(errorMessage), findsOneWidget);
  });
}
