import 'package:do_it_now/ui/ui_screens/to_do_screen/widget/task_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:do_it_now/ui/theme/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:do_it_now/ui/hive/task_model.dart';

class InputTask extends StatefulWidget {
  final TextEditingController controller;
  const InputTask(this.controller, {super.key});

  @override
  State<InputTask> createState() => _InputTaskState();
}

class _InputTaskState extends State<InputTask> {
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');

  void _openTaskForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskFormSheet(onAddTask: _addTask),
    );
  }

  void _addTask(String title, String description, int priority) {
    _taskBox.add(
      TaskModel(
        title: title,
        description: description,
        date: DateTime.now(),
        priority: priority,
        isDone: false,
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openTaskForm,
      child: Container(
        padding: EdgeInsets.all(14),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 28, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              "Add new task",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
