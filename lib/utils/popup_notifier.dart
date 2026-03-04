// ignore_for_file: avoid_setters_without_getters

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PopupNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  set open(int tableNo) {
    state = tableNo;
  }

  void close() {
    state = 0;
  }
}
