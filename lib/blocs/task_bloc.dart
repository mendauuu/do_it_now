import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/data/database/database_initializer.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final String title;
  final String description;
  final int priority;
  final String category;
  final DateTime? dueDate;

  const AddTask(
    this.title,
    this.description,
    this.priority, {
    this.category = 'General',
    this.dueDate,
  });

  @override
  List<Object?> get props => [title, description, priority, category, dueDate];
}

class EditTask extends TaskEvent {
  final TaskModel task;
  const EditTask(this.task);
  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  /// The SQL id — never the list index.
  final int sqlId;
  const DeleteTask(this.sqlId);
  @override
  List<Object?> get props => [sqlId];
}

class ToggleTask extends TaskEvent {
  final int sqlId;
  final bool isDone;
  const ToggleTask(this.sqlId, this.isDone);
  @override
  List<Object?> get props => [sqlId, isDone];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoadInProgress extends TaskState {}

class TaskLoadSuccess extends TaskState {
  final List<TaskModel> tasks;
  const TaskLoadSuccess(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

class TaskOperationFailure extends TaskState {
  final String error;

  /// Keep the last known task list so the UI doesn't go blank on error.
  final List<TaskModel> previousTasks;
  const TaskOperationFailure(this.error, {this.previousTasks = const []});
  @override
  List<Object?> get props => [error, previousTasks];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc() : super(TaskInitial()) {
    on<LoadTasks>(_onLoad);
    on<AddTask>(_onAdd);
    on<EditTask>(_onEdit);
    on<DeleteTask>(_onDelete);
    on<ToggleTask>(_onToggle);
  }

  List<TaskModel> get _current =>
      state is TaskLoadSuccess ? (state as TaskLoadSuccess).tasks : [];

  Future<void> _onLoad(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoadInProgress());
    try {
      final tasks = await DatabaseInitializer.getAllTasks();
      emit(TaskLoadSuccess(tasks));
    } catch (e) {
      emit(TaskOperationFailure(e.toString()));
    }
  }

  Future<void> _onAdd(AddTask event, Emitter<TaskState> emit) async {
    try {
      final newTask = await DatabaseInitializer.createTask(
        title: event.title,
        description: event.description,
        priority: event.priority,
        category: event.category,
        dueDate: event.dueDate,
      );
      // Prepend so newest appears first — no extra DB round-trip.
      emit(TaskLoadSuccess([newTask, ..._current]));
    } catch (e) {
      emit(TaskOperationFailure(e.toString(), previousTasks: _current));
      emit(TaskLoadSuccess(_current)); // restore
    }
  }

  Future<void> _onEdit(EditTask event, Emitter<TaskState> emit) async {
    try {
      await DatabaseInitializer.updateTask(event.task);
      final updated = _current
          .map((t) => t.sqlId == event.task.sqlId ? event.task : t)
          .toList();
      emit(TaskLoadSuccess(updated));
    } catch (e) {
      emit(TaskOperationFailure(e.toString(), previousTasks: _current));
      emit(TaskLoadSuccess(_current));
    }
  }

  Future<void> _onDelete(DeleteTask event, Emitter<TaskState> emit) async {
    // Optimistic remove
    final optimistic = _current.where((t) => t.sqlId != event.sqlId).toList();
    emit(TaskLoadSuccess(optimistic));
    try {
      await DatabaseInitializer.deleteTask(event.sqlId);
    } catch (e) {
      // Roll back
      emit(TaskOperationFailure(e.toString(), previousTasks: _current));
      emit(TaskLoadSuccess(_current));
    }
  }

  Future<void> _onToggle(ToggleTask event, Emitter<TaskState> emit) async {
    // Optimistic update
    final optimistic = _current
        .map((t) =>
            t.sqlId == event.sqlId ? t.copyWith(isDone: event.isDone) : t)
        .toList();
    emit(TaskLoadSuccess(optimistic));
    try {
      await DatabaseInitializer.toggleTaskCompletion(event.sqlId, event.isDone);
    } catch (e) {
      // Roll back
      emit(TaskOperationFailure(e.toString(), previousTasks: _current));
      emit(TaskLoadSuccess(_current));
    }
  }
}
