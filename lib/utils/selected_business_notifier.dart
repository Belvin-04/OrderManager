import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedBusinessNotifier extends Notifier<Business?> {
  static const _businessKey = "SelectedBusiness";

  @override
  Business? build() {
    _loadBusiness();
    return null;
  }

  Future<void> _loadBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBusiness = prefs.getString(_businessKey);
    if (savedBusiness != null) {
      state = Business.fromMap(jsonDecode(savedBusiness));
    }
  }

  Future<void> setSelectedBusiness(Business? business) async {
    final prefs = await SharedPreferences.getInstance();
    state = business;
    if (business != null) {
      await prefs.setString(_businessKey, jsonEncode(business.toMap()));
    } else {
      await prefs.remove(_businessKey);
    }
  }

  Future<void> clearBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    state = null;
    await prefs.remove(_businessKey);
  }
}
