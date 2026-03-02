# UI Integration Guide - Connect Screens to DualRepository

## 🎯 Quick Integration Steps

Your screens are currently using the old Hive-based approach. To connect them to the new DualRepository system while keeping both working, follow these patterns:

---

## 📱 Pattern 1: Update a Screen That Lists Tasks

### BEFORE (Hive-only):
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:do_it_now/ui/hive/task_model.dart';

class ToDoScreen extends StatefulWidget {
  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  late Box<TaskModel> _taskBox;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<TaskModel>('tasks');
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _taskBox.length,
      itemBuilder: (context, index) {
        final task = _taskBox.getAt(index);
        return TaskCard(task: task, index: index);
      },
    );
  }
}
```

### AFTER (Dual-mode safe):
```dart
import 'package:do_it_now/data/database/database_initializer.dart';
import 'package:do_it_now/ui/hive/task_model.dart';

class ToDoScreen extends StatefulWidget {
  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Load tasks from DualRepository
  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);
      final tasks = await DatabaseInitializer.getAllTasks();
      setState(() => _tasks = tasks);
    } catch (e) {
      print('Error loading tasks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return TaskCard(
          task: task,
          index: index,
          onUpdate: _loadTasks,
        );
      },
    );
  }
}
```

**Key Changes:**
- Replace Hive.box with DatabaseInitializer
- Call getAllTasks() in initState
- Manage loading state
- Refresh after updates

---

## 📝 Pattern 2: Update a Screen That Creates Tasks

### BEFORE (Hive-only):
```dart
class TaskFormSheet extends StatefulWidget {
  @override
  _TaskFormSheetState createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int _priority = 2;

  void _createTask() {
    final taskBox = Hive.box<TaskModel>('tasks');
    final newTask = TaskModel(
      title: _titleController.text,
      description: _descController.text,
      priority: _priority,
      isDone: false,
      date: DateTime.now(),
    );
    taskBox.add(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _titleController),
        TextField(controller: _descController),
        ElevatedButton(onPressed: _createTask, child: Text('Create')),
      ],
    );
  }
}
```

### AFTER (Dual-mode safe):
```dart
import 'package:do_it_now/data/database/database_initializer.dart';
import 'package:do_it_now/data/validators/input_validator.dart';

class TaskFormSheet extends StatefulWidget {
  @override
  _TaskFormSheetState createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  int _priority = 2;
  bool _isCreating = false;

