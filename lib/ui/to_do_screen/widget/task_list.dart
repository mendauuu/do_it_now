import 'package:do_it_now/ui/to_do_screen/widget/task_card.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:do_it_now/ui/hive/task_model.dart';

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
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<TaskModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No tasks yet!"));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final TaskModel task = box.getAt(index)!;

              return TaskCard(
                task: task,
                index: index,
                onDelete: removeTaskCallback,
              );
            },
          );
        },
      ),
    );
  }
}
