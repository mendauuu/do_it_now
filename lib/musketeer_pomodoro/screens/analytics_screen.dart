import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pomodoro_sessions_repository.dart';
import '../data/settings_repository.dart';
import '../data/topics_repository.dart';
import '../models.dart';
import 'app_theme.dart';
import 'section_card.dart';

/// Full-screen analytics: today's progress toward the daily goal,
/// streaks, a week/month/year chart, topic and time-of-day
/// breakdowns, and recent sessions. Loads every session once and
/// slices it in memory (see [_Stats]); reloads on pull-to-refresh,
/// since it has no other way to know a session just finished while
/// this screen happens to be open.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

enum _Range { week, month, year }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _sessionsRepository = PomodoroSessionsRepository();
  final _settingsRepository = SettingsRepository();
  final _topicsRepository = TopicsRepository();

  bool _loading = true;
  List<_Session> _sessions = const [];
  PomodoroSettings _settings = const PomodoroSettings();
  Map<String, Color> _topicColors = const {};
  _Range _range = _Range.week;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _sessionsRepository.allSessions();
    final settings = await _settingsRepository.load();
    final topics = await _topicsRepository.loadAll();
    if (!mounted) return;

    setState(() {
      _sessions = rows.map(_Session.fromRow).toList();
      _settings = settings;
      // Same color per topic as the chips on the settings screen.
      _topicColors = {
        for (int i = 0; i < topics.length; i++)
          topics[i].name: kTopicColors[i % kTopicColors.length],
      };
      _loading = false;
    });
  }

  Color _colorFor(String topic) =>
      _topicColors[topic] ??
      kTopicColors[topic.hashCode.abs() % kTopicColors.length];

  void _setRange(_Range range) {
    if (range == _range) return;
    HapticFeedback.selectionClick();
    setState(() => _range = range);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: kInk),
        title: const Text('Your focus time',
            style: TextStyle(color: kInk, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackground, kBackgroundDeep],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kAccent))
              : RefreshIndicator(
                  color: kAccent,
                  onRefresh: _load,
                  child: _buildContent(),
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final stats = _Stats(_sessions, _range, DateTime.now());
    final goalSeconds = _settings.dailyGoalMinutes * 60;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _TodayHero(
          todaySeconds: stats.todaySeconds,
          todaySessions: stats.todaySessions,
          goalSeconds: goalSeconds,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniTile(
                icon: Icons.local_fire_department_rounded,
                color: kAccent,
                value: '${stats.currentStreak}',
                label: 'day streak',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniTile(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFE8A92E),
                value: '${stats.bestStreak}',
                label: 'best streak',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniTile(
                icon: Icons.hourglass_bottom_rounded,
                color: const Color(0xFF6FA85B),
                value: _formatDuration(stats.allTimeSeconds, compact: true),
                label: 'all time',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _RangePicker(range: _range, onChanged: _setRange),
        const SizedBox(height: 16),
        _SummaryCard(stats: stats),
        const SizedBox(height: 16),
        _ChartCard(
          // A new key per range resets the tapped bar and replays the
          // grow-in animation when switching ranges.
          key: ValueKey(_range),
          stats: stats,
          goalSeconds: _range == _Range.year ? null : goalSeconds,
        ),
        const SizedBox(height: 16),
        _TopicCard(stats: stats, colorFor: _colorFor),
        const SizedBox(height: 16),
        _TimeOfDayCard(stats: stats),
        const SizedBox(height: 16),
        _RecentCard(sessions: _sessions, colorFor: _colorFor),
      ],
    );
  }
}

// ── Data ────────────────────────────────────────────────────────

class _Session {
  final bool isFocus;
  final String topic;
  final int seconds;
  final DateTime completedAt;

  const _Session(this.isFocus, this.topic, this.seconds, this.completedAt);

  DateTime get startedAt => completedAt.subtract(Duration(seconds: seconds));

  static _Session fromRow(Map<String, Object?> row) => _Session(
        row['phase'] == 'focus',
        (row['topic_name'] as String?) ?? 'No topic',
        row['duration_seconds'] as int,
        DateTime.parse(row['completed_at'] as String),
      );
}

class _Bucket {
  final String label; // short axis label
  final String title; // shown when the bar is tapped
  final int seconds;
  final bool isCurrent; // today / this month

