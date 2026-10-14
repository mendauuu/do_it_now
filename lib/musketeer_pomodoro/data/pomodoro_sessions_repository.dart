import '../models.dart';
import 'app_database.dart';

class TodayFocusTotals {
  final int seconds;
  final int sessionCount;

  const TodayFocusTotals({required this.seconds, required this.sessionCount});
}

/// Reads and writes completed Pomodoro sessions to the local
/// database, and answers the questions the analytics screen needs
/// (totals by topic, totals by day).
class PomodoroSessionsRepository {
  static const table = 'pomodoro_sessions';

  Future<void> record(CompletedSession session) async {
    final db = await AppDatabase.open();
    await db.insert(table, {
      'phase': session.phase == PomodoroPhase.focus ? 'focus' : 'break',
      'topic_id': session.topicId,
      'topic_name': session.topicName,
      'duration_seconds': session.durationSeconds,
      'completed_at': session.completedAt.toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> sessionsSince(DateTime start) async {
    final db = await AppDatabase.open();
    return db.query(
      table,
      where: 'completed_at >= ?',
      whereArgs: [start.toIso8601String()],
      orderBy: 'completed_at DESC',
    );
  }

  /// Every recorded session, newest first. Session rows are tiny, so
  /// the analytics screen loads them all once and slices them in
  /// memory rather than running a query per chart.
  Future<List<Map<String, Object?>>> allSessions() async {
    final db = await AppDatabase.open();
    return db.query(table, orderBy: 'completed_at DESC');
  }

  /// Total focus seconds and session count for today.
  Future<TodayFocusTotals> todayFocusTotals() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final rows = await sessionsSince(startOfDay);
    final focusRows = rows.where((r) => r['phase'] == 'focus');

    return TodayFocusTotals(
      seconds: focusRows.fold<int>(
          0, (sum, r) => sum + (r['duration_seconds'] as int)),
      sessionCount: focusRows.length,
    );
  }

  /// Total focus seconds per topic since [start], keyed by topic
  /// name — falls back to "No topic" for rows saved before topics
  /// existed, or a deleted custom topic.
  Future<Map<String, int>> focusSecondsByTopic(DateTime start) async {
    final rows = await sessionsSince(start);
    final totals = <String, int>{};

    for (final row in rows) {
      if (row['phase'] != 'focus') continue;
      final name = (row['topic_name'] as String?) ?? 'No topic';
      final seconds = row['duration_seconds'] as int;
      totals[name] = (totals[name] ?? 0) + seconds;
    }

    return totals;
  }

  /// Total focus seconds per day for the last [days] days, oldest
  /// first — for a simple week-view bar chart.
  Future<List<int>> dailyFocusSeconds(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final rows = await sessionsSince(start);

    final totals = List<int>.filled(days, 0);
    for (final row in rows) {
      if (row['phase'] != 'focus') continue;
      final completedAt = DateTime.parse(row['completed_at'] as String);
      final dayIndex =
          DateTime(completedAt.year, completedAt.month, completedAt.day)
              .difference(start)
              .inDays;
      if (dayIndex >= 0 && dayIndex < days) {
        totals[dayIndex] += row['duration_seconds'] as int;
      }
    }

    return totals;
  }
}
