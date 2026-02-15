import 'package:do_it_now/ui/clock_theme.dart';
import 'package:do_it_now/ui/flip_clock_widget.dart';
import 'package:do_it_now/ui/pomodoro_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    currentTheme = ClockTheme.themes[widget.currentThemeIndex];

    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page?.round() ?? 0;
      });
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void didUpdateWidget(TodoClockFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeIndex != widget.currentThemeIndex) {
      setState(() {
        currentTheme = ClockTheme.themes[widget.currentThemeIndex];
      });
    }
  }

  void _showThemeSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.secondaryBackgroundColor,
        title: Text(
          'Select Theme',
          style: TextStyle(color: currentTheme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            ClockTheme.themes.length,
            (index) => GestureDetector(
              onTap: () {
                widget.onThemeChanged(index);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.currentThemeIndex == index
                      ? currentTheme.hourHandColor
                      : currentTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: currentTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ClockTheme.themes[index].backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: ClockTheme.themes[index].borderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ClockTheme.themes[index].name,
                      style: TextStyle(
                        color: currentTheme.textColor,
                        fontWeight: widget.currentThemeIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      floatingActionButton: FloatingActionButton(
        // Use the theme's bright accent color
        backgroundColor: currentTheme.secondHandColor,
        onPressed: _showThemeSettings,
        // Use the deep dark background color for the icon to make it "cut out"
        child: Icon(
          Icons.palette,
          color: currentTheme.backgroundColor,
        ),
      ),
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
