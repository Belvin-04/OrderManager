import 'package:order_manager/models/type.dart';
import 'package:order_manager/viewmodels/types_viewmodel.dart';

class FakeTypesViewModel extends TypesViewModel {
  Type1? deletedType;
  Type1? savedType;

  @override
  Future<void> deleteType(Type1 type) async {
    deletedType = type;
  }

  @override
  Future<void> saveType(Type1 type) async {
    savedType = type;
  }
}
