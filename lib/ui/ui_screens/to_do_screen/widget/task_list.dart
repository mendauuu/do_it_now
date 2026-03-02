import 'package:flutter/material.dart';
import '../../../theme/clock_theme.dart';
import 'package:do_it_now/data/database/database_initializer.dart';
import 'package:do_it_now/ui/hive/task_model.dart';

class TaskListWidget extends StatefulWidget {
  final Function(int) removeTaskCallback;
  final ClockTheme theme;

  const TaskListWidget({
    super.key,
    required this.removeTaskCallback,
    required this.theme,
  });

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  late Future<List<TaskModel>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture = DatabaseInitializer.getAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TaskModel>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Text(
              "No tasks yet",
              style: TextStyle(color: widget.theme.secondaryTextColor),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.theme.borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: widget.theme.borderColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(color: widget.theme.textColor),
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.delete, color: widget.theme.secondHandColor),
                    onPressed: () async {
                      await widget.removeTaskCallback(index);
                      _loadTasks();
                    },
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
