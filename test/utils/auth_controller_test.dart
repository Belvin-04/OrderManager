import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import '../test_helper.dart';

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  test(
    'signInWithGoogle signs in with credential when user is selected',
    () async {
      final googleSignIn = MockGoogleSignIn();
      final googleUser = MockGoogleSignInAccount();
      final googleAuth = MockGoogleSignInAuthentication();
      final firebaseAuth = MockFirebaseAuth();
      final userCredential = MockUserCredential();

      when(googleSignIn.signIn).thenAnswer((_) async => googleUser);
      when(() => googleUser.authentication).thenAnswer((_) async => googleAuth);
      when(() => googleAuth.accessToken).thenReturn('access-token');
      when(() => googleAuth.idToken).thenReturn('id-token');
      when(
        () => firebaseAuth.signInWithCredential(any()),
      ).thenAnswer((_) async => userCredential);

      final container = ProviderContainer(
        overrides: [
          googleSignInProvider.overrideWithValue(googleSignIn),
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithGoogle();

      final state = container.read(authControllerProvider);
      expect(state, const AsyncData<void>(null));
      verify(googleSignIn.signIn).called(1);
      verify(() => firebaseAuth.signInWithCredential(any())).called(1);
    },
  );

  test('signInWithGoogle does not sign in when user cancels', () async {
    final googleSignIn = MockGoogleSignIn();
    final firebaseAuth = MockFirebaseAuth();

    when(googleSignIn.signIn).thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [
        googleSignInProvider.overrideWithValue(googleSignIn),
        firebaseAuthProvider.overrideWithValue(firebaseAuth),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    final notifier = container.read(authControllerProvider.notifier);
    await notifier.signInWithGoogle();

    final state = container.read(authControllerProvider);
    expect(state, const AsyncData<void>(null));
    verify(googleSignIn.signIn).called(1);
    verifyNever(() => firebaseAuth.signInWithCredential(any()));
  });

  test('signInWithGoogle exposes errors', () async {
    final googleSignIn = MockGoogleSignIn();
    final firebaseAuth = MockFirebaseAuth();

    when(googleSignIn.signIn).thenThrow(Exception('google-failure'));

    final container = ProviderContainer(
      overrides: [
        googleSignInProvider.overrideWithValue(googleSignIn),
        firebaseAuthProvider.overrideWithValue(firebaseAuth),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    final notifier = container.read(authControllerProvider.notifier);
    await notifier.signInWithGoogle();

    final state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<Exception>());
  });

  test('signOut calls firebaseAuth.signOut', () async {
    final googleSignIn = MockGoogleSignIn();
    final firebaseAuth = MockFirebaseAuth();

    when(firebaseAuth.signOut).thenAnswer((_) async {});
    when(googleSignIn.signOut).thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [
        googleSignInProvider.overrideWithValue(googleSignIn),
        firebaseAuthProvider.overrideWithValue(firebaseAuth),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    final notifier = container.read(authControllerProvider.notifier);
    await notifier.signOut();

    final state = container.read(authControllerProvider);
    expect(state, const AsyncData<void>(null));
    verify(firebaseAuth.signOut).called(1);
    verify(googleSignIn.signOut).called(1);
  });

  test('signOut exposes errors', () async {
    final googleSignIn = MockGoogleSignIn();
    final firebaseAuth = MockFirebaseAuth();

    when(firebaseAuth.signOut).thenThrow(Exception('signout-failure'));
    when(googleSignIn.signOut).thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [
        googleSignInProvider.overrideWithValue(googleSignIn),
        firebaseAuthProvider.overrideWithValue(firebaseAuth),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    final notifier = container.read(authControllerProvider.notifier);
    await notifier.signOut();

    final state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<Exception>());
  });
}
