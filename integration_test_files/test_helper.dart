import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:order_manager/firebase_options.dart';

class TestHelper {
  static bool _initialized = false;

  static Future<void> setupFirebase() async {
    if (!_initialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final firestore = FirebaseFirestore.instance;

      const useEmulator = bool.fromEnvironment(
        'USE_FIREBASE_EMULATOR',
        defaultValue: true,
      );

      if (useEmulator) {
        final host = const String.fromEnvironment('EMULATOR_HOST').isNotEmpty
            ? const String.fromEnvironment('EMULATOR_HOST')
            : (defaultTargetPlatform == TargetPlatform.android
                  ? '10.0.2.2'
                  : 'localhost');

        try {
          await FirebaseAuth.instance.useAuthEmulator(host, 9099);
          firestore.useFirestoreEmulator(host, 8080);
        } catch (e) {
          throw Exception('Failed to set up Firebase emulator: $e');
        }
      }
      _initialized = true;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (!currentUser.isAnonymous) {
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInAnonymously();
      }
    } else {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await FirebaseAuth.instance.authStateChanges().first;
  }

  static Future<void> createBusiness(String businessId, String ownerId) async {
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .set({'id': businessId, 'name': 'Test Business', 'ownerId': ownerId});
  }
}
