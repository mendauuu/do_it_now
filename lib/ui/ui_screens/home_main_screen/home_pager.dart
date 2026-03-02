import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:do_it_now/ui/ui_screens/time_screen/flip_clock_widget.dart';
import 'package:do_it_now/ui/ui_screens/pomodoro_screen/pomodoro_timer.dart';
import 'package:flutter/material.dart';

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

class _TodoClockFlipState extends State<TodoClockFlip> {
  final PageController _pageController = PageController();
  late ClockTheme currentTheme;
  // keep track of selected theme locally so child widgets can update immediately
  late int _localThemeIndex;
  int _currentPageIndex = 0;

  int get currentPageIndex => _currentPageIndex;
  set currentPageIndex(int value) {
    setState(() {
      _currentPageIndex = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _localThemeIndex = widget.currentThemeIndex;
    currentTheme = ClockTheme.themes[_localThemeIndex];

    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void didUpdateWidget(covariant TodoClockFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeIndex != widget.currentThemeIndex) {
      // parent changed the theme index (maybe via navigation or external)
      _localThemeIndex = widget.currentThemeIndex;
      setState(() {
        currentTheme = ClockTheme.themes[_localThemeIndex];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          TodoPage(
            onFlip: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            theme: currentTheme,
            currentThemeIndex: _localThemeIndex,
            onThemeChanged: (int newIndex) {
              _localThemeIndex = newIndex;
              widget.onThemeChanged(newIndex);
              setState(() {
                currentTheme = ClockTheme.themes[newIndex];
              });
            },
          ),
          RotatedBox(
            quarterTurns: 3,
            child: PomodoroTimer(
              theme: currentTheme,
            ),
          ),
          RotatedBox(
            quarterTurns: 3,
            child: FlipClockWidget(
              theme: currentTheme,
              pageController: _pageController,
              currentTheme: currentTheme,
            ),
          ),
        ],
      ),
    );
  }
}