  const _Bucket(this.label, this.title, this.seconds, this.isCurrent);
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Every number the screen shows, computed in one pass-ish over the
/// focus sessions for the selected range.
class _Stats {
  final _Range range;
  late final List<_Bucket> buckets;
  late final int totalSeconds;
  late final int previousTotalSeconds;
  late final int sessionCount;
  late final int activeDays;
  late final Map<String, int> byTopic;
  late final List<int> byPartOfDay; // morning, afternoon, evening, night
  late final int todaySeconds;
  late final int todaySessions;
  late final int currentStreak;
  late final int bestStreak;
  late final int allTimeSeconds;

  _Stats(List<_Session> all, this.range, DateTime now) {
    final focus = all.where((s) => s.isFocus).toList();
    final today = _dayOf(now);

    // ── Range window and its buckets ──
    late DateTime start;
    late DateTime previousStart;
    if (range == _Range.year) {
      start = DateTime(now.year, now.month - 11);
      previousStart = DateTime(now.year, now.month - 23);
      buckets = [
        for (int i = 0; i < 12; i++)
          () {
            final m = DateTime(start.year, start.month + i);
            final secs = focus
                .where((s) =>
                    s.completedAt.year == m.year &&
                    s.completedAt.month == m.month)
                .fold<int>(0, (sum, s) => sum + s.seconds);
            return _Bucket(_months[m.month - 1][0],
                '${_months[m.month - 1]} ${m.year}', secs, i == 11);
          }(),
      ];
    } else {
      final days = range == _Range.week ? 7 : 30;
      start = today.subtract(Duration(days: days - 1));
      previousStart = start.subtract(Duration(days: days));
      final totals = List<int>.filled(days, 0);
      for (final s in focus) {
        final i = _dayOf(s.completedAt).difference(start).inDays;
        if (i >= 0 && i < days) totals[i] += s.seconds;
      }
      buckets = [
        for (int i = 0; i < days; i++)
          () {
            final d = start.add(Duration(days: i));
            final label = range == _Range.week
                ? _weekdays[d.weekday - 1]
                // Every 5th day (counting back from today) keeps 30
                // bars readable.
                : ((days - 1 - i) % 5 == 0 ? '${d.day}' : '');
            return _Bucket(
              label,
              '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}',
              totals[i],
              i == days - 1,
            );
          }(),
      ];
    }

    final inRange = focus.where((s) => !s.completedAt.isBefore(start));
    totalSeconds = inRange.fold(0, (sum, s) => sum + s.seconds);
    sessionCount = inRange.length;
    activeDays = inRange.map((s) => _dayOf(s.completedAt)).toSet().length;
    previousTotalSeconds = focus
        .where((s) =>
            !s.completedAt.isBefore(previousStart) &&
            s.completedAt.isBefore(start))
        .fold(0, (sum, s) => sum + s.seconds);

    final topics = <String, int>{};
    final parts = List<int>.filled(4, 0);
    for (final s in inRange) {
      topics[s.topic] = (topics[s.topic] ?? 0) + s.seconds;
      final h = s.startedAt.hour;
      final part = h >= 5 && h < 12
          ? 0
          : h >= 12 && h < 17
              ? 1
              : h >= 17 && h < 21
                  ? 2
                  : 3;
      parts[part] += s.seconds;
    }
    byTopic = topics;
    byPartOfDay = parts;

    // ── Today, all time ──
    final todayFocus = focus.where((s) => _dayOf(s.completedAt) == today);
    todaySeconds = todayFocus.fold(0, (sum, s) => sum + s.seconds);
    todaySessions = todayFocus.length;
    allTimeSeconds = focus.fold(0, (sum, s) => sum + s.seconds);

    // ── Streaks (always over all time, not the selected range) ──
    final days = focus.map((s) => _dayOf(s.completedAt)).toSet();
    // A streak isn't broken until today ends without a session, so
    // count back from yesterday if nothing's been done yet today.
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var current = 0;
    while (days.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    currentStreak = current;

    final sorted = days.toList()..sort();
    var best = 0, run = 0;
    for (int i = 0; i < sorted.length; i++) {
      run = i > 0 && sorted[i].difference(sorted[i - 1]).inDays == 1
          ? run + 1
          : 1;
      best = math.max(best, run);
    }
    bestStreak = best;
  }

  String get periodName => switch (range) {
        _Range.week => 'last week',
        _Range.month => 'previous 30 days',
        _Range.year => 'previous year',
      };

  _Bucket? get bestBucket {
    final best = buckets.reduce((a, b) => b.seconds > a.seconds ? b : a);
    return best.seconds == 0 ? null : best;
  }
}

String _formatDuration(int seconds, {bool compact = false}) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60, m = minutes % 60;
  if (compact || m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String _relativeTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  final time = '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
  final days = _dayOf(now).difference(_dayOf(t)).inDays;
  if (days == 0) return 'Today, $time';
  if (days == 1) return 'Yesterday, $time';
  if (days < 7) return '${_weekdays[t.weekday - 1]}, $time';
  return '${_months[t.month - 1]} ${t.day}, $time';
}

// ── Today hero ──────────────────────────────────────────────────

class _TodayHero extends StatelessWidget {
  final int todaySeconds;
  final int todaySessions;
  final int goalSeconds;

