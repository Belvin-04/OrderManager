import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../integration_test_files/firebase_app_user_remote_data_source_test.dart'
    as app_user;
import '../integration_test_files/firebase_business_remote_data_source_test.dart'
    as business;
import '../integration_test_files/firebase_item_remote_data_source_test.dart'
    as item;
import '../integration_test_files/firebase_order_remote_data_source_test.dart'
    as order;
import '../integration_test_files/firebase_table_remote_data_source_test.dart'
    as table;
import '../integration_test_files/firebase_type_remote_data_source_test.dart'
    as type;
import '../integration_test_files/index_verification_test.dart'
    as index_verification;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('All Integration Tests', () {
    group('App User', app_user.main);
    group('Business', business.main);
    group('Item', item.main);
    group('Order', order.main);
    group('Table', table.main);
    group('Type', type.main);
    group('Index Verification', index_verification.main);
  });
}
