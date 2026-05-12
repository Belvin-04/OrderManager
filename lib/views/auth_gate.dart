import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/providers/employee_provider.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/views/business/businesses_page.dart';
import 'login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        return FutureBuilder(
          future: ref.watch(appUserRepositoryProvider).queryById(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text(snapshot.error.toString())),
              );
            }
            final appUser = snapshot.data;
            if (appUser == null) {
              final AppUser appUser = AppUser(
                id: user.uid,
                email: user.email!,
                name: user.displayName!,
              );
              ref.read(employeeViewModelProvider.notifier).saveUser(appUser);
            }
            return const BusinessGate();
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }
}
