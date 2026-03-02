import 'package:flutter/material.dart';
import '../../../theme/clock_theme.dart';
import '../../../hive/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final int index;
  final Function(int) onDelete;
  final ClockTheme theme;

  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        iconColor: theme.buttonColor,
        trailing: Icon(Icons.expand_more, size: 30, color: theme.buttonColor),
        children: [
          Divider(color: theme.borderColor.withOpacity(0.3)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description, color: theme.accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag, color: theme.warningColor),
              const SizedBox(width: 8),
              Text(
                "Priority: ${task.priority}",
                style: TextStyle(
                  color: task.priority == 3
                      ? theme.errorColor
                      : task.priority == 2
                          ? theme.warningColor
                          : theme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_month, color: theme.infoColor),
              const SizedBox(width: 8),
              Text(
                task.date.toString().substring(0, 16),
                style: TextStyle(color: theme.secondaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => onDelete(index),
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
