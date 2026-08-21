import 'dart:ui';

import 'package:do_it_now/ui/ui_screens/to_do_screen/widget/completed_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/clock_theme.dart';
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
  late ClockTheme currentTheme;

  @override
  void initState() {
    super.initState();
    currentTheme = ClockTheme.themes[widget.currentThemeIndex];
    // DO NOT set immersive here — it overrides the cutout-safe setup in main()
    // and causes the camera area to go black.
    // Orientation is already locked to portrait in main().
  }

  @override
  void dispose() {
    _controller.dispose();
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

  void _openCompletedTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompletedTasksPage(theme: widget.theme),
      ),
    );
  }

  @override
  void didUpdateWidget(TodoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme ||
        oldWidget.currentThemeIndex != widget.currentThemeIndex) {
      currentTheme = ClockTheme.themes[widget.currentThemeIndex];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: widget.theme.borderColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Do it now',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.0,
                          color: widget.theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stay focused',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: widget.theme.secondaryTextColor,
                          letterSpacing: 0.3,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openCompletedTasks,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: widget.theme.buttonColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openSettings,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.settings_rounded,
                              color: widget.theme.buttonColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            InputTask(theme: widget.theme),
            const SizedBox(height: 12),
            Flexible(
              child: TaskListWidget(theme: widget.theme),
            ),
          ],
        ),
      ),
    );
  }
}
