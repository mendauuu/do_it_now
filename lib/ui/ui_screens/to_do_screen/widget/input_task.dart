import 'package:do_it_now/ui/ui_screens/to_do_screen/widget/task_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/clock_theme.dart';
import '../../../../blocs/task_bloc.dart';

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
    // dispatch event to TaskBloc
    context.read<TaskBloc>().add(AddTask(title, description, priority));
    // give immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task added!'),
          backgroundColor: widget.theme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openTaskForm,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.theme.inputFieldColor,
                widget.theme.inputFieldColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.theme.borderColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.theme.buttonColor.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.theme.buttonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: widget.theme.buttonColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Add a new task",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: widget.theme.buttonColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
