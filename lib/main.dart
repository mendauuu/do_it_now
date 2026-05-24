import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/ui/ui_screens/home_main_screen/home_pager.dart';
import 'package:do_it_now/ui/welcom/splash_screen.dart';
import 'package:do_it_now/ui/welcom/welcom_screen.dart';
import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:do_it_now/data/database/database_initializer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/task_bloc.dart';
import 'blocs/stats_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive — kept only to migrate any existing data from old installs.
  // New installs: the box will be empty and no migration runs.
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox<TaskModel>('tasks');

  // SQL — primary storage
  await DatabaseInitializer.initialize();

  // One-time migration: copy any old Hive tasks into SQL then clear the box.
  await _migrateHiveToSQLIfNeeded();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<TaskBloc>(
          create: (_) => TaskBloc()..add(LoadTasks()),
        ),
        BlocProvider<StatsBloc>(
          create: (_) => StatsBloc(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// One-time migration. After it runs it sets a flag so it never runs again.
Future<void> _migrateHiveToSQLIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('hive_migration_done') == true) return;

  try {
    final box = Hive.box<TaskModel>('tasks');
    if (box.isNotEmpty) {
      for (final task in box.values) {
        // Only migrate tasks that don't already have a SQL id
        if (task.sqlId == null) {
          await DatabaseInitializer.createTask(
            title: task.title,
            description: task.description,
            priority: task.priority,
            category: task.category,
            dueDate: task.dueDate,
          );
        }
      }
      await box.clear();
    }
    await prefs.setBool('hive_migration_done', true);
  } catch (e) {
    // Non-fatal — user keeps their data in SQL from next launch
    debugPrint('Hive migration error: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _themeIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _themeIndex = prefs.getInt('selectedThemeIndex') ?? 1);
  }

  Future<void> _changeTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedThemeIndex', index);
    setState(() => _themeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClockTheme.themes[_themeIndex];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Do It Now',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: theme.backgroundColor,
        primaryColor: theme.hourHandColor,
        cardColor: theme.secondaryBackgroundColor,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => SplashScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/todo': (_) => TodoClockFlip(
              currentThemeIndex: _themeIndex,
              onThemeChanged: _changeTheme,
            ),
      },
    );
  }
}
