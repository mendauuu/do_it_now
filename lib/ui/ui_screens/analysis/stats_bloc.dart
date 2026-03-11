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

/// STATE
class StatsState extends Equatable {
  final TaskStatistics? stats;
  final int streak;
  final String filter;
  final bool loading;

  const StatsState({
    required this.filter,
    this.stats,
    this.streak = 0,
    this.loading = false,
  });

  StatsState copyWith({
    TaskStatistics? stats,
    int? streak,
    String? filter,
    bool? loading,
  }) {
    return StatsState(
      stats: stats ?? this.stats,
      streak: streak ?? this.streak,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [stats, streak, filter, loading];
}

/// BLOC
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  /// cache for instant switching
  final Map<String, TaskStatistics> _cache = {};

  StatsBloc() : super(const StatsState(filter: "Week", loading: true)) {
    on<LoadStats>(_onLoadStats);
    on<ChangeFilter>(_onChangeFilter);
  }

  Future<void> _onLoadStats(
    LoadStats event,
    Emitter<StatsState> emit,
  ) async {
    /// if cached → instant update
    if (_cache.containsKey(event.filter)) {
      emit(state.copyWith(
        filter: event.filter,
        stats: _cache[event.filter],
        loading: false,
      ));
      return;
    }

    /// keep old stats while loading
    emit(state.copyWith(
      filter: event.filter,
      loading: true,
    ));

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

      /// save cache
      _cache[event.filter] = stats;

      emit(state.copyWith(
        stats: stats,
        streak: streak,
        loading: false,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _onChangeFilter(
    ChangeFilter event,
    Emitter<StatsState> emit,
  ) async {
    if (state.filter == event.filter) return;

    add(LoadStats(event.filter));
  }
}
