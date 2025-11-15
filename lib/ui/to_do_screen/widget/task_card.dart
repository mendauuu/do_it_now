import 'package:flutter/material.dart';
import 'package:do_it_now/ui/hive/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final int index;
  final Function(int) onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        title: Text(
          task.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        // subtitle: Text(
        //   "Priority: ${task.priority} | ${task.date.toLocal().toString().substring(0, 16)}",
        //   style: TextStyle(color: Colors.grey[700]),
        // ),
        trailing: const Icon(Icons.expand_more, size: 30),
        children: [
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description, color: Colors.blueGrey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.orange),
              const SizedBox(width: 8),
              Text("Priority: ${task.priority}"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.green),
              const SizedBox(width: 8),
              Text(task.date.toString().substring(0, 16)),
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
                backgroundColor: Colors.red[300], // soft red
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