  Future<void> _createTask() async {
    // Validate input
    final titleError = InputValidator.validateTitle(_titleController.text);
    final descError = InputValidator.validateDescription(_descController.text);
    final categoryError = InputValidator.validCategory(_categoryController.text);

    if (titleError != null || descError != null || categoryError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(titleError ?? descError ?? categoryError ?? 'Invalid input')),
      );
      return;
    }

    try {
      setState(() => _isCreating = true);

      // Create via DualRepository
      await DatabaseInitializer.createTask(
        title: _titleController.text,
        description: _descController.text,
        priority: _priority,
        category: _categoryController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created!')),
      );

      Navigator.pop(context, true); // Indicate reload needed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Task title',
            errorText: 
                _titleController.text.isEmpty 
                    ? null 
                    : InputValidator.validateTitle(_titleController.text),
          ),
        ),
        TextField(
          controller: _descController,
          decoration: InputDecoration(
            hintText: 'Task description',
            errorText: 
                _descController.text.isEmpty 
                    ? null 
                    : InputValidator.validateDescription(_descController.text),
          ),
        ),
        TextField(
          controller: _categoryController,
          decoration: InputDecoration(hintText: 'Category'),
        ),
        Row(
          children: [
            Text('Priority:'),
            ...List.generate(3, (i) {
              final label = ['Low', 'Medium', 'High'][i];
              return Expanded(
                child: Chip(
                  label: Text(label),
                  selected: _priority == i + 1,
                  onSelected: (selected) {
                    if (selected) setState(() => _priority = i + 1);
                  },
                ),
              );
            }),
          ],
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createTask,
          child: _isCreating 
              ? CircularProgressIndicator() 
              : Text('Create Task'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
```

**Key Changes:**
- Use DatabaseInitializer.createTask()
- Add input validation using InputValidator
- Handle async operation with loading state
- Catch and display errors
- Return value to parent for reload signal

---

## ✏️ Pattern 3: Update a Screen That Edits Tasks

### AFTER (Dual-mode safe):
```dart
import 'package:do_it_now/data/database/database_initializer.dart';

class TaskEditSheet extends StatefulWidget {
  final int taskIndex;
  final TaskModel task;

  const TaskEditSheet({required this.taskIndex, required this.task});

  @override
  _TaskEditSheetState createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late int _priority;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
  }

  Future<void> _saveTask() async {
    try {
      setState(() => _isSaving = true);

      // Create updated task
      final updatedTask = TaskModel(
        title: _titleController.text,
        description: _descController.text,
        priority: _priority,
        isDone: widget.task.isDone,
        date: widget.task.date,
      );

      // Update via DualRepository
      await DatabaseInitializer.updateTask(widget.taskIndex, updatedTask);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated!')),
      );

      Navigator.pop(context, true); // Indicate reload needed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _titleController),
        TextField(controller: _descController),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveTask,
          child: _isSaving ? CircularProgressIndicator() : Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
```

---

## 🔄 Pattern 4: Toggle Task Completion

### AFTER (Dual-mode safe):
```dart
class TaskCard extends StatefulWidget {
  final TaskModel task;
  final int index;
  final VoidCallback onUpdate;

  const TaskCard({
    required this.task,
    required this.index,
    required this.onUpdate,
  });

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isToggling = false;

  Future<void> _toggleCompletion() async {
    try {
      setState(() => _isToggling = true);

      // Toggle via DualRepository
      await DatabaseInitializer.toggleTaskCompletion(
        widget.index,
        !widget.task.isDone,
      );

      widget.onUpdate(); // Notify parent to reload
    } catch (e) {
      print('Error toggling task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.task.title,
        style: TextStyle(
          decoration: widget.task.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Checkbox(
        value: widget.task.isDone,
        onChanged: _isToggling
            ? null
            : (_) => _toggleCompletion(),
      ),
    );
  }
}
```

---

## 🗑️ Pattern 5: Delete Task

### AFTER (Dual-mode safe):
```dart
Future<void> _deleteTask(int index) async {
  try {
    await DatabaseInitializer.deleteTask(index);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
    
    // Reload parent screen
    setState(() => _loadTasks());
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## 📊 Pattern 6: Show Statistics (Analytics)

### NEW (SQL-based Analytics):
```dart
class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  TaskStatistics? _weeklyStats;
  int _streak = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);

      // Get statistics from SQL-based service
      final stats = await DatabaseInitializer.getWeeklyStatistics();
      final streak = await DatabaseInitializer.getStreak();

      setState(() {
        _weeklyStats = stats;
        _streak = streak;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _weeklyStats == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Total: ${_weeklyStats!.totalTasks}'),
                Text('Completed: ${_weeklyStats!.completedTasks}'),
                Text('Rate: ${_weeklyStats!.completionRate.toStringAsFixed(1)}%'),
                Text('🔥 Streak: $_streak days'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 🔌 Integration Checklist

For each screen that uses tasks:

- [ ] Remove `import 'package:hive_flutter/hive_flutter.dart'`
- [ ] Remove `import 'package:do_it_now/ui/hive/task_model.dart'` (old location)
- [ ] Add `import 'package:do_it_now/data/database/database_initializer.dart'`
- [ ] Add `import 'package:do_it_now/data/validators/input_validator.dart'` (for validation)
- [ ] Replace direct Hive box access with DatabaseInitializer calls
- [ ] Add loading states for async operations
- [ ] Add error handling with try-catch
- [ ] Test all operations (create, read, update, delete)

---

## ✅ Testing Each Screen

### Step 1: Create a Task
```
1. Open app
2. Click "Add Task"
3. Fill in title, description, priority
4. Click "Create"
5. ✅ Verify task appears in list
```

### Step 2: Update a Task
```
1. Tap on task to open edit screen
2. Change title or description
3. Click "Save"
4. ✅ Verify changes appear in list
```

### Step 3: Toggle Completion
```
1. Click checkbox on task
2. ✅ Verify task marked as done
3. Click checkbox again
4. ✅ Verify task marked as pending
```

### Step 4: Delete a Task
```
1. Long-press task (if implemented) or use delete button
2. Confirm deletion
3. ✅ Verify task removed from list
```

### Step 5: View Statistics
```
1. Navigate to Analysis/Statistics screen
2. ✅ Verify stats display correctly
3. ✅ Verify streak calculation
```

---

## 🚀 Implementation Priority

### Priority 1 (Start First):
1. to_do_screen.dart - List all tasks
2. input_task.dart - Create tasks
3. task_card.dart - Display individual tasks

### Priority 2:
4. task_form_sheet.dart - More detailed creation
5. Settings/navigation screens

### Priority 3:
6. analysis_screen.dart - Statistics display
7. Advanced features

---

## 💡 Common Patterns

**Always do this for async operations:**
```dart
try {
  setState(() => _isLoading = true);
  
  // Call DatabaseInitializer method
  final result = await DatabaseInitializer.method(...);
  
  // Update UI
  setState(() => _data = result);
} catch (e) {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
} finally {
  setState(() => _isLoading = false);
}
```

**Always do this for validation:**
```dart
// Before creating/updating
final error = InputValidator.validateTitle(title);
if (error != null) {
  // Show error and return
  return;
}

// Proceed with operation
```

---

**Status**: Ready to integrate screens one by one. Start with Pattern 1 (list screen) as it's the most straightforward.
