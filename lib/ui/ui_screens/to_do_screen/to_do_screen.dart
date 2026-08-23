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
  late ClockTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = ClockTheme.themes[widget.currentThemeIndex];
    // Do NOT call setEnabledSystemUIMode here — it overrides the immersive
    // mode set by the parent and causes the black strip to reappear.
  }

  @override
  void didUpdateWidget(TodoPage old) {
    super.didUpdateWidget(old);
    if (old.currentThemeIndex != widget.currentThemeIndex ||
        old.theme != widget.theme) {
      setState(() => _theme = ClockTheme.themes[widget.currentThemeIndex]);
    }
  }

  void _openSettings() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsPage(
            currentThemeIndex: widget.currentThemeIndex,
            onThemeChanged: widget.onThemeChanged,
            theme: _theme,
          ),
        ),
      );

  void _openCompleted() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompletedTasksPage(theme: widget.theme),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // How tall the status bar is — we pad the AppBar content down by this
    // so text doesn't sit behind the status bar, while the color fills the
    // full area including behind the status bar.
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _theme.backgroundColor,
      // Fill behind status bar AND behind bottom nav bar
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        // Add topPad so the AppBar is tall enough to cover the status bar area
        preferredSize: Size.fromHeight(70 + topPad),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              // Top padding pushes content below the status bar
              padding: EdgeInsets.only(
                top: topPad + 10,
                left: 20,
                right: 20,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                // Same as theme background — no black showing through
                color: _theme.backgroundColor.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: _theme.borderColor.withValues(alpha: 0.15),
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
                          color: _theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stay focused',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: _theme.secondaryTextColor,
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
                          onTap: _openCompleted,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.check_circle_outline,
                                color: _theme.buttonColor, size: 22),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openSettings,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.settings_rounded,
                                color: _theme.buttonColor, size: 22),
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
        // Top padding = AppBar height + status bar, bottom = nav bar height
        padding: EdgeInsets.only(
          top: 70 + topPad + 12,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          children: [
            InputTask(theme: _theme),
            const SizedBox(height: 12),
            Flexible(child: TaskListWidget(theme: _theme)),
          ],
        ),
      ),
    );
  }
}
