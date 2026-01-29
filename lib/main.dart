import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/ui/to_do_screen/home_pager.dart';
import 'package:do_it_now/ui/welcom/splash_screen.dart';
import 'package:do_it_now/ui/welcom/welcom_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive init
  await Hive.initFlutter();

  Hive.registerAdapter(TaskModelAdapter()); // <-- MUHIM

  await Hive.openBox<TaskModel>('tasks'); // <-- Modelga mos box
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFB0C4DE), // Powder Blue
        scaffoldBackgroundColor: Color(0xFFB0C4DE), // Powder Blue Background
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
      title: 'To-Do App',
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/todo': (context) => TodoClockFlip(), // Todo screen uchun UI
      },
    );
  }
}
