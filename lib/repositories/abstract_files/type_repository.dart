import 'package:order_manager/models/type.dart';

abstract class TypeRepository {
  Stream<List<Type1>> watchTypes();
  Future<Type1?> getType(String typeName);
  Future<void> saveType(Type1 type);
  Future<void> deleteType(Type1 type);
  Future<Type1?> getTypeById(String id);
}
