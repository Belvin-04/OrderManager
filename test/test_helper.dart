import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/abstract_files/app_user_repository.dart';
import 'package:order_manager/repositories/abstract_files/business_repository.dart';
import 'package:order_manager/repositories/abstract_files/items_repository.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/app_user_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/business_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/item_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/order_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/table_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/type_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';
import 'package:order_manager/viewmodels/types_viewmodel.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockTableRepository extends Mock implements TableRepository {}

class MockItemsRepository extends Mock implements ItemsRepository {}

class MockTypeRepository extends Mock implements TypeRepository {}

class MockBusinessRepository extends Mock implements BusinessRepository {}

class MockAppUserRepository extends Mock implements AppUserRepository {}

class MockAppUserRemoteDataSource extends Mock
    implements AppUserRemoteDataSource {}

class MockBusinessRemoteDataSource extends Mock
    implements BusinessRemoteDataSource {}

class MockItemRemoteDataSource extends Mock implements ItemRemoteDataSource {}

class MockOrderRemoteDataSource extends Mock implements OrderRemoteDataSource {}

class MockTableRemoteDataSource extends Mock implements TableRemoteDataSource {}

class MockTypeRemoteDataSource extends Mock implements TypeRemoteDataSource {}

class MockTypesViewModel extends Mock implements TypesViewModel {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockAuthRepository extends Mock implements FirebaseAuth {}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_uid123';

  @override
  String get email => 'test@example.com';

  @override
  String get displayName => 'Test User';
}

class FakeUserCredential extends Fake implements UserCredential {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class FakeOrder extends Fake implements Order {}

class FakeTable1 extends Fake implements Table1 {}

class FakeBusiness extends Fake implements Business {}

class FakeAuthCredential extends Fake implements AuthCredential {}

class FakeAppUser extends Fake implements AppUser {}

class FakeBusinessEmployee extends Fake implements BusinessEmployee {}

class FakeItem extends Fake implements Item {}

class FakeType1 extends Fake implements Type1 {}

final testTable = Table1(id: 't', tableNo: 1);

Order baseOrder({
  String businessId = 'biz-1',
  String id = '',
  int quantity = 1,
  String status = 'pending',
  int amount = 100,
  int splitNo = 0,
  Table1? table,
  Type1? type,
  Item? item,
}) {
  return Order(
    id: id,
    quantity: quantity,
    item: item ?? Item(id: 'i1', name: 'Burger', price: 100),
    type: type ?? Type1(id: 't1', type: 'None', price: 0),
    table:
        table?.copyWith(splitNo: splitNo) ??
        testTable.copyWith(splitNo: splitNo),
    status: status,
    note: '',
    amount: amount,
  );
}

void registerCommonFallbacks() {
  registerFallbackValue(FakeOrder());
  registerFallbackValue(FakeTable1());
}

void stubOrderRepoStatus(
  MockOrderRepository orderRepo, {
  bool pending = false,
  bool completed = false,
  bool canceled = false,
}) {
  when(
    () => orderRepo.watchPendingOrdersExist(any()),
  ).thenAnswer((_) => Stream.value(pending));
  when(
    () => orderRepo.watchCompletedOrdersExist(any()),
  ).thenAnswer((_) => Stream.value(completed));
  when(
    () => orderRepo.watchCanceledOrdersExist(any()),
  ).thenAnswer((_) => Stream.value(canceled));
}
