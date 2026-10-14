import 'package:do_it_now/musketeer_pomodoro/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pomodoro_sessions_repository.dart';

class PomodoroSessionsState {
  final int focusSessionsToday;
  final int focusSecondsToday;

  const PomodoroSessionsState({
    this.focusSessionsToday = 0,
    this.focusSecondsToday = 0,
  });
}

/// Bridges completed sessions from MusketeerAnimationScreen into
/// SQLite, and exposes today's totals for an analytics screen to
/// display. Hand its `record` method straight to the screen:
///
///   MusketeerAnimationScreen(
///     onSessionCompleted: context.read<PomodoroSessionsCubit>().record,
///   )
///
/// This is the piece you'd most likely replace outright if Do It Now
/// already has its own sessions/analytics Cubit — in that case, point
/// MusketeerAnimationScreen.onSessionCompleted at your existing one's
/// method instead of this class, and PomodoroSessionsRepository above
/// becomes optional scaffolding rather than something you need.
class PomodoroSessionsCubit extends Cubit<PomodoroSessionsState> {
  final PomodoroSessionsRepository repository;

  PomodoroSessionsCubit(this.repository)
      : super(const PomodoroSessionsState()) {
    _refresh();
  }

  Future<void> record(CompletedSession session) async {
    await repository.record(session);
    await _refresh();
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final rows = await repository.sessionsSince(startOfDay);
    final focusRows = rows.where((r) => r['phase'] == 'focus');

    emit(PomodoroSessionsState(
      focusSessionsToday: focusRows.length,
      focusSecondsToday: focusRows.fold<int>(
        0,
        (sum, r) => sum + (r['duration_seconds'] as int),
      ),
    ));
  }
}
