import 'package:firebase_database/firebase_database.dart';

class FirebaseInitializer {
  static void enableOfflineFeatures() {
    final database = FirebaseDatabase.instance;
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);

    database.ref('tables').keepSynced(true);
    database.ref('orders').keepSynced(true);
    database.ref('types').keepSynced(true);
    database.ref('items').keepSynced(true);
  }
}
