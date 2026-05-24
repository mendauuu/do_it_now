import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/blocs/task_bloc.dart';
import 'package:do_it_now/ui/ui_screens/to_do_screen/widget/task_form_sheet.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final ClockTheme theme;

  const TaskCard({
    super.key,
    required this.task,
    required this.theme,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late bool _isCompleted;
  bool _isExpanded = false;
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isDone;
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(TaskCard old) {
    super.didUpdateWidget(old);
    if (old.task.sqlId != widget.task.sqlId ||
        old.task.title != widget.task.title) {
      _isExpanded = false;
      _expandController.reset();
    }
    _isCompleted = widget.task.isDone;
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggle() {
    assert(widget.task.sqlId != null, 'TaskCard: task has no sqlId');
    final newValue = !_isCompleted;
    setState(() => _isCompleted = newValue);
    context.read<TaskBloc>().add(ToggleTask(widget.task.sqlId!, newValue));
  }

  void _delete() {
    assert(widget.task.sqlId != null, 'TaskCard: task has no sqlId');
    context.read<TaskBloc>().add(DeleteTask(widget.task.sqlId!));
  }

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.theme.secondaryBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskFormSheet(
        theme: widget.theme,
        initialTask: widget.task,
        onAddTask: (title, desc, priority, category, dueDate) {
          final edited = widget.task.copyWith(
            title: title,
            description: desc,
            priority: priority,
            category: category,
            dueDate: dueDate,
          );
          context.read<TaskBloc>().add(EditTask(edited));
        },
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _expandController.forward() : _expandController.reverse();
    });
  }

  Color _priorityColor() {
    return switch (widget.task.priority) {
      3 => widget.theme.errorColor,
      2 => widget.theme.warningColor,
      _ => widget.theme.successColor,
    };
  }

  String _priorityLabel() {
    return switch (widget.task.priority) {
      3 => 'High',
      2 => 'Med',
      _ => 'Low',
    };
  }

  bool get _isOverdue {
    final due = widget.task.dueDate;
    return due != null && !_isCompleted && due.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCompleted
              ? widget.theme.successColor.withValues(alpha: 0.2)
              : _isOverdue
                  ? widget.theme.errorColor.withValues(alpha: 0.4)
                  : widget.theme.borderColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.theme.shadowColor ?? Colors.black)
                .withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: _toggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCompleted
                            ? widget.theme.successColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: _isCompleted
                              ? widget.theme.successColor
                              : widget.theme.borderColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _isCompleted ? Icons.check : Icons.circle_outlined,
                        size: 18,
                        color: _isCompleted
                            ? widget.theme.successColor
                            : widget.theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _isCompleted
                                ? widget.theme.secondaryTextColor
                                    .withValues(alpha: 0.6)
                                : widget.theme.textColor,
                            decoration: _isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: widget.theme.secondaryTextColor,
                          ),
                        ),
                        if (widget.task.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.theme.secondaryTextColor
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        // Due date chip
                        if (widget.task.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 11,
                                color: _isOverdue
                                    ? widget.theme.errorColor
                                    : widget.theme.infoColor
                                        .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                DateFormat('MMM d')
                                    .format(widget.task.dueDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isOverdue
                                      ? widget.theme.errorColor
                                      : widget.theme.infoColor
                                          .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_isOverdue) ...[
                                const SizedBox(width: 4),
                                Text(
                                  'Overdue',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: widget.theme.errorColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Priority badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _priorityLabel(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  RotationTransition(
                    turns:
                        Tween(begin: 0.0, end: 0.5).animate(_expandController),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 22,
                      color: widget.theme.buttonColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details ────────────────────────────────────────────────
          if (_isExpanded) ...[
            Divider(
              color: widget.theme.borderColor.withValues(alpha: 0.15),
              height: 1,
              indent: 14,
              endIndent: 14,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Created date + category
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14,
                          color: widget.theme.infoColor.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(widget.task.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.label_outline_rounded,
                          size: 14,
                          color: widget.theme.infoColor.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        widget.task.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      _actionButton(
                        icon: _isCompleted
                            ? Icons.restore_rounded
                            : Icons.check_rounded,
                        label: _isCompleted ? 'Undo' : 'Done',
                        color: _isCompleted
                            ? widget.theme.warningColor
                            : widget.theme.successColor,
                        onTap: _toggle,
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: widget.theme.infoColor,
                        onTap: _openEdit,
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        color: widget.theme.errorColor,
                        onTap: _delete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
