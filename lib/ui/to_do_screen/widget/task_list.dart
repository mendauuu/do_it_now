import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../hive/task_model.dart';

class TaskListWidget extends StatelessWidget {
  final Box<TaskModel> taskBox;
  final Function(int) removeTaskCallback;

  const TaskListWidget({
    super.key,
    required this.taskBox,
    required this.removeTaskCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: taskBox.listenable(),
      builder: (context, Box<TaskModel> box, _) {
        if (box.isEmpty) {
          return const Center(
            child: Text(
              "No tasks yet",
              style: TextStyle(color: Colors.white54),
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task?.title ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
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
