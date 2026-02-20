import 'package:do_it_now/ui/clock_theme.dart';
import 'package:do_it_now/ui/flip_clock_widget.dart';
import 'package:do_it_now/ui/pomodoro_timer.dart';
import 'package:flutter/material.dart';

import 'to_do_screen.dart';

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
    currentTheme = ClockTheme.themes[widget.currentThemeIndex];

    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page?.round() ?? 0;
      });
    });
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
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: currentTheme.secondHandColor,
      //   onPressed: _showThemeSettings,
      //   child: Icon(
      //     Icons.palette,
      //     color: currentTheme.backgroundColor,
      //   ),
      // ),

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
            onThemeChanged: (int p1) {},
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
