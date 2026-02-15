import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/ui/to_do_screen/home_pager.dart';
import 'package:do_it_now/ui/welcom/splash_screen.dart';
import 'package:do_it_now/ui/welcom/welcom_screen.dart';
import 'package:do_it_now/ui/clock_theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox<TaskModel>('tasks');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedThemeIndex = 1; // Dark theme by default

  void _changeTheme(int index) {
    setState(() {
      _selectedThemeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = ClockTheme.themes[_selectedThemeIndex];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // showPerformanceOverlay: true,
      // 🌙 DARK THEME using ClockTheme
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: selectedTheme.backgroundColor,
        primaryColor: selectedTheme.hourHandColor,
        colorScheme: ColorScheme.dark(
          background: selectedTheme.backgroundColor,
          surface: selectedTheme.secondaryBackgroundColor,
          primary: selectedTheme.hourHandColor,
          secondary: selectedTheme.secondHandColor,
        ),
        cardColor: selectedTheme.secondaryBackgroundColor,
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: selectedTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: selectedTheme.secondaryTextColor,
            fontSize: 16,
          ),
        ),
      ),

      title: 'To-Do App',
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/todo': (context) => TodoClockFlip(
              currentThemeIndex: _selectedThemeIndex,
              onThemeChanged: _changeTheme,
            ),
      },
    );
  }
}
