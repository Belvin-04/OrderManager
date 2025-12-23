import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/providers/providers.dart';

final itemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.read(itemRepositoryProvider).watchItems();
});
