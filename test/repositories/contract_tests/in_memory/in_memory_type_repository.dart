import 'dart:async';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';

class InMemoryTypeRepository implements TypeRepository {
  final Map<String, Type1> _byId = {};
  late final StreamController<List<Type1>> _controller =
      StreamController<List<Type1>>.broadcast(
        onListen: () {
          _controller.add(_byId.values.toList());
        },
      );

  void _emit() {
    _controller.add(_byId.values.toList());
  }

  @override
  Stream<List<Type1>> watchTypes() => _controller.stream;

  @override
  Future<void> saveType(Type1 type) async {
    final existing = _byId.values.where((t) => t.type == type.type).toList();

    final String id;
    if (existing.isNotEmpty) {
      id = existing.first.id;
    } else if (type.id.isNotEmpty) {
      id = type.id;
    } else {
      id = 'type_${_byId.length + 1}';
    }

    _byId[id] = type.copyWith(id: id);

    _emit();
  }

  @override
  Future<Type1?> getType(String typeName) async {
    try {
      return _byId.values.firstWhere((t) => t.type == typeName);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteType(Type1 type) async {
    _byId.remove(type.id);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
