# SQL Migration Strategy & Implementation Guide

## 📋 Current Architecture (Dual-Source Mode)

Your app now runs in **dual-source mode**:

```
┌─────────────────────────────────────┐
│           Main.dart                 │
│  Initializes both Hive and SQL      │
└─────────────────────────────────────┘
                ↓
        ┌───────┴────────┐
        ↓                ↓
   ┌─────────┐      ┌─────────┐
   │  Hive   │      │   SQL   │
   │ (Active)│      │ (Synced)│
   └─────────┘      └─────────┘
        ↑                ↓
        └────────────────┘
  DualRepository
  (manages both)
```

### How It Works:

1. **Initialize Phase** (in main.dart):
   - Initializes Hive database (current UI data source)
   - Initializes SQL database
   - Creates DualRepository to manage both
   - Automatically migrates existing Hive data to SQL

2. **Operation Phase**:
   - **Read**: Fetches from Hive (keeps UI working)
   - **Write**: Saves to both Hive and SQL (synchronization)
   - **Analytics**: Queries SQL database (for statistics)

3. **Migration Phase**:
   - Verify data consistency
   - Switch to SQL-only when confirmed
   - Remove Hive dependency

---

## 🚀 Implementation Steps

### Step 1: Verify Database Initialization

The following is already done in your code:

**main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialization (current UI source)
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox<TaskModel>('tasks');

  // SQL database initialization
  await DatabaseInitializer.initialize();

  runApp(const MyApp());
}
```

✅ **Status**: Complete

---

### Step 2: Test Dual-Source Operations

Add this test button to your home screen:

```dart
import 'package:do_it_now/data/database/database_initializer.dart';

ElevatedButton(
  onPressed: () async {
    // Test 1: Create task via DualRepository
    await DatabaseInitializer.createTask(
      title: 'Test Task',
      description: 'Testing dual-source',
      priority: 2,
      category: 'Test',
    );
    
    // Test 2: Verify it appears in UI
    final tasks = await DatabaseInitializer.getAllTasks();
    print('✅ Tasks in memory: ${tasks.length}');
    
    // Test 3: Check data consistency
    final isConsistent = 
        await DatabaseInitializer.verifyDataConsistency();
    print(isConsistent ? '✅ Data consistent' : '❌ Data mismatch');
    
    // Test 4: Get migration stats
    final stats = await DatabaseInitializer.getMigrationStats();
    print('📊 Hive: ${stats['hive_tasks']}, SQL: ${stats['sql_tasks']}');
  },
  child: Text('Test Database'),
)
```

**Expected Output:**
```
✅ Tasks in memory: 1
✅ Data consistent
📊 Hive: 1, SQL: 1
```

---

### Step 3: Verify Automatic Migration

When the app launches for the first time with existing Hive data:

1. Check the console output:
   ```
   ✅ SQL database initialized
   ✅ DualRepository initialized
   📊 Migration stats: 5 Hive tasks, 5 SQL tasks
   ```

2. Add a debug button to check migration:
   ```dart
   ElevatedButton(
     onPressed: () async {
       final stats = await DatabaseInitializer.getMigrationStats();
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(
           'Hive: ${stats['hive_tasks']} tasks\n'
           'SQL: ${stats['sql_tasks']} tasks'
         )),
       );
     },
     child: Text('Check Migration'),
   )
   ```

---

### Step 4: Test Data Consistency

Add a verification button:

```dart
ElevatedButton(
  onPressed: () async {
    try {
      final isConsistent = 
          await DatabaseInitializer.verifyDataConsistency();
      
      final message = isConsistent 
          ? '✅ Hive and SQL are in sync!'
          : '❌ Data mismatch detected!';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print('Error: $e');
    }
  },
  child: Text('Verify Consistency'),
)
```

**Expected Result**: ✅ Hive and SQL are in sync!

---

### Step 5: Force Synchronize (If Needed)

If data gets out of sync (rare), force a sync:

```dart
ElevatedButton(
  onPressed: () async {
    await DatabaseInitializer.forceSyncHiveToSQL();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync complete!')),
    );
  },
  child: Text('Force Sync Hive → SQL'),
)
```

---

## 🔄 Migration Flow

### Phase 1: Dual-Source (Current) ✅
```
┌─────────────────────────────────────┐
│  [✓] Both systems active            │
│  [✓] Hive as read source            │
│  [✓] Both receive writes            │
│  [✓] Data synced automatically      │
│  [ ] SQL as primary source          │
│  [ ] Hive removed                   │
└─────────────────────────────────────┘
```

### Phase 2: Verify & Test
```
Before switching, confirm:
  ✅ All tasks appear in Hive
  ✅ All tasks in SQL
  ✅ Counts match
  ✅ New tasks sync correctly
  ✅ Updates sync correctly
  ✅ Deletes sync correctly
