import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/clock_theme.dart';
import '../../../../blocs/task_bloc.dart';
import 'task_card.dart';

class TaskListWidget extends StatelessWidget {
  final ClockTheme theme;

  const TaskListWidget({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoadInProgress) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme.buttonColor,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading tasks...',
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is TaskOperationFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 56,
                  color: theme.errorColor.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.error,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is TaskLoadSuccess) {
          // remove completed tasks and show newest first
          final tasks = state.tasks
              .where((task) => !task.isDone)
              .toList()
              .reversed
              .toList();

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: theme.successColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'All caught up!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No tasks to complete',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return TaskCard(
                key: ValueKey('${task.title}_${task.date}'),
                task: task,
                index: index,
                onDelete: (i) => context.read<TaskBloc>().add(DeleteTask(i)),
                theme: theme,
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
