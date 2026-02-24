import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../theme/clock_theme.dart';
import '../../../hive/task_model.dart';

class TaskListWidget extends StatelessWidget {
  final Box<TaskModel> taskBox;
  final Function(int) removeTaskCallback;
  final ClockTheme theme;

  const TaskListWidget({
    super.key,
    required this.taskBox,
    required this.removeTaskCallback,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: taskBox.listenable(),
      builder: (context, Box<TaskModel> box, _) {
        if (box.isEmpty) {
          return Center(
            child: Text(
              "No tasks yet",
              style: TextStyle(color: theme.secondaryTextColor),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final task = box.getAt(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.borderColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task?.title ?? '',
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: theme.secondHandColor),
                    onPressed: () => removeTaskCallback(index),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
