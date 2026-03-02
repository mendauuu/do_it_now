# Quick Reference - API & Code Examples

## 🎯 Import Everything You Need

```dart
import 'package:do_it_now/data/database/database_initializer.dart';
import 'package:do_it_now/data/models/task_model.dart';
import 'package:do_it_now/data/validators/input_validator.dart';
```

---

## 📖 Common Patterns

### Pattern 1: Display All Tasks

```dart
// Get all tasks
final tasks = await DatabaseInitializer.getAllTasks();

// In UI (StreamBuilder or FutureBuilder)
FutureBuilder<List<TaskModel>>(
  future: DatabaseInitializer.getAllTasks(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final task = snapshot.data![index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### Pattern 2: Create New Task

```dart
// Validate input
String? titleError = InputValidator.validateTitle("New Task");
if (titleError != null) {
  showError(titleError);
  return;
}

// Create task
await DatabaseInitializer.createTask(
  title: "New Task",
  description: "Task description",
  priority: 2,
  category: "Work",
);

// Refresh UI
setState(() {});
```

### Pattern 3: Update Task

```dart
final updatedTask = TaskModel(
  id: task.id,
  title: "Updated Title",
  description: task.description,
  priority: 3,
  isDone: task.isDone,
  createdDate: task.createdDate,
  completedDate: task.completedDate,
  category: task.category,
);

await DatabaseInitializer.updateTask(index, updatedTask);
setState(() {});
```

### Pattern 4: Toggle Task Completion

```dart
// Check current status
bool isDone = task.isDone;

// Toggle
await DatabaseInitializer.toggleTaskCompletion(index, !isDone);

// Refresh
setState(() {});
```

### Pattern 5: Delete Task

```dart
await DatabaseInitializer.deleteTask(index);
setState(() {});
```

### Pattern 6: Show Analytics

```dart
// Get statistics
final stats = await DatabaseInitializer.getStatistics();

// Display
Text('Total: ${stats.totalTasks}'),
Text('Completed: ${stats.completedTasks}'),
Text('Pending: ${stats.pendingTasks}'),
Text('Completion: ${stats.completionPercentage}%'),
```

### Pattern 7: Validate Form Input

```dart
// Validate title
String? titleError = InputValidator.validateTitle(_titleController.text);

// Validate priority
String? priorityError = InputValidator.validatePriority(selectedPriority);

// Validate category
String? categoryError = InputValidator.validCategory(selectedCategory);

// Get labels
String label = InputValidator.getPriorityLabel(priority); // "High", "Medium", etc.

// Get colors
Color priorityColor = Color(
  InputValidator.getPriorityColorValue(priority)
);
```

### Pattern 8: Weekly/Monthly Analytics

```dart
// Weekly stats
final weekStats = await DatabaseInitializer.getWeeklyStatistics();

// Monthly stats  
final monthStats = await DatabaseInitializer.getMonthlyStatistics();

// Current streak
final streak = await DatabaseInitializer.getStreak();

// Productivity trend (for charts)
final trend = await DatabaseInitializer.getProductivityTrend();
```

### Pattern 9: Check Data Consistency

```dart
// Verify Hive and SQL are in sync
final isConsistent = await DatabaseInitializer.verifyDataConsistency();

if (!isConsistent) {
  // Force sync if needed
  await DatabaseInitializer.forceSyncHiveToSQL();
  showMessage('Data synced');
}
```

### Pattern 10: Current Database Source

```dart
// Check which source is active
bool usingSql = DatabaseInitializer.isUsingSQLSource();

if (usingSql) {
  print('Using SQL');
} else {
  print('Using Hive');
}

// Get migration stats
final stats = await DatabaseInitializer.getMigrationStats();
print('Hive: ${stats['hive_tasks']}');
print('SQL: ${stats['sql_tasks']}');
```

---

## 🛠️ Form Validation Example

```dart
class TaskForm extends StatefulWidget {
  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int _priority = 2;
  String _category = 'General';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Title field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Title'),
            validator: InputValidator.validateTitle,
          ),
          
          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
            validator: InputValidator.validateDescription,
            maxLines: 3,
          ),
          
          // Priority dropdown
          DropdownButton<int>(
            value: _priority,
            items: [1, 2, 3].map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(InputValidator.getPriorityLabel(p)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _priority = value!);
            },
          ),
          
          // Category field
          TextFormField(
            initialValue: _category,
            decoration: InputDecoration(labelText: 'Category'),
            validator: InputValidator.validCategory,
            onChanged: (value) => _category = value,
          ),
          
          // Submit button
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Create Task'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await DatabaseInitializer.createTask(
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        category: _category,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task created!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
```

---

## 📋 Task List Screen Example

```dart
class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<TaskModel>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture = DatabaseInitializer.getAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Tasks')),
      body: FutureBuilder<List<TaskModel>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(child: Text('No tasks'));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                index: index,
                onRefresh: _loadTasks,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => TaskFormSheet(onTaskCreated: _loadTasks),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## 🎨 Task Card Component Example

