import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/database/database_initializer.dart';

// EVENTS
abstract class StatsEvent extends Equatable {
  const StatsEvent();
  @override
  List<Object?> get props => [];
}

class LoadStats extends StatsEvent {
  final String filter; // "Week" "Month" "All"
  const LoadStats(this.filter);
  @override
  List<Object?> get props => [filter];
}

// STATES
abstract class StatsState extends Equatable {
  const StatsState();
  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoadInProgress extends StatsState {}

class StatsLoadSuccess extends StatsState {
  final TaskStatistics stats;
  final int streak;
  const StatsLoadSuccess(this.stats, this.streak);
  @override
  List<Object?> get props => [stats, streak];
}

class StatsOperationFailure extends StatsState {
  final String error;
  const StatsOperationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// BLOC
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc() : super(StatsInitial()) {
    on<LoadStats>(_onLoadStats);
  }

  Future<void> _onLoadStats(LoadStats event, Emitter<StatsState> emit) async {
    emit(StatsLoadInProgress());
    try {
      TaskStatistics stats;
      if (event.filter == "Week") {
        stats = await DatabaseInitializer.getWeeklyStatistics();
      } else if (event.filter == "Month") {
        stats = await DatabaseInitializer.getMonthlyStatistics();
      } else {
        stats = await DatabaseInitializer.getStatistics();
      }
      final streak = await DatabaseInitializer.getStreak();
      emit(StatsLoadSuccess(stats, streak));
    } catch (e) {
      emit(StatsOperationFailure(e.toString()));
    }
  }
}
