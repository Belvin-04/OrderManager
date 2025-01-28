import "package:flutter/material.dart";
import 'package:order_manager/screens/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:order_manager/utils/ThemeProvider.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;
  bool _error = false;
  late FirebaseApp app;
  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      FirebaseApp app1 = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform
      );
      setState(() {
        _initialized = true;
        app = app1;
      });
    } catch (e) {
      print(e);
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_error) {
      //return SomethingWentWrong();
    }

    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return SplashScreen1(app);
  }
}

class SplashScreen1 extends StatefulWidget {
  final FirebaseApp app;
  SplashScreen1(this.app);

  @override
  _SplashScreen1State createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  ThemeProvider themeProvider = ThemeProvider();
  @override
  void initState() {
    super.initState();
    getCurrentTheme();
  }

  void getCurrentTheme() async {
    themeProvider.darkTheme =
        await themeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => themeProvider,
        builder: (context, _) {
          ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: "Order Manager",
            theme: MyThemes.lightTheme,
            darkTheme: MyThemes.darkTheme,
            themeMode: MyThemes.getTheme(themeProvider.isdarkMode),
            debugShowCheckedModeBanner: false,
            home: Material(
              child: HomePage(),
            ),
          );
        });
  }
}
