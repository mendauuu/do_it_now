import 'package:flutter/material.dart';
import 'package:do_it_now/data/database/database_initializer.dart';
import '../../../theme/clock_theme.dart';
import '../../../hive/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final int index;
  final Function(int) onDelete;
  final ClockTheme theme;

  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onDelete,
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
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion() async {
    try {
      setState(() {
        _isCompleted = !_isCompleted;
      });
      await DatabaseInitializer.toggleTaskCompletion(
        widget.index,
        _isCompleted,
      );
    } catch (e) {
      setState(() {
        _isCompleted = !_isCompleted;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: widget.theme.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If task content changed (deleted and replaced by different task), reset expanded state
    if (oldWidget.task.title != widget.task.title ||
        oldWidget.task.date != widget.task.date) {
      _isExpanded = false;
      _expandController.reset();
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case 3:
        return widget.theme.errorColor;
      case 2:
        return widget.theme.warningColor;
      default:
        return widget.theme.successColor;
    }
  }

  String _getPriorityLabel() {
    switch (widget.task.priority) {
      case 3:
        return 'High';
      case 2:
        return 'Med';
      default:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCompleted
              ? widget.theme.successColor.withValues(alpha: 0.2)
              : widget.theme.borderColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.shadowColor?.withValues(alpha: 0.08) ??
                Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          // Card Header
          GestureDetector(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: _toggleCompletion,
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
                  // Title & Description
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
                        const SizedBox(height: 3),
                        Text(
                          widget.task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.theme.secondaryTextColor
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Priority Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getPriorityLabel(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _getPriorityColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Expand Icon
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
          // Expanded Details
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
                  // Date Row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: widget.theme.infoColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.task.date.toString().substring(0, 10),
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.theme.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleCompletion,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9, horizontal: 8),
                              decoration: BoxDecoration(
                                color: (_isCompleted
                                        ? widget.theme.warningColor
                                        : widget.theme.successColor)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isCompleted
                                        ? Icons.restore_rounded
                                        : Icons.check_rounded,
                                    size: 15,
                                    color: _isCompleted
                                        ? widget.theme.warningColor
                                        : widget.theme.successColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _isCompleted ? 'Undo' : 'Done',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _isCompleted
                                            ? widget.theme.warningColor
                                            : widget.theme.successColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onDelete(widget.index),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9, horizontal: 8),
                              decoration: BoxDecoration(
                                color: widget.theme.errorColor
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 15,
                                    color: widget.theme.errorColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Delete',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: widget.theme.errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
}
