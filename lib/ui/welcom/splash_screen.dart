import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  // Tekshirish, foydalanuvchi birinchi marta kelganmi
  _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirst = prefs.getBool('isFirstLaunch');
    await Future.delayed(
        Duration(seconds: 5)); // Splash ekrani 2 soniya davom etadi

    if (isFirst == null || isFirst) {
      Navigator.pushReplacementNamed(context, '/welcome'); // Welcome ekrani
    } else {
      Navigator.pushReplacementNamed(context, '/todo'); // Todo ekran
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/splash_animation.json', // Lottie animation file
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