  const _TodayHero({
    required this.todaySeconds,
    required this.todaySessions,
    required this.goalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goalSeconds == 0 ? 0.0 : todaySeconds / goalSeconds;
    final reached = progress >= 1;
    final leftMinutes = ((goalSeconds - todaySeconds) / 60).ceil();

    final message = reached
        ? 'Goal reached — great work!'
        : todaySeconds == 0
            ? 'Start a session to get going'
            : '$leftMinutes min left to hit your goal';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8EC9E8), Color(0xFFF4D9A0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => SizedBox(
              width: 112,
              height: 112,
              child: CustomPaint(
                painter: _GoalRingPainter(
                  progress: value,
                  color: reached ? const Color(0xFF6FA85B) : kAccent,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(todaySeconds / 60).round()}',
                        style: const TextStyle(
                            color: kInk,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1),
                      ),
                      Text(
                        'of ${goalSeconds ~/ 60} min',
                        style: const TextStyle(
                            color: kInk,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pill(
                  icon: reached
                      ? Icons.check_circle_rounded
                      : Icons.today_rounded,
                  text: 'Today',
                  color: reached ? const Color(0xFF6FA85B) : kAccent,
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress * 100).clamp(0, 999).round()}%',
                  style: const TextStyle(
                      color: kInk, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                Text(
                  message,
                  style: const TextStyle(
                      color: kInk, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$todaySessions ${todaySessions == 1 ? 'session' : 'sessions'} '
                  'done',
                  style: TextStyle(
                      color: kInk.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GoalRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawCircle(
      rect.center,
      arcRect.width / 2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.progress != progress || old.color != color;
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: kInk, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MiniTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: kInk, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kInkFaint, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Range picker ────────────────────────────────────────────────

class _RangePicker extends StatelessWidget {
  final _Range range;
  final ValueChanged<_Range> onChanged;

  const _RangePicker({required this.range, required this.onChanged});

  static const _labels = {
    _Range.week: 'Week',
    _Range.month: 'Month',
    _Range.year: 'Year',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final r in _Range.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: r == range ? kAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _labels[r]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: r == range ? Colors.white : kInkFaint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Summary ─────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final _Stats stats;

  const _SummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final avg = stats.activeDays == 0 ? 0 : stats.totalSeconds ~/ stats.activeDays;
    final best = stats.bestBucket;

    return SectionCard(
      title: 'Summary',
      icon: Icons.insights_rounded,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDuration(stats.totalSeconds),
              style: const TextStyle(
                  color: kAccent, fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(bottom: 7),
              child: Text('focused',
                  style: TextStyle(color: kInkFaint, fontSize: 13)),
            ),
            const Spacer(),
            _TrendChip(
              current: stats.totalSeconds,
              previous: stats.previousTotalSeconds,
            ),
          ],
        ),
        Text(
          'vs ${stats.periodName}: '
          '${_formatDuration(stats.previousTotalSeconds)}',
          style: const TextStyle(color: kInkFaint, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SummaryStat(
              icon: Icons.check_circle_outline_rounded,
              value: '${stats.sessionCount}',
              label: 'sessions',
            ),
            _SummaryStat(
              icon: Icons.calendar_today_rounded,
              value: '${stats.activeDays}',
              label: 'active days',
            ),
            _SummaryStat(
              icon: Icons.speed_rounded,
              value: _formatDuration(avg),
              label: 'per active day',
            ),
          ],
        ),
        if (best != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A92E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFE8A92E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: stats.range == _Range.year
                          ? 'Best month: '
                          : 'Best day: ',
                      style: const TextStyle(color: kInkFaint, fontSize: 13),
                      children: [
                        TextSpan(
                          text: '${best.title} · '
                              '${_formatDuration(best.seconds)}',
                          style: const TextStyle(
                              color: kInk, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  final int current;
  final int previous;

  const _TrendChip({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    if (current == 0 && previous == 0) return const SizedBox.shrink();

    final String text;
    final bool up;
    if (previous == 0) {
      text = 'New';
      up = true;
    } else {
      final pct = ((current - previous) / previous * 100).round();
      up = pct >= 0;
      text = '${up ? '+' : ''}$pct%';
    }
    final color = up ? const Color(0xFF4E9A3E) : const Color(0xFFC1443B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 16, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: kAccent, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: kInk, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kInkFaint, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Chart ───────────────────────────────────────────────────────

class _ChartCard extends StatefulWidget {
  final _Stats stats;
  final int? goalSeconds; // dashed line on daily charts

  const _ChartCard({super.key, required this.stats, this.goalSeconds});

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final buckets = widget.stats.buckets;
    final goal = widget.goalSeconds;
    final maxSeconds = math.max(
      buckets.fold<int>(1, (m, b) => math.max(m, b.seconds)),
      goal ?? 0,
    );
    final selected = _selected == null ? null : buckets[_selected!];
    final dense = buckets.length > 12;

    return SectionCard(
      title: switch (widget.stats.range) {
        _Range.week => 'Last 7 days',
        _Range.month => 'Last 30 days',
        _Range.year => 'Last 12 months',
      },
      icon: Icons.bar_chart_rounded,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            selected == null
                ? 'Tap a bar to see details'
                : '${selected.title} · ${_formatDuration(selected.seconds)}',
            key: ValueKey(_selected),
            style: TextStyle(
              color: selected == null ? kInkFaint : kInk,
              fontSize: 13,
              fontWeight: selected == null ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const labelSpace = 20.0;
              final barArea = constraints.maxHeight - labelSpace;

              return Stack(
                children: [
                  if (goal != null && goal > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: labelSpace + barArea * goal / maxSeconds,
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomPaint(
                              size: const Size.fromHeight(1),
                              painter: _DashedLinePainter(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.flag_rounded,
                              size: 12, color: Color(0xFF6FA85B)),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < buckets.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(
                                  () => _selected = _selected == i ? null : i);
                            },
                            child: _bar(buckets[i], i, barArea, maxSeconds,
                                dense, goal),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bar(_Bucket b, int i, double barArea, int maxSeconds, bool dense,
      int? goal) {
    final isSelected = _selected == i;
    final metGoal = goal != null && goal > 0 && b.seconds >= goal;
    final color = isSelected
        ? kInk
        : metGoal
            ? const Color(0xFF6FA85B)
            : b.isCurrent
                ? kAccent
                : kAccent.withValues(alpha: 0.55);
    final target = b.seconds == 0 ? 3.0 : barArea * b.seconds / maxSeconds;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 1.5 : 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: math.max(3.0, target)),
            duration: Duration(milliseconds: 500 + i * (dense ? 10 : 40)),
            curve: Curves.easeOutCubic,
            builder: (_, h, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: h,
              decoration: BoxDecoration(
                color: b.seconds == 0 ? kInkFaint.withValues(alpha: 0.2) : color,
                borderRadius: BorderRadius.circular(dense ? 3 : 6),
              ),
            ),
          ),
          SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                b.label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  color: b.isCurrent || isSelected ? kInk : kInkFaint,
                  fontWeight: b.isCurrent || isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6FA85B)
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, size.width), 0),
          paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}

// ── Topics ──────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final _Stats stats;
  final Color Function(String) colorFor;

  const _TopicCard({required this.stats, required this.colorFor});

  @override
  Widget build(BuildContext context) {
    final entries = stats.byTopic.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return SectionCard(
      title: 'By topic',
      icon: Icons.sell_outlined,
      children: [
        if (entries.isEmpty)
          const _EmptyHint(
            icon: Icons.donut_large_rounded,
            text: 'No focus sessions in this period yet.',
          )
        else
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, t, __) => SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: [for (final e in entries) e.value.toDouble()],
                      colors: [for (final e in entries) colorFor(e.key)],
                      progress: t,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${entries.length}',
                              style: const TextStyle(
                                  color: kInk,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text(entries.length == 1 ? 'topic' : 'topics',
                              style: const TextStyle(
                                  color: kInkFaint, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    for (final e in entries.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colorFor(e.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(e.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: kInk,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(
                              '${(e.value / total * 100).round()}%',
                              style: const TextStyle(
                                  color: kInk,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 44,
                              child: Text(
                                _formatDuration(e.value),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    color: kInkFaint, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (entries.length > 5)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('+ ${entries.length - 5} more',
                            style: const TextStyle(
                                color: kInkFaint, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;

  _DonutPainter(
      {required this.values, required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;

    // Small gaps between slices, but only when there's more than one.
    final gap = values.length > 1 ? 0.05 : 0.0;
    var start = -math.pi / 2;
    final sweepTotal = 2 * math.pi * progress;

    for (int i = 0; i < values.length; i++) {
      final sweep = sweepTotal * values[i] / total;
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ── Time of day ─────────────────────────────────────────────────

class _TimeOfDayCard extends StatelessWidget {
  final _Stats stats;

  const _TimeOfDayCard({required this.stats});

  static const _parts = [
    ('Morning', '5–12', Icons.wb_twilight_rounded, Color(0xFFE8A92E)),
    ('Afternoon', '12–17', Icons.wb_sunny_rounded, Color(0xFFD46A2B)),
    ('Evening', '17–21', Icons.nights_stay_rounded, Color(0xFF8F7CB8)),
    ('Night', '21–5', Icons.dark_mode_rounded, Color(0xFF5B4F9E)),
  ];

  @override
  Widget build(BuildContext context) {
    final values = stats.byPartOfDay;
    final maxValue = values.fold<int>(0, math.max);
    final bestIndex = maxValue == 0 ? -1 : values.indexOf(maxValue);

    return SectionCard(
      title: 'When you focus',
      icon: Icons.schedule_rounded,
      subtitle: bestIndex == -1
          ? 'Finish a few sessions to find your best time.'
          : 'You focus most in the ${_parts[bestIndex].$1.toLowerCase()}.',
      children: [
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _tile(i, values[i], maxValue, i == bestIndex)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _tile(int i, int seconds, int maxValue, bool best) {
    final (label, hours, icon, color) = _parts[i];
    final fill = maxValue == 0 ? 0.0 : seconds / maxValue;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: best
            ? color.withValues(alpha: 0.16)
            : kBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: best ? color : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: seconds > 0 ? color : kInkFaint, size: 24),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            width: 10,
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: kInkFaint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, f, __) => FractionallySizedBox(
                  heightFactor: f,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: kInk,
                  fontSize: 12,
                  fontWeight: best ? FontWeight.w700 : FontWeight.w500)),
          Text(_formatDuration(seconds),
              style: const TextStyle(color: kInkFaint, fontSize: 11)),
          Text(hours,
              style: TextStyle(
                  color: kInkFaint.withValues(alpha: 0.7), fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Recent sessions ─────────────────────────────────────────────

class _RecentCard extends StatefulWidget {
  final List<_Session> sessions; // newest first
  final Color Function(String) colorFor;

  const _RecentCard({required this.sessions, required this.colorFor});

  @override
  State<_RecentCard> createState() => _RecentCardState();
}

class _RecentCardState extends State<_RecentCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final focus = widget.sessions.where((s) => s.isFocus).toList();
    final visible = focus.take(_showAll ? 30 : 5).toList();

    return SectionCard(
      title: 'Recent sessions',
      icon: Icons.history_rounded,
      children: [
        if (focus.isEmpty)
          const _EmptyHint(
            icon: Icons.timer_outlined,
            text: 'Your finished focus sessions will show up here.',
          )
        else ...[
          for (final s in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.colorFor(s.topic).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check_rounded,
                        color: widget.colorFor(s.topic), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.topic,
                            style: const TextStyle(
                                color: kInk, fontWeight: FontWeight.w600)),
                        Text(_relativeTime(s.completedAt),
                            style: const TextStyle(
                                color: kInkFaint, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kBackground.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_formatDuration(s.seconds),
                        style: const TextStyle(
                            color: kInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          if (focus.length > 5)
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kAccent),
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(_showAll
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded),
                label: Text(_showAll ? 'Show less' : 'Show more'),
              ),
            ),
        ],
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, size: 36, color: kInkFaint.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kInkFaint)),
        ],
      ),
    );
  }
}
