import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/clock_theme.dart';
import '../../../../blocs/task_bloc.dart';
import 'task_card.dart';

class CompletedTasksPage extends StatelessWidget {
  final ClockTheme theme;

  const CompletedTasksPage({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textColor),
        title: Text(
          "Completed Tasks",
          style: TextStyle(color: theme.textColor),
        ),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoadSuccess) {
            /// SHOW ONLY COMPLETED
            final completedTasks = state.tasks
                .where((task) => task.isDone == true)
                .toList()
                .reversed
                .toList();

            if (completedTasks.isEmpty) {
              return Center(
                child: Text(
                  "No completed tasks",
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];

                return TaskCard(
                  task: task,
                  index: state.tasks.indexOf(task),
                  theme: theme,
                  onDelete: (i) {
                    context.read<TaskBloc>().add(DeleteTask(i));
                  },
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