```dart
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final int index;
  final Function onRefresh;

  const TaskCard({
    required this.task,
    required this.index,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        // Checkbox for completion
        leading: Checkbox(
          value: task.isDone,
          onChanged: (value) async {
            await DatabaseInitializer.toggleTaskCompletion(
              index,
              value ?? false,
            );
            onRefresh();
          },
        ),
        
        // Title and description
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(task.description),
        
        // Priority color indicator
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(InputValidator.getPriorityColorValue(task.priority)),
            shape: BoxShape.circle,
          ),
        ),
        
        // Edit and delete
        onLongPress: () {
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(0, 0, 0, 0),
            items: [
              PopupMenuItem(
                child: Text('Edit'),
                onTap: () {
                  // Show edit dialog
                },
              ),
              PopupMenuItem(
                child: Text('Delete'),
                onTap: () async {
                  await DatabaseInitializer.deleteTask(index);
                  onRefresh();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 📊 Analytics Screen Example

```dart
class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics')),
      body: FutureBuilder<TaskStatistics>(
        future: DatabaseInitializer.getStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Summary cards
                SummaryCard(
                  title: 'Total Tasks',
                  value: '${stats.totalTasks}',
                ),
                SummaryCard(
                  title: 'Completed',
                  value: '${stats.completedTasks}',
                ),
                SummaryCard(
                  title: 'Pending',
                  value: '${stats.pendingTasks}',
                ),
                SummaryCard(
                  title: 'Completion Rate',
                  value: '${stats.completionPercentage}%',
                ),
                
                // Streak
                FutureBuilder<int>(
                  future: DatabaseInitializer.getStreak(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SummaryCard(
                        title: 'Current Streak',
                        value: '${snapshot.data} days',
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                
                // Productivity trend
                FutureBuilder<Map<String, double>>(
                  future: DatabaseInitializer.getProductivityTrend(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // Build chart here
                      return TrendChart(trend: snapshot.data!);
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing Snippet

```dart
// Add this button to test database
ElevatedButton(
  onPressed: () async {
    // Test 1: Create task
    await DatabaseInitializer.createTask(
      title: 'Test Task',
      description: 'Testing database',
      priority: 2,
      category: 'Test',
    );

    // Test 2: Get all tasks
    final tasks = await DatabaseInitializer.getAllTasks();
    print('All tasks: ${tasks.length}');

    // Test 3: Check consistency
    final consistent = await DatabaseInitializer.verifyDataConsistency();
    print('Data consistent: $consistent');

    // Test 4: Get stats
    final stats = await DatabaseInitializer.getMigrationStats();
    print('Hive: ${stats['hive_tasks']}, SQL: ${stats['sql_tasks']}');

    // Test 5: Get analytics
    final analytics = await DatabaseInitializer.getStatistics();
    print('Completed: ${analytics.completedTasks}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All tests completed!')),
    );
  },
  child: Text('Test Database'),
)
```

---

## 🚀 Switch Between Sources

```dart
// Check current source
bool usingSql = DatabaseInitializer.isUsingSQLSource();
print('Using: ${usingSql ? 'SQL' : 'Hive'}');

// Switch to SQL
DatabaseInitializer.switchToSQLSource(true);

// Switch back to Hive
DatabaseInitializer.switchToSQLSource(false);

// Force sync if needed
await DatabaseInitializer.forceSyncHiveToSQL();
```

---

## ⚡ Performance Tips

1. **Use FutureBuilder** - Load data asynchronously
2. **Cache results** - Don't re-fetch unnecessarily
3. **Paginate lists** - Load first 20 items, then more on scroll
4. **Use indexes** - SQL is optimized with indexes on created_date and is_done
5. **Batch operations** - Create multiple tasks in a loop

---

## 📝 Notes

- All methods are async/await
- Always handle errors with try-catch
- Call setState() after database operations
- Use FutureBuilder or StreamBuilder for UI updates
- ValidationValidator methods return String? (null if valid)
- Priority: 1 (High), 2 (Medium), 3 (Low)

---

**Reference**: See `UI_INTEGRATION_GUIDE.md` for more patterns
