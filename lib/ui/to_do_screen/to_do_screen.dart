import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_colors.dart';
import '../hive/task_model.dart';
import 'widget/input_task.dart';
import 'widget/task_list.dart';

class TodoPage extends StatefulWidget {
  final VoidCallback onFlip;
  const TodoPage({super.key, required this.onFlip});

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
  Widget build(BuildContext context) {
    return Container(
      height: 600, // Fixed height for FlipCard
      width: 360,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Do it now", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: widget.onFlip,
              icon: const Icon(Icons.access_time, color: Colors.white),
            ),
          ],
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
