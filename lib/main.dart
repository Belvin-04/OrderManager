import "package:flutter/material.dart";
import 'package:order_manager/screens/HomePage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:order_manager/utils/ThemeProvider.dart';
import 'dart:async';

import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;
  bool _error = false;
  FirebaseApp app;
  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      FirebaseApp app1 = await Firebase.initializeApp();
      setState(() {
        _initialized = true;
        app = app1;
      });
    } catch (e) {
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
            /*theme: ThemeData(
          primarySwatch: Colors.red,
          primaryColor: Colors.black,
          backgroundColor: Colors.black,
          indicatorColor: Color(0xff0E1D36),
          buttonColor: Color(0xff3B3B3B),
          hintColor: Color(0xffffffff),
          highlightColor: Color(0xff372901),
          hoverColor: Color(0xff3A3A3B),
          focusColor: Color(0xffffffff),
          disabledColor: Colors.grey,
          textSelectionTheme:
              TextSelectionThemeData(selectionColor: Colors.black),
          cardColor: Color(0xFF151515),
          canvasColor: Colors.black,
          brightness: Brightness.dark,
          buttonTheme: Theme.of(context)
              .buttonTheme
              .copyWith(colorScheme: ColorScheme.dark()),
          appBarTheme: AppBarTheme(
            elevation: 0.0,
          ),
        ),*/
            debugShowCheckedModeBanner: false,
            home: Material(
              child: HomePage(this.widget.app),
            ),
          );
        });
  }
}
