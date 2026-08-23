import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:do_it_now/ui/ui_screens/pomodoro_screen/pomodoro_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../to_do_screen/to_do_screen.dart';

class TodoClockFlip extends StatefulWidget {
  final int currentThemeIndex;
  final Function(int) onThemeChanged;

  const TodoClockFlip({
    super.key,
    this.currentThemeIndex = 1,
    required this.onThemeChanged,
  });

  @override
  State<TodoClockFlip> createState() => _TodoClockFlipState();
}

class _TodoClockFlipState extends State<TodoClockFlip>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  late ClockTheme currentTheme;
  late int _localThemeIndex;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _localThemeIndex = widget.currentThemeIndex;
    currentTheme = ClockTheme.themes[_localThemeIndex];
    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page?.round() ?? 0;
      });
    });
    // Re-apply immersive after build so it sticks
    WidgetsBinding.instance.addPostFrameCallback((_) => _goImmersive());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-apply when app comes back to foreground
    if (state == AppLifecycleState.resumed) _goImmersive();
  }

  void _goImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Paint bars with theme color for the brief moment they appear on swipe
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: currentTheme.backgroundColor,
      systemNavigationBarColor: currentTheme.backgroundColor,
      statusBarIconBrightness:
          currentTheme.backgroundColor.computeLuminance() > 0.3
              ? Brightness.dark
              : Brightness.light,
      systemNavigationBarIconBrightness:
          currentTheme.backgroundColor.computeLuminance() > 0.3
              ? Brightness.dark
              : Brightness.light,
    ));
  }

  @override
  void didUpdateWidget(covariant TodoClockFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeIndex != widget.currentThemeIndex) {
      _localThemeIndex = widget.currentThemeIndex;
      setState(() => currentTheme = ClockTheme.themes[_localThemeIndex]);
      _goImmersive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      // These two lines make the body fill BEHIND the status bar and nav bar
      // so there is zero black strip anywhere.
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: PageView(
        controller: _pageController,
        physics: ClampingScrollPhysics(),
        children: [
          TodoPage(
            onFlip: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            theme: currentTheme,
            currentThemeIndex: _localThemeIndex,
            onThemeChanged: (int newIndex) {
              _localThemeIndex = newIndex;
              widget.onThemeChanged(newIndex);
              setState(() => currentTheme = ClockTheme.themes[newIndex]);
              _goImmersive();
            },
          ),
          RotatedBox(
            quarterTurns: 3,
            child: PomodoroTimer(theme: currentTheme),
          ),
        ],
      ),
    );
  }
}
