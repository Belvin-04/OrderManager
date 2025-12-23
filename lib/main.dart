import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/utils/theme_provider.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/firebase_initializer.dart';

final firebaseInitProvider = FutureProvider<FirebaseApp>((ref) async {
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseInitializer.enableOfflineFeatures();
  return app;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseState = ref.watch(firebaseInitProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: "Order Manager",
      debugShowCheckedModeBanner: false,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      themeMode: themeMode,
      home: firebaseState.when(
        loading: () => const SplashScreen(),
        error: (e, _) => ErrorScreen(error: e.toString()),
        data: (_) => HomePage(),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Error initializing app:\n$error")),
    );
  }
}
