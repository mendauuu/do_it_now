import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  // Welcome ekrani ko‘rsatganidan keyin
  _setFirstLaunchDone() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstLaunch', false);
    Navigator.pushReplacementNamed(context, '/todo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB0C4DE), // Powder Blue background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animatsiyasi
              Lottie.asset(
                'assets/welcome_animation.json', // Animatsiya fayli
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20), // Text va button orasida bo'sh joy
              Text(
                'Welcome to the App!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20), // Buton va matn orasida bo'sh joy
              ElevatedButton(
                onPressed: _setFirstLaunchDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Color(0xFF4A90E2), // Button rangi (masalan, ko'k)
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5, // Buttonni ko'tarish
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
