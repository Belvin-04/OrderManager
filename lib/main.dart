import "package:flutter/material.dart";
import 'package:order_manager/screens/HomePage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

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

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch(e) {
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
    if(_error) {
      //return SomethingWentWrong();
    }

    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      //return Loading();
    }

    return SplashScreen1();
  }
}


class SplashScreen1 extends StatelessWidget {
  const SplashScreen1({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Order Manager",
      theme: ThemeData(
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
        textSelectionColor: Colors.white,
        cardColor: Color(0xFF151515),
        canvasColor: Colors.black,
        brightness: Brightness.dark,
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
            colorScheme: ColorScheme.dark()),
        appBarTheme: AppBarTheme(
          elevation: 0.0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Material(
        child: HomePage(),
      ),
    );
  }
}


