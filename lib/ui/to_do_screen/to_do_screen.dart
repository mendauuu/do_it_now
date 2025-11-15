import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/ui/to_do_screen/widget/input_task.dart';
import 'package:do_it_now/ui/to_do_screen/widget/task_list.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');

  void _removeTask(int index) {
    _taskBox.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Do it now", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF789ABE),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputTask(_controller),
            SizedBox(height: 20),
            TaskListWidget(taskBox: _taskBox, removeTaskCallback: _removeTask)
          ],
        ),
      ),
    );
  }
}
