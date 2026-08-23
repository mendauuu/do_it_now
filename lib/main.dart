import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/ui/ui_screens/home_main_screen/home_pager.dart';
import 'package:do_it_now/ui/welcom/splash_screen.dart';
import 'package:do_it_now/ui/welcom/welcom_screen.dart';
import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:do_it_now/data/database/database_initializer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/task_bloc.dart';
import 'blocs/stats_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
    SystemUiOverlay.bottom,
  ]);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox<TaskModel>('tasks');
  // SQL
  await DatabaseInitializer.initialize();
  await _migrateHiveToSQLIfNeeded();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<TaskBloc>(create: (_) => TaskBloc()..add(LoadTasks())),
        BlocProvider<StatsBloc>(create: (_) => StatsBloc()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _migrateHiveToSQLIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('hive_migration_done') == true) return;
  try {
    final box = Hive.box<TaskModel>('tasks');
    if (box.isNotEmpty) {
      for (final task in box.values) {
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
    final idx = prefs.getInt('selectedThemeIndex') ?? 1;
    setState(() => _themeIndex = idx);
    _applyBarsColor(idx);
  }

  Future<void> _changeTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedThemeIndex', index);
    setState(() => _themeIndex = index);
    _applyBarsColor(index);
  }

  // When bars briefly appear on swipe, paint them with the theme color
  // so there is no black flash.
  void _applyBarsColor(int index) {
    final bg = ClockTheme.themes[index].backgroundColor;
    // Determine icon brightness based on background luminance
    final luminance = bg.computeLuminance();
    final brightness = luminance > 0.3 ? Brightness.dark : Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent, // Makes status bar match your background color
        statusBarIconBrightness: Brightness
            .dark, // Dark icons (use Brightness.light for white text/icons)
        statusBarBrightness: Brightness
            .light, // Required styling configuration for iOS status bar
        systemNavigationBarColor:
            Colors.white, // Sets the bottom system navigation bar color
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ClockTheme.themes[_themeIndex];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Do It Now',
      // builder wraps every route — re-applies the color whenever navigation
      // happens (route transitions can reset the overlay style to default).
      builder: (context, child) {
        _applyBarsColor(_themeIndex);
        return child!;
      },
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: t.backgroundColor,
        primaryColor: t.hourHandColor,
        cardColor: t.secondaryBackgroundColor,
        // canvasColor is the Android window background color in Flutter's
        // Material layer — must match theme so nothing flashes black.
        canvasColor: t.backgroundColor,
        dialogBackgroundColor: t.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: t.backgroundColor,
          elevation: 0,
        ),
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
