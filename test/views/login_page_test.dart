import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/login_page.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  testWidgets('shows sign in button when idle', (tester) async {
    final googleSignIn = MockGoogleSignIn();
    final firebaseAuth = MockFirebaseAuth();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleSignInProvider.overrideWithValue(googleSignIn),
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('tapping sign in calls google sign in', (tester) async {
    final googleSignIn = MockGoogleSignIn();
    final firebaseAuth = MockFirebaseAuth();

    when(googleSignIn.signIn).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleSignInProvider.overrideWithValue(googleSignIn),
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    verify(googleSignIn.signIn).called(1);
  });

  testWidgets('shows loading state and disables sign in button', (
    tester,
  ) async {
    final googleSignIn = MockGoogleSignIn();
    final firebaseAuth = MockFirebaseAuth();
    final pendingSignIn = Completer<GoogleSignInAccount?>();

    when(googleSignIn.signIn).thenAnswer((_) => pendingSignIn.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleSignInProvider.overrideWithValue(googleSignIn),
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.text('Signing in...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
