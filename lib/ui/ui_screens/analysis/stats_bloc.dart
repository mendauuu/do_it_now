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

class ChangeFilter extends StatsEvent {
  final String filter; // "Week" "Month" "All"
  const ChangeFilter(this.filter);
  @override
  List<Object?> get props => [filter];
}

// STATES
abstract class StatsState extends Equatable {
  const StatsState();
  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {
  final String filter;
  const StatsInitial({this.filter = "Week"});
  @override
  List<Object?> get props => [filter];
}

class StatsLoadInProgress extends StatsState {
  final String filter;
  const StatsLoadInProgress(this.filter);
  @override
  List<Object?> get props => [filter];
}

class StatsLoadSuccess extends StatsState {
  final TaskStatistics stats;
  final int streak;
  final String filter;
  const StatsLoadSuccess(this.stats, this.streak, this.filter);
  @override
  List<Object?> get props => [stats, streak, filter];
}

class StatsOperationFailure extends StatsState {
  final String error;
  final String filter;
  const StatsOperationFailure(this.error, this.filter);
  @override
  List<Object?> get props => [error, filter];
}

// BLOC
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc() : super(const StatsInitial()) {
    on<LoadStats>(_onLoadStats);
    on<ChangeFilter>(_onChangeFilter);
  }

  Future<void> _onLoadStats(LoadStats event, Emitter<StatsState> emit) async {
    emit(StatsLoadInProgress(event.filter));
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
      emit(StatsLoadSuccess(stats, streak, event.filter));
    } catch (e) {
      emit(StatsOperationFailure(e.toString(), event.filter));
    }
  }

  Future<void> _onChangeFilter(
      ChangeFilter event, Emitter<StatsState> emit) async {
    // If we're already in the same filter, don't reload
    if (state is StatsLoadSuccess &&
        (state as StatsLoadSuccess).filter == event.filter) {
      return;
    }
    // Load stats for the new filter
    add(LoadStats(event.filter));
  }
}
