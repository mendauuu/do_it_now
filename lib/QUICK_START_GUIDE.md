// QUICK START GUIDE - SQL Database Integration

// ============================================================================
// 1. ADD THIS TO main.dart (in main() function)
// ============================================================================

import 'package:do_it_now/data/database/database_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseInitializer.initialize();
  
  runApp(const MyApp());
}

// ============================================================================
// 2. CREATE A NEW TASK (example in your form submission)
// ============================================================================

import 'package:do_it_now/data/database/database_initializer.dart';
import 'package:do_it_now/data/validators/input_validator.dart';

// Validate
String? titleError = InputValidator.validateTitle(titleController.text);
String? descError = InputValidator.validateDescription(descController.text);

if (titleError == null && descError == null) {
  // Create
  await DatabaseInitializer.createTask(
    title: titleController.text,
    description: descController.text,
    priority: priorityValue, // 1, 2, or 3
    category: 'Work', // or any category
  );
  
  // Refresh UI
  setState(() {});
}

// ============================================================================
// 3. LOAD AND DISPLAY ALL TASKS
// ============================================================================

List<Task> _tasks = [];

@override
void initState() {
  super.initState();
  _loadTasks();
}

Future<void> _loadTasks() async {
  final tasks = await DatabaseInitializer.getAllTasks();
  setState(() => _tasks = tasks);
}

@override
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: _tasks.length,
    itemBuilder: (context, index) {
      final task = _tasks[index];
      return ListTile(
        title: Text(task.title),
        subtitle: Text(task.description),
        trailing: Checkbox(
          value: task.isDone,
          onChanged: (val) async {
            if (val != null) {
              await DatabaseInitializer.toggleTaskCompletion(
                task.id!,
                val,
              );
              _loadTasks();
            }
          },
        ),
      );
    },
  );
}

// ============================================================================
// 4. DISPLAY STATISTICS
// ============================================================================

TaskStatistics? _stats;

@override
void initState() {
  super.initState();
  _loadStats();
}

Future<void> _loadStats() async {
  final stats = await DatabaseInitializer.getWeeklyStatistics();
  setState(() => _stats = stats);
}

Widget _buildStatsScreen() {
  if (_stats == null) {
    return Center(child: CircularProgressIndicator());
  }
  
  return Column(
    children: [
      Text('Total Tasks: ${_stats!.totalTasks}'),
      Text('Completed: ${_stats!.completedTasks}'),
      Text('Completion Rate: ${_stats!.completionRate.toStringAsFixed(1)}%'),
      Text('High Priority: ${_stats!.highPriorityTasks}'),
      Text('This Week: ${_stats!.tasksCompletedThisWeek}'),
    ],
  );
}

// ============================================================================
// 5. DELETE A TASK
// ============================================================================

onPressed: () async {
  await DatabaseInitializer.deleteTask(taskId);
  _loadTasks(); // Refresh
}

// ============================================================================
// 6. EDIT A TASK
// ============================================================================

// Get existing task
final task = _tasks.firstWhere((t) => t.id == taskId);

// Create updated copy
final updatedTask = task.copyWith(
  title: newTitle,
  description: newDescription,
  priority: newPriority,
);

// Save to database
final repository = DatabaseInitializer.getRepository();
await repository.updateTask(updatedTask);

// Refresh UI
_loadTasks();

// ============================================================================
// 7. PRIORITY HELPERS
// ============================================================================

import 'package:do_it_now/data/validators/input_validator.dart';

// Get priority label
String label = InputValidator.getPriorityLabel(3); // Returns 'High'

// Get priority color
int color = InputValidator.getPriorityColorValue(2); // Returns orange

// ============================================================================
// 8. ADVANCED QUERIES
// ============================================================================

final repository = DatabaseInitializer.getRepository();

// Get only pending tasks
final pending = await repository.getPendingTasks();

// Get completed tasks
final completed = await repository.getCompletedTasks();

// Get tasks by category
final workTasks = await repository.getTasksByCategory('Work');

// Get single task
final task = await repository.getTaskById(123);

// Get tasks between dates
final rangedTasks = await repository.getTasksByDateRange(
  DateTime(2024, 1, 1),
  DateTime(2024, 12, 31),
);

// ============================================================================
// 9. STREAK AND PRODUCTIVITY
// ============================================================================

final streak = await DatabaseInitializer.getStreak();
print('Current Streak: $streak days');

final trend = await DatabaseInitializer.getProductivityTrend();
// Returns: {'Week 1': 75.0, 'Week 2': 80.0, ...}

// ============================================================================
// 10. INPUT VALIDATION EXAMPLES
// ============================================================================

// Check title
if (InputValidator.validateTitle(title) != null) {
  print('Invalid title!');
}

// Check description  
if (InputValidator.validateDescription(desc) != null) {
  print('Invalid description!');
}

// Check priority
if (InputValidator.validatePriority(priority) != null) {
  print('Invalid priority!');
}

// Check category
if (InputValidator.validCategory(category) != null) {
  print('Invalid category!');
}

// ============================================================================
// DATABASE FILES SUMMARY
// ============================================================================

/*
lib/data/
├── database/
│   ├── database_service.dart        (SQLite connection/schema)
│   └── database_initializer.dart    (App initialization helper)
├── models/
│   ├── task_model.dart              (Task data class)
│   └── task_statistics.dart         (Analytics data class)
├── repositories/
│   └── task_repository.dart         (All CRUD operations)
├── services/
│   └── statistics_service.dart      (Analytics calculations)
├── validators/
│   └── input_validator.dart         (Input validation)
└── DATABASE_ARCHITECTURE.md         (Full documentation)
*/

// ============================================================================
// DEPENDENCIES INSTALLED
// ============================================================================

/*
pubspec.yaml updates:
- sqflite: ^2.3.3       (SQLite database)
- path: ^1.8.3          (Database path resolution)
- intl: ^0.19.0         (Date formatting for analytics)
*/

// ============================================================================
// COMMON PATTERNS
// ============================================================================

// Pattern 1: Load data with error handling
Future<void> _loadData() async {
  try {
    final tasks = await DatabaseInitializer.getAllTasks();
    setState(() => _tasks = tasks);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// Pattern 2: Form submission
Future<void> _submitForm() async {
  try {
    // Validate
    if (!_formKey.currentState!.validate()) return;
    
    // Create
    await DatabaseInitializer.createTask(
      title: _titleController.text,
      description: _descController.text,
      priority: _priority,
      category: _category,
    );
    
    // Success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task created!')),
    );
    
    // Navigate back
    Navigator.pop(context);
  } catch (e) {
    // Error feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// Pattern 3: Refresh on tab change
class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  // Refresh when tab is accessed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStats();
    }
  }
}

// ============================================================================
