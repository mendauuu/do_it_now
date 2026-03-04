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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  int selectedPriority = 1;
  DateTime? _dueDate;

  // simple keyword-based priority guesser
  void _guessPriority(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('urgent') ||
        lower.contains('asap') ||
        lower.contains('now')) {
      selectedPriority = 3;
    } else if (lower.contains('later') || lower.contains('someday')) {
      selectedPriority = 1;
    } // leave medium as default
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.theme.buttonColor,
              onPrimary: widget.theme.backgroundColor,
              surface: widget.theme.secondaryBackgroundColor,
              onSurface: widget.theme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 10,
      ),
      child: Card(
        color: widget.theme.secondaryBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: widget.theme.borderColor),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // grab handle + header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.theme.borderColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Task",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: widget.theme.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title input with counter and validator
                    TextFormField(
                      controller: titleController,
                      cursorColor: widget.theme.buttonColor,
                      style: TextStyle(color: widget.theme.textColor),
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle:
                            TextStyle(color: widget.theme.secondaryTextColor),
                        hintText: "Task title",
                        hintStyle:
                            TextStyle(color: widget.theme.secondaryTextColor),
                        counterStyle:
                            TextStyle(color: widget.theme.secondaryTextColor),
                        filled: true,
                        fillColor: widget.theme.inputFieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: widget.theme.borderColor
                                  .withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: widget.theme.buttonColor, width: 2),
                        ),
                        prefixIcon:
                            Icon(Icons.title, color: widget.theme.buttonColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      onChanged: (text) {
                        setState(() {
                          _guessPriority(text);
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      cursorColor: widget.theme.buttonColor,
                      style: TextStyle(color: widget.theme.textColor),
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        labelStyle:
                            TextStyle(color: widget.theme.secondaryTextColor),
                        filled: true,
                        fillColor: widget.theme.inputFieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: widget.theme.borderColor
                                  .withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: widget.theme.buttonColor, width: 2),
                        ),
                        prefixIcon: Icon(Icons.description,
                            color: widget.theme.buttonColor),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Due date row
                    GestureDetector(
                      onTap: _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.theme.inputFieldColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                widget.theme.borderColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: widget.theme.buttonColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dueDate == null
                                    ? 'Due date (optional)'
                                    : '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}',
                                style: TextStyle(
                                    color: _dueDate == null
                                        ? widget.theme.secondaryTextColor
                                        : widget.theme.textColor),
                              ),
                            ),
                            if (_dueDate != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _dueDate = null;
                                  });
                                },
                                child: Icon(Icons.close,
                                    color: widget.theme.secondaryTextColor,
                                    size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Priority picker with labels
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
                        const SizedBox(width: 12),
                        for (int i = 1; i <= 3; i++)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPriority = i;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
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
                                          color: widget.theme.glowColor
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                i == 1
                                    ? 'Low'
                                    : i == 2
                                        ? 'Med'
                                        : 'High',
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
                    const SizedBox(height: 20),

                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.theme.textColor,
                              side: BorderSide(color: widget.theme.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                var desc = descController.text;
                                if (_dueDate != null &&
                                    desc.trim().isNotEmpty) {
                                  desc =
                                      "${desc.trim()} (due ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year})";
                                } else if (_dueDate != null) {
                                  desc =
                                      "(due ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year})";
                                }
                                widget.onAddTask(
                                  titleController.text,
                                  desc,
                                  selectedPriority,
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.theme.buttonColor,
                              foregroundColor: widget.theme.backgroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            child: const Text('Add Task'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
