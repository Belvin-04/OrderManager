import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:order_manager/firebase_options.dart';

class TestHelper {
  static bool _initialized = false;

  static Future<void> setupFirebase() async {
    if (!_initialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final firestore = FirebaseFirestore.instance;

      const host = String.fromEnvironment(
        'EMULATOR_HOST',
        defaultValue: 'localhost',
      );

      try {
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        firestore.useFirestoreEmulator(host, 8080);
      } catch (e) {
        throw Exception('Failed to set up Firebase: $e');
      }
      _initialized = true;
    }

    if (FirebaseAuth.instance.currentUser == null) {
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
