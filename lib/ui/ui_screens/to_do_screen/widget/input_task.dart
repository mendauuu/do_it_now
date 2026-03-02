import 'package:do_it_now/ui/ui_screens/to_do_screen/widget/task_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:do_it_now/data/database/database_initializer.dart';
import '../../../theme/clock_theme.dart';

class InputTask extends StatefulWidget {
  final TextEditingController controller;
  final ClockTheme theme;
  const InputTask(this.controller, {super.key, required this.theme});

  @override
  State<InputTask> createState() => _InputTaskState();
}

class _InputTaskState extends State<InputTask> {
  // Using DatabaseInitializer to create tasks (will write to both Hive and SQL)

  void _openTaskForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.theme.secondaryBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskFormSheet(onAddTask: _addTask, theme: widget.theme),
    );
  }

  void _addTask(String title, String description, int priority) async {
    await DatabaseInitializer.createTask(
      title: title,
      description: description,
      priority: priority,
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
          color: widget.theme.inputFieldColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.theme.borderColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color:
                  widget.theme.shadowColor?.withOpacity(0.2) ?? Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.theme.buttonColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_circle_outline,
                  size: 24, color: widget.theme.buttonColor),
            ),
            SizedBox(width: 12),
            Text(
              "Add new task",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
