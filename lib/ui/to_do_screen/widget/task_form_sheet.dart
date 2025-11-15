import 'package:flutter/material.dart';

class TaskFormSheet extends StatefulWidget {
  final Function(String, String, int) onAddTask;

  const TaskFormSheet({super.key, required this.onAddTask});

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  int selectedPriority = 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Add Task",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),

          // Title input
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: "Task title",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 14),

          // Description
          TextField(
            controller: descController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Description (optional)",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 14),

          // Priority picker
          Row(
            children: [
              Text(
                "Priority:",
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
              SizedBox(width: 12),
              for (int i = 1; i <= 3; i++)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPriority = i;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedPriority == i
                          ? Colors.blueAccent
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selectedPriority == i
                          ? [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      "$i",
                      style: TextStyle(
                        color: selectedPriority == i
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),

          // Submit button (Soft Red / Coral style)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  widget.onAddTask(
                    titleController.text,
                    descController.text,
                    selectedPriority,
                  );
                  Navigator.pop(context);
                }
              },
              icon: Icon(Icons.add_task),
              label: Text("Add Task"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300], // Soft Red / Coral
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}
