import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/providers.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final isLoading = authState.isLoading;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 220,
          child: ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle();
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(isLoading ? 'Signing in...' : 'Sign in with Google'),
          ),
        ),
      ),
    );
  }
}
