import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../clock_theme.dart';
import '../hive/task_model.dart';
import 'widget/input_task.dart';
import 'widget/task_list.dart';

class TodoPage extends StatefulWidget {
  final VoidCallback onFlip;
  final ClockTheme theme;
  const TodoPage({super.key, required this.onFlip, required this.theme});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');
  final TextEditingController _controller = TextEditingController();

  void _removeTask(int index) {
    _taskBox.deleteAt(index);
    setState(() {});
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
