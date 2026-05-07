import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseInitializer {
  static void enableOfflineFeatures() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
