import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/database/database_initializer.dart';

/// EVENTS
abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStats extends StatsEvent {
  final String filter;
  const LoadStats(this.filter);

  @override
  List<Object?> get props => [filter];
}

class ChangeFilter extends StatsEvent {
  final String filter;
  const ChangeFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// STATES
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

class StatsLoadSuccess extends StatsState {
  final TaskStatistics stats;
  final int streak;
  final String filter;

  const StatsLoadSuccess(this.stats, this.streak, this.filter);

  @override
  List<Object?> get props => [stats, streak, filter];
}

/// BLOC
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  /// Cache for all statistics
  final Map<String, TaskStatistics> _cache = {};

  int _streak = 0;

  StatsBloc() : super(const StatsInitial()) {
    on<LoadStats>(_onLoadStats);
    on<ChangeFilter>(_onChangeFilter);
  }

  /// Load all statistics once
  Future<void> _onLoadStats(
    LoadStats event,
    Emitter<StatsState> emit,
  ) async {
    try {
      /// If cache already exists → just return it
      if (_cache.isNotEmpty) {
        emit(StatsLoadSuccess(
          _cache[event.filter]!,
          _streak,
          event.filter,
        ));
        return;
      }

      /// Load everything in parallel
      final results = await Future.wait([
        DatabaseInitializer.getWeeklyStatistics(),
        DatabaseInitializer.getMonthlyStatistics(),
        DatabaseInitializer.getStatistics(),
      ]);

      _cache["Week"] = results[0];
      _cache["Month"] = results[1];
      _cache["All"] = results[2];

      _streak = await DatabaseInitializer.getStreak();

      emit(StatsLoadSuccess(
        _cache[event.filter]!,
        _streak,
        event.filter,
      ));
    } catch (e) {
      emit(state);
    }
  }

  /// Switch filters instantly using cache
  Future<void> _onChangeFilter(
    ChangeFilter event,
    Emitter<StatsState> emit,
  ) async {
    if (!_cache.containsKey(event.filter)) return;

    emit(StatsLoadSuccess(
      _cache[event.filter]!,
      _streak,
      event.filter,
    ));
  }
}
