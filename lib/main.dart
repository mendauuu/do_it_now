import 'package:flutter/material.dart';

import 'musketeer_pomodoro/musketeer_pomodoro_screen.dart';

void main() {
  // Flutter's default error screen only shows readable text in debug
  // mode — in release/profile mode a build error is just a plain gray
  // box, which is indistinguishable from "nothing rendered". This
  // makes any widget-build error show up as plain text on screen
  // instead, regardless of build mode, so a screenshot of it is
  // enough to diagnose — no terminal access needed.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE0E0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.black, fontSize: 13),
          ),
        ),
      ),
    );
  };

  runApp(const MusketeerTestApp());
}

class MusketeerTestApp extends StatelessWidget {
  const MusketeerTestApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Musketeer Focus',
        home: MusketeerAnimationScreen(),
      );
}
//google

// import 'dart:async';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const AralTestApp());
// }

// class AralTestApp extends StatelessWidget {
//   const AralTestApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'ARAL Pixel Animation',
//       home: AralIdleTestScreen(),
//     );
//   }
// }

// class AralIdleTestScreen extends StatefulWidget {
//   const AralIdleTestScreen({super.key});

//   @override
//   State<AralIdleTestScreen> createState() => _AralIdleTestScreenState();
// }

// class _AralIdleTestScreenState extends State<AralIdleTestScreen> {
//   ui.Image? spriteSheet;
//   int currentFrame = 0;
//   Timer? timer;

//   @override
//   void initState() {
//     super.initState();
//     _loadSpriteSheet();
//   }

//   // 1. Rasmni xotiraga to'liq yuklab olish
//   Future<void> _loadSpriteSheet() async {
//     final ImageProvider provider =
//         const AssetImage('assets/aral/aral_idle_4frame_64x64.png');
//     final ImageStream stream = provider.resolve(ImageConfiguration.empty);

//     stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
//       if (mounted) {
//         setState(() {
//           spriteSheet = info.image;
//         });
//         _startAnimation();
//       }
//     }));
//   }

//   // 2. Taymer orqali kadrlarni o'zgartirish
//   void _startAnimation() {
//     timer = Timer.periodic(const Duration(milliseconds: 150), (t) {
//       if (mounted) {
//         setState(() {
//           currentFrame = (currentFrame + 1) % 4; // 4 ta kadr: 0, 1, 2, 3
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4E8D0),
//       body: Center(
//         child: spriteSheet == null
//             ? const CircularProgressIndicator() // Rasm yuklanguncha kutish
//             : CustomPaint(
//                 size: const Size(256, 256), // Ekrandagi yakuniy o'lchami
//                 painter: SpritePainter(
//                   image: spriteSheet!,
//                   frame: currentFrame,
//                 ),
//               ),
//       ),
//     );
//   }
// }

// // 3. Rasmdan kadrni aniq kesib olib chizuvchi maxsus klass
// class SpritePainter extends CustomPainter {
//   final ui.Image image;
//   final int frame;

//   SpritePainter({required this.image, required this.frame});

//   @override
//   void paint(Canvas canvas, Size size) {
//     // 1. Rasmning haqiqiy kengligini 4 ta kadrga bo'lib, 1 ta kadr o'lchamini aniqlaymiz
//     final double frameWidth = image.width / 4;
//     final double frameHeight =
//         image.height.toDouble(); // Rasmning asl balandligi

//     // 2. Rasmdan joriy kadrni aniq koordinata bo'yicha kesib olish (Source)
//     final Rect src =
//         Rect.fromLTWH(frame * frameWidth, 0, frameWidth, frameHeight);

//     // 3. Ekranga chiziladigan joy (Destination) - siz bergan Size(256, 256) ichiga chizadi
//     final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);

//     final Paint paint = Paint()
//       ..filterQuality = ui.FilterQuality.none; // Pixel-art o'tkir bo'lib qoladi

//     // Rasmni chizish
//     canvas.drawImageRect(image, src, dst, paint);
//   }

//   @override
//   bool shouldRepaint(covariant SpritePainter oldDelegate) {
//     return oldDelegate.frame != frame || oldDelegate.image != image;
//   }
// }





// Pomodoro 

