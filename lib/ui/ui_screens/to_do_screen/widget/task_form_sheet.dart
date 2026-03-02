import 'package:flutter/material.dart';
import '../../../theme/clock_theme.dart';

class TaskFormSheet extends StatefulWidget {
  final Function(String, String, int) onAddTask;
  final ClockTheme theme;

  const TaskFormSheet(
      {super.key, required this.onAddTask, required this.theme});

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
              color: widget.theme.textColor,
            ),
          ),
          SizedBox(height: 20),

          // Title input
          TextField(
            controller: titleController,
            cursorColor: widget.theme.buttonColor,
            style: TextStyle(color: widget.theme.textColor),
            decoration: InputDecoration(
              hintText: "Task title",
              hintStyle: TextStyle(color: widget.theme.secondaryTextColor),
              filled: true,
              fillColor: widget.theme.inputFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: widget.theme.borderColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: widget.theme.buttonColor, width: 2),
              ),
              prefixIcon: Icon(Icons.title, color: widget.theme.buttonColor),
            ),
          ),
          SizedBox(height: 14),

          // Description
          TextField(
            controller: descController,
            maxLines: 3,
            cursorColor: widget.theme.buttonColor,
            style: TextStyle(color: widget.theme.textColor),
            decoration: InputDecoration(
              hintText: "Description (optional)",
              hintStyle: TextStyle(color: widget.theme.secondaryTextColor),
              filled: true,
              fillColor: widget.theme.inputFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: widget.theme.borderColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: widget.theme.buttonColor, width: 2),
              ),
              prefixIcon:
                  Icon(Icons.description, color: widget.theme.buttonColor),
            ),
          ),
          SizedBox(height: 14),

          // Priority picker
          Row(
            children: [
              Text(
                "Priority:",
                style: TextStyle(
                  fontSize: 16,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
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
                          ? widget.theme.buttonColor
                          : widget.theme.inputFieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedPriority == i
                            ? widget.theme.buttonColor
                            : widget.theme.borderColor,
                        width: selectedPriority == i ? 2 : 1,
                      ),
                      boxShadow: selectedPriority == i
                          ? [
                              BoxShadow(
                                color: widget.theme.glowColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      "$i",
                      style: TextStyle(
                        color: selectedPriority == i
                            ? widget.theme.backgroundColor
                            : widget.theme.secondaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),

          // Submit button
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
                backgroundColor: widget.theme.buttonColor,
                foregroundColor: widget.theme.backgroundColor,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}
