import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:do_it_now/ui/hive/task_model.dart';

typedef OnSaveTask = void Function(
  String title,
  String description,
  int priority,
  String category,
  DateTime? dueDate,
);

class TaskFormSheet extends StatefulWidget {
  final OnSaveTask onAddTask;
  final ClockTheme theme;

  /// If provided, the form opens in edit mode pre-filled with this task.
  final TaskModel? initialTask;

  const TaskFormSheet({
    super.key,
    required this.onAddTask,
    required this.theme,
    this.initialTask,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  late int _priority;
  late String _category;
  DateTime? _dueDate;

  bool get _isEditing => widget.initialTask != null;

  static const _categories = [
    'General',
    'Work',
    'Personal',
    'Health',
    'Learning',
    'Shopping',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? 1;
    _category = (t?.category != null && _categories.contains(t!.category))
        ? t.category
        : 'General';
    _dueDate = t?.dueDate;

    // Auto-guess priority from title as user types (add mode only)
    if (!_isEditing) {
      _titleCtrl.addListener(() {
        final guessed = _guessPriority(_titleCtrl.text);
        if (guessed != _priority) setState(() => _priority = guessed);
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  int _guessPriority(String title) {
    final l = title.toLowerCase();
    if (l.contains('urgent') || l.contains('asap') || l.contains('now')) {
      return 3;
    }
    if (l.contains('later') || l.contains('someday')) return 1;
    return _priority; // keep current
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: widget.theme.buttonColor,
            onPrimary: widget.theme.backgroundColor,
            surface: widget.theme.secondaryBackgroundColor,
            onSurface: widget.theme.textColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onAddTask(
      _titleCtrl.text.trim(),
      _descCtrl.text.trim(),
      _priority,
      _category,
      _dueDate,
    );
    Navigator.pop(context);
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: widget.theme.borderColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Task' : 'Add Task',
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
                // Title
                _field(
                  controller: _titleCtrl,
                  label: 'Title',
                  hint: 'Task title',
                  icon: Icons.title,
                  maxLength: 80,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Title required';
                    if (v.trim().length < 2) return 'At least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Description
                _field(
                  controller: _descCtrl,
                  label: 'Description (optional)',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                // Category + Due date (side by side)
                Row(
                  children: [
                    // Category dropdown
                    Expanded(
                      child: _dropdown(
                        value: _category,
                        label: 'Category',
                        items: _categories,
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Due date
                    Expanded(child: _dueDatePicker()),
                  ],
                ),
                const SizedBox(height: 14),
                // Priority
                _priorityRow(),
                const SizedBox(height: 20),
                // Buttons
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
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.buttonColor,
                          foregroundColor: widget.theme.backgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        child: Text(_isEditing ? 'Save Changes' : 'Add Task'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      cursorColor: widget.theme.buttonColor,
      style: TextStyle(color: widget.theme.textColor),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: widget.theme.secondaryTextColor),
        hintStyle: TextStyle(color: widget.theme.secondaryTextColor),
        counterStyle: TextStyle(color: widget.theme.secondaryTextColor),
        filled: true,
        fillColor: widget.theme.inputFieldColor,
        prefixIcon: Icon(icon, color: widget.theme.buttonColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: widget.theme.borderColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.buttonColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: widget.theme.borderColor.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: widget.theme.secondaryBackgroundColor,
      style: TextStyle(color: widget.theme.textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.theme.secondaryTextColor),
        filled: true,
        fillColor: widget.theme.inputFieldColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: widget.theme.borderColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: widget.theme.borderColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.buttonColor, width: 2),
        ),
      ),
      items: items
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: TextStyle(color: widget.theme.textColor)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dueDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: widget.theme.inputFieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: widget.theme.borderColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded,
                size: 18, color: widget.theme.buttonColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _dueDate == null
                    ? 'Due date'
                    : DateFormat('MMM d').format(_dueDate!),
                style: TextStyle(
                  fontSize: 14,
                  color: _dueDate == null
                      ? widget.theme.secondaryTextColor
                      : widget.theme.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_dueDate != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: Icon(Icons.close,
                    size: 16, color: widget.theme.secondaryTextColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _priorityRow() {
    return Row(
      children: [
        Text('Priority:',
            style: TextStyle(
                fontSize: 15,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        for (final level in [1, 2, 3])
          GestureDetector(
            onTap: () => setState(() => _priority = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _priority == level
                    ? widget.theme.buttonColor
                    : widget.theme.inputFieldColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _priority == level
                      ? widget.theme.buttonColor
                      : widget.theme.borderColor,
                  width: _priority == level ? 2 : 1,
                ),
              ),
              child: Text(
                level == 1
                    ? 'Low'
                    : level == 2
                        ? 'Med'
                        : 'High',
                style: TextStyle(
                  color: _priority == level
                      ? widget.theme.backgroundColor
                      : widget.theme.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