// import 'package:do_it_now/ui/hive/task_model.dart';
// import 'package:do_it_now/ui/ui_screens/home_main_screen/home_pager.dart';
// import 'package:do_it_now/ui/welcom/splash_screen.dart';
// import 'package:do_it_now/ui/welcom/welcom_screen.dart';
// import 'package:do_it_now/ui/theme/clock_theme.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:do_it_now/data/database/database_initializer.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'blocs/task_bloc.dart';
// import 'blocs/stats_bloc.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
//     SystemUiOverlay.bottom,
//   ]);
//   await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

//   await Hive.initFlutter();
//   Hive.registerAdapter(TaskModelAdapter());
//   await Hive.openBox<TaskModel>('tasks');
//   // SQL
//   await DatabaseInitializer.initialize();
//   await _migrateHiveToSQLIfNeeded();

//   runApp(
//     MultiBlocProvider(
//       providers: [
//         BlocProvider<TaskBloc>(create: (_) => TaskBloc()..add(LoadTasks())),
//         BlocProvider<StatsBloc>(create: (_) => StatsBloc()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// Future<void> _migrateHiveToSQLIfNeeded() async {
//   final prefs = await SharedPreferences.getInstance();
//   if (prefs.getBool('hive_migration_done') == true) return;
//   try {
//     final box = Hive.box<TaskModel>('tasks');
//     if (box.isNotEmpty) {
//       for (final task in box.values) {
//         if (task.sqlId == null) {
//           await DatabaseInitializer.createTask(
//             title: task.title,
//             description: task.description,
//             priority: task.priority,
//             category: task.category,
//             dueDate: task.dueDate,
//           );
//         }
//       }
//       await box.clear();
//     }
//     await prefs.setBool('hive_migration_done', true);
//   } catch (e) {
//     debugPrint('Hive migration error: $e');
//   }
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   int _themeIndex = 1;

//   @override
//   void initState() {
//     super.initState();
//     _loadTheme();
//   }

//   Future<void> _loadTheme() async {
//     final prefs = await SharedPreferences.getInstance();
//     final idx = prefs.getInt('selectedThemeIndex') ?? 1;
//     setState(() => _themeIndex = idx);
//     _applyBarsColor(idx);
//   }

//   Future<void> _changeTheme(int index) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('selectedThemeIndex', index);
//     setState(() => _themeIndex = index);
//     _applyBarsColor(index);
//   }

//   // When bars briefly appear on swipe, paint them with the theme color
//   // so there is no black flash.
//   void _applyBarsColor(int index) {
//     final bg = ClockTheme.themes[index].backgroundColor;
//     // Determine icon brightness based on background luminance
//     final luminance = bg.computeLuminance();
//     final brightness = luminance > 0.3 ? Brightness.dark : Brightness.light;

//     SystemChrome.setSystemUIOverlayStyle(
//       const SystemUiOverlayStyle(
//         statusBarColor:
//             Colors.transparent, // Makes status bar match your background color
//         statusBarIconBrightness: Brightness
//             .dark, // Dark icons (use Brightness.light for white text/icons)
//         statusBarBrightness: Brightness
//             .light, // Required styling configuration for iOS status bar
//         systemNavigationBarColor:
//             Colors.white, // Sets the bottom system navigation bar color
//         systemNavigationBarIconBrightness: Brightness.dark,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = ClockTheme.themes[_themeIndex];
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Do It Now',
//       // builder wraps every route — re-applies the color whenever navigation
//       // happens (route transitions can reset the overlay style to default).
//       builder: (context, child) {
//         _applyBarsColor(_themeIndex);
//         return child!;
//       },
//       theme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: t.backgroundColor,
//         primaryColor: t.hourHandColor,
//         cardColor: t.secondaryBackgroundColor,
//         // canvasColor is the Android window background color in Flutter's
//         // Material layer — must match theme so nothing flashes black.
//         canvasColor: t.backgroundColor,
//         dialogBackgroundColor: t.backgroundColor,
//         appBarTheme: AppBarTheme(
//           backgroundColor: t.backgroundColor,
//           elevation: 0,
//         ),
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (_) => SplashScreen(),
//         '/welcome': (_) => const WelcomeScreen(),
//         '/todo': (_) => TodoClockFlip(
//               currentThemeIndex: _themeIndex,
//               onThemeChanged: _changeTheme,
//             ),
//       },
//     );
//   }
// }
