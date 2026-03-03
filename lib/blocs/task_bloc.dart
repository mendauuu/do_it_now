import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:do_it_now/ui/hive/task_model.dart';
import 'package:do_it_now/data/database/database_initializer.dart';

// EVENTS
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
  const AddTask(this.title, this.description, this.priority);
  @override
  List<Object?> get props => [title, description, priority];
}

class DeleteTask extends TaskEvent {
  final int index;
  const DeleteTask(this.index);
  @override
  List<Object?> get props => [index];
}

class ToggleTask extends TaskEvent {
  final int index;
  final bool isDone;
  const ToggleTask(this.index, this.isDone);
  @override
  List<Object?> get props => [index, isDone];
}

// STATES
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
  const TaskOperationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// BLOC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc() : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTask>(_onToggleTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoadInProgress());
    try {
      final list = await DatabaseInitializer.getAllTasks();
      emit(TaskLoadSuccess(list));
    } catch (e) {
      emit(TaskOperationFailure(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoadSuccess) {
      try {
        await DatabaseInitializer.createTask(
          title: event.title,
          description: event.description,
          priority: event.priority,
        );
        add(LoadTasks());
      } catch (e) {
        emit(TaskOperationFailure(e.toString()));
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoadSuccess) {
      try {
        await DatabaseInitializer.deleteTask(event.index);
        add(LoadTasks());
      } catch (e) {
        emit(TaskOperationFailure(e.toString()));
      }
    }
  }

  Future<void> _onToggleTask(ToggleTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoadSuccess) {
      try {
        await DatabaseInitializer.toggleTaskCompletion(
            event.index, event.isDone);
        // update local state immediately
        final current = (state as TaskLoadSuccess).tasks;
        final updated = List<TaskModel>.from(current);
        final task = updated[event.index];
        updated[event.index] = TaskModel(
          title: task.title,
          description: task.description,
          date: task.date,
          priority: task.priority,
          isDone: event.isDone,
        );
        emit(TaskLoadSuccess(updated));
      } catch (e) {
        emit(TaskOperationFailure(e.toString()));
      }
    }
  }
}
