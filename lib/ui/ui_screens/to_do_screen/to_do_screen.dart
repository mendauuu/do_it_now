import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/clock_theme.dart';
import 'package:do_it_now/data/database/database_initializer.dart';
import 'widget/input_task.dart';
import 'widget/task_list.dart';
import 'pages/settings_page.dart';

class TodoPage extends StatefulWidget {
  final VoidCallback onFlip;
  final ClockTheme theme;
  final int currentThemeIndex;
  final Function(int) onThemeChanged;
  const TodoPage({
    super.key,
    required this.onFlip,
    required this.theme,
    this.currentThemeIndex = 1,
    required this.onThemeChanged,
  });

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  final PageController _pageController = PageController();
  late ClockTheme currentTheme;

  @override
  void initState() {
    super.initState();
    currentTheme = ClockTheme.themes[widget.currentThemeIndex];

    _pageController.addListener(() {
      setState(() {
        _pageController.page?.round() ?? 0;
      });
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _removeTask(int index) async {
    await DatabaseInitializer.deleteTask(index);
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          currentThemeIndex: widget.currentThemeIndex,
          onThemeChanged: widget.onThemeChanged,
          theme: currentTheme,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(TodoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if the provided theme or theme index changed, update local currentTheme
    if (oldWidget.theme != widget.theme ||
        oldWidget.currentThemeIndex != widget.currentThemeIndex) {
      currentTheme = ClockTheme.themes[widget.currentThemeIndex];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      width: 360,
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
      ),
      child: Scaffold(
        backgroundColor: widget.theme.backgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.theme.borderColor.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Do it now",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openSettings,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.9, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              InputTask(_controller, theme: widget.theme),
              const SizedBox(height: 16),
              Flexible(
                child: TaskListWidget(
                  removeTaskCallback: _removeTask,
                  theme: widget.theme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
