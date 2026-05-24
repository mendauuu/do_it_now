import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:do_it_now/data/models/task_statistics.dart';
import 'package:do_it_now/data/database/database_initializer.dart';

// ── Events ─────────────────────────────────────────────────────────────────────

abstract class StatsEvent extends Equatable {
  const StatsEvent();
  @override
  List<Object?> get props => [];
}

/// Load (or reload) stats. Pass [forceRefresh] to bust the cache.
class LoadStats extends StatsEvent {
  final String filter;
  final bool forceRefresh;
  const LoadStats(this.filter, {this.forceRefresh = false});
  @override
  List<Object?> get props => [filter, forceRefresh];
}

class ChangeFilter extends StatsEvent {
  final String filter;
  const ChangeFilter(this.filter);
  @override
  List<Object?> get props => [filter];
}

// ── States ─────────────────────────────────────────────────────────────────────

abstract class StatsState extends Equatable {
  final String filter;
  const StatsState(this.filter);
  @override
  List<Object?> get props => [filter];
}

class StatsInitial extends StatsState {
  const StatsInitial({String filter = 'Week'}) : super(filter);
}

class StatsLoadInProgress extends StatsState {
  const StatsLoadInProgress(super.filter);
}

class StatsLoadSuccess extends StatsState {
  final TaskStatistics stats;
  final int streak;
  const StatsLoadSuccess(this.stats, this.streak, String filter)
      : super(filter);
  @override
  List<Object?> get props => [stats, streak, filter];
}

class StatsOperationFailure extends StatsState {
  final String error;
  const StatsOperationFailure(this.error, String filter) : super(filter);
  @override
  List<Object?> get props => [error, filter];
}

// ── Bloc ───────────────────────────────────────────────────────────────────────

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final Map<String, TaskStatistics> _cache = {};
  int _streak = 0;

  StatsBloc() : super(const StatsInitial()) {
    on<LoadStats>(_onLoad);
    on<ChangeFilter>(_onChangeFilter);
  }

  Future<void> _onLoad(LoadStats event, Emitter<StatsState> emit) async {
    // Serve from cache if available and not a forced refresh
    if (!event.forceRefresh && _cache.containsKey(event.filter)) {
      emit(StatsLoadSuccess(_cache[event.filter]!, _streak, event.filter));
      return;
    }

    emit(StatsLoadInProgress(event.filter));

    try {
      // Load all three filters in parallel — cheap since it's all from one DB
      final results = await Future.wait([
        DatabaseInitializer.getWeeklyStatistics(),
        DatabaseInitializer.getMonthlyStatistics(),
        DatabaseInitializer.getStatistics(),
      ]);

      _cache['Week'] = results[0];
      _cache['Month'] = results[1];
      _cache['All'] = results[2];
      _streak = await DatabaseInitializer.getStreak();

      emit(StatsLoadSuccess(_cache[event.filter]!, _streak, event.filter));
    } catch (e) {
      emit(StatsOperationFailure(e.toString(), event.filter));
    }
  }

  Future<void> _onChangeFilter(
      ChangeFilter event, Emitter<StatsState> emit) async {
    if (state is StatsLoadSuccess &&
        (state as StatsLoadSuccess).filter == event.filter) {
      return; // already showing this filter
    }

    if (_cache.containsKey(event.filter)) {
      // Instant switch from cache
      emit(StatsLoadSuccess(_cache[event.filter]!, _streak, event.filter));
    } else {
      // Cache not ready yet — trigger a load
      add(LoadStats(event.filter));
    }
  }

  /// Call this after task mutations so stats stay up to date.
  void invalidateCache() {
    _cache.clear();
  }
}
