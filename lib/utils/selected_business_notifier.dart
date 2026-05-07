import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business.dart';

class SelectedBusinessNotifier extends Notifier<Business?> {
  @override
  Business? build() => null;

  Business? get selectedBusiness => state;
  set selectedBusiness(Business? business) => state = business;

  void clearBusiness() {
    selectedBusiness = null;
  }
}
