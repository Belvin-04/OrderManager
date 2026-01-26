import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';

class FakeTypeRepository implements TypeRepository {
  List<Type1> types = [];
  Type1? lastSavedType;
  Type1? lastDeletedType;

  @override
  Stream<List<Type1>> watchTypes() async* {
    yield types;
  }

  @override
  Future<void> saveType(Type1 type) async {
    lastSavedType = type;
    types.removeWhere((t) => t.id == type.id);
    types.add(type);
  }

  @override
  Future<void> deleteType(Type1 type) async {
    lastDeletedType = type;
    types.removeWhere((t) => t.id == type.id);
  }

  @override
  Future<Type1?> getType(String typeName) async {
    try {
      return types.firstWhere((t) => t.type == typeName);
    } catch (_) {
      return null;
    }
  }
}
