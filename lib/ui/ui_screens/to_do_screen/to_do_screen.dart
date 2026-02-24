import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/clock_theme.dart';
import '../../hive/task_model.dart';
import 'widget/input_task.dart';
import 'widget/task_list.dart';

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
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');
  final TextEditingController _controller = TextEditingController();
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

  void _removeTask(int index) {
    _taskBox.deleteAt(index);
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
  void didUpdateWidget(TodoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600, // Fixed height for FlipCard
      width: 360,
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        // borderRadius: BorderRadius.circular(24),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.4),
        //     blurRadius: 20,
        //     offset: const Offset(0, 10),
        //   ),
        // ],
      ),
      child: Scaffold(
        backgroundColor: widget.theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // elevation: 0,

          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: GestureDetector(
                onTap: _showThemeSettings,
                child: Icon(
                  Icons.palette,
                  color: widget.theme.secondHandColor,
                ),
              ),
            ),
          ],
          title: Text(
            "Do it now",
            style: TextStyle(color: widget.theme.textColor),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              InputTask(_controller),
              const SizedBox(height: 16),
              Flexible(
                child: TaskListWidget(
                  taskBox: _taskBox,
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