```

### Phase 3: Switch to SQL-Only (After Verification)
```dart
// Switch to SQL as primary source
DatabaseInitializer.switchToSQLSource(true);
print(DatabaseInitializer.isUsingSQLSource()); // true
```

### Phase 4: Remove Hive (Final Step)
```dart
// Remove from main.dart
// Remove Hive initialization
// Remove all Hive imports from screens
// Remove Hive exports from pubspec.yaml
```

---

## 📊 Testing Checklist

### Basic Operations
- [ ] Create task - appears in UI
- [ ] Create task - appears in SQL
- [ ] Update task - updates in UI
- [ ] Update task - updates in SQL
- [ ] Delete task - removed from UI
- [ ] Delete task - removed from SQL

### Data Consistency
- [ ] verifyDataConsistency() returns true
- [ ] getMigrationStats() shows equal counts
- [ ] App restart doesn't duplicate tasks

### Analytics (SQL sourced)
- [ ] getStatistics() returns valid data
- [ ] getWeeklyStatistics() works
- [ ] getMonthlyStatistics() works
- [ ] getStreak() calculates correctly
- [ ] getProductivityTrend() shows trends

### Edge Cases
- [ ] Force sync completes without error
- [ ] Switching back to Hive source works
- [ ] Switching to SQL source works
- [ ] Creating 100+ tasks doesn't error

---

## 🔧 Current State: DualRepository Methods

All these methods are available and working:

### Read Operations
```dart
// Read from active source (Hive or SQL)
Future<List<TaskModel>> getAllTasks()
Future<List<TaskModel>> getPendingTasks()
Future<List<TaskModel>> getCompletedTasks()
```

### Write Operations
```dart
// Write to both sources
Future<void> createTask(TaskModel task)
Future<void> updateTask(int index, TaskModel updatedTask)
Future<void> toggleTaskCompletion(int index, bool isDone)
Future<void> deleteTask(int index)
```

### Migration Management
```dart
// Monitor migration progress
Future<Map<String, int>> getMigrationStats()
Future<bool> verifyDataConsistency()
Future<void> forceSyncHiveToSQL()

// Control data source
void switchToSQLSource(bool useSql)
bool isUsingSQLSource()
```

---

## 📝 Recommended Testing Timeline

### Day 1-2: Verify Initialization
- [ ] App starts without errors
- [ ] Console shows: "✅ SQL database initialized"
- [ ] Tasks still display in UI

### Day 2-3: Test Dual Operations
- [ ] Create new task - appears in UI and SQL
- [ ] Update task - updates in both
- [ ] Verify consistency - passes

### Day 3-4: Extended Testing
- [ ] Create 50+ tasks
- [ ] Toggle completions on multiple tasks
- [ ] Verify no duplicates
- [ ] Verify analytics work

### Day 4-5: Full Migration Verification
- [ ] All tests pass consistently
- [ ] No data loss observed
- [ ] No performance degradation

### Day 5+: Switch to SQL-Only
- [ ] Call `DatabaseInitializer.switchToSQLSource(true)`
- [ ] App continues to work
- [ ] Test everything again
- [ ] Remove Hive code

---

## 🚨 Troubleshooting

### Issue: "Data inconsistency detected"
**Solution:**
```dart
// Force sync all Hive data to SQL
await DatabaseInitializer.forceSyncHiveToSQL();

// Verify again
final isConsistent = 
    await DatabaseInitializer.verifyDataConsistency();
```

### Issue: Tasks not appearing after update
**Solution:**
1. Check console for exceptions
2. Verify DualRepository.initialize() was called
3. Check that update reached both sources

### Issue: App crashes on startup
**Solution:**
1. Ensure `DatabaseInitializer.initialize()` is called in main()
2. Check sqflite dependency is added to pubspec.yaml
3. Rebuild: `flutter clean && flutter pub get`

### Issue: SQL database not created
**Solution:**
```dart
// Manually trigger database creation
final db = await DatabaseService().database;
print('Database created at: $db');
```

---

## 📦 Next Steps After Migration

Once SQL is confirmed working and Hive is removed:

1. **Update screens to use SQL models directly**
   - Remove TaskModel conversions
   - Use Task model from data/models directly

2. **Enable full analytics**
   - Use TaskStatistics from SQL queries
   - Build analytics screens with real data

3. **Optimize queries**
   - Add more specific queries as needed
   - Implement pagination for large datasets

4. **Prepare for features**
   - Task categories and filters
   - Search functionality
   - Advanced statistics
   - Reports and exports

---

## ✨ Key Files in Migration

```
lib/
├── main.dart                              ← Initializes both Hive + SQL
├── data/
│   ├── database/
│   │   ├── database_service.dart         ← SQL connection
│   │   └── database_initializer.dart     ← Main API (with DualRepository)
│   ├── repositories/
│   │   ├── task_repository.dart          ← Pure SQL queries
│   │   └── dual_repository.dart          ← Hive + SQL management
│   ├── models/
│   │   ├── task_model.dart               ← SQL Task model
│   │   └── task_statistics.dart          ← Analytics model
│   ├── services/
│   │   └── statistics_service.dart       ← Analytics calculations
│   └── validators/
│       └── input_validator.dart
└── ui/
    └── hive/
        └── task_model.dart               ← Old Hive model (to remove)
```

---

## 💡 Key Principles

✅ **Non-Breaking**: UI continues to work unchanged  
✅ **Safe**: Dual-source prevents data loss  
✅ **Gradual**: Switch to SQL when ready  
✅ **Reversible**: Can revert to Hive if needed  
✅ **Verifiable**: Built-in consistency checks  
✅ **Traceable**: Console logs all operations  

---

## 🎯 Success Criteria

Migration is complete when:

1. ✅ SQL database created and populated
2. ✅ Data consistency verified
3. ✅ All read/write operations working
4. ✅ Analytics queries functioning
5. ✅ Hive removed from codebase
6. ✅ UI working with SQL models only
7. ✅ No performance degradation
8. ✅ No data loss detected

---

**Status**: ✅ **Ready for Testing Phase 1**

Begin with the testing checklist and proceed through the phases. Each phase builds on the previous, ensuring safety and correctness.
