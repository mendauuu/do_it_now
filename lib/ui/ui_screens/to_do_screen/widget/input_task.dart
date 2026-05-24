import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:do_it_now/blocs/task_bloc.dart';
import 'package:do_it_now/ui/ui_screens/to_do_screen/widget/task_form_sheet.dart';

class InputTask extends StatelessWidget {
  final ClockTheme theme;

  const InputTask({super.key, required this.theme});

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.secondaryBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskFormSheet(
        theme: theme,
        onAddTask: (title, desc, priority, category, dueDate) {
          context.read<TaskBloc>().add(
                AddTask(title, desc, priority,
                    category: category, dueDate: dueDate),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task added!'),
              backgroundColor: theme.successColor,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openForm(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.inputFieldColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.buttonColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.buttonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.add_rounded, size: 22, color: theme.buttonColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Add a new task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: theme.buttonColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
