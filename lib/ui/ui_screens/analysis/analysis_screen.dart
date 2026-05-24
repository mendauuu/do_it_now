import 'dart:math' as math;
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:do_it_now/ui/theme/clock_theme.dart';
import 'package:do_it_now/blocs/stats_bloc.dart';
import 'package:do_it_now/data/models/task_statistics.dart';

/// Full analytics screen — open via Navigator.push.
class AnalysisScreen extends StatefulWidget {
  final ClockTheme theme;
  const AnalysisScreen({super.key, required this.theme});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _filters = ['Week', 'Month', 'All'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _filters.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        context.read<StatsBloc>().add(ChangeFilter(_filters[_tab.index]));
      }
    });
    context.read<StatsBloc>().add(const LoadStats('Week'));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: t.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: t.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              BlocSelector<StatsBloc, StatsState, String>(
                selector: (s) => s.filter,
                builder: (ctx, filter) => IconButton(
                  icon: Icon(Icons.refresh_rounded, color: t.textColor),
                  onPressed: () => ctx
                      .read<StatsBloc>()
                      .add(LoadStats(filter, forceRefresh: true)),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeaderBg(theme: t),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 56),
              title: Text(
                'Analytics',
                style: TextStyle(
                  color: t.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: _FilterTabs(theme: t, controller: _tab, filters: _filters),
            ),
          ),
        ],
        body: BlocBuilder<StatsBloc, StatsState>(
          builder: (ctx, state) {
            if (state is StatsLoadInProgress) {
              return Center(
                child: CircularProgressIndicator(
                    color: t.buttonColor, strokeWidth: 2.5),
              );
            }
            if (state is StatsOperationFailure) {
              return _ErrorView(theme: t, message: state.error);
            }
            final stats = state is StatsLoadSuccess
                ? state.stats
                : TaskStatistics.empty();
            final streak = state is StatsLoadSuccess ? state.streak : 0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // ── Headline numbers ──────────────────────────────────────
                _HeadlineRow(stats: stats, streak: streak, theme: t),
                const SizedBox(height: 20),

                // ── Completion rate ring ──────────────────────────────────
                _SectionLabel('Completion rate', t),
                const SizedBox(height: 12),
                _CompletionRingCard(stats: stats, theme: t),
                const SizedBox(height: 24),

                // ── Daily bar chart ───────────────────────────────────────
                _SectionLabel('Completions per day', t),
                const SizedBox(height: 12),
                _DailyBarChart(stats: stats, theme: t),
                const SizedBox(height: 24),

                // ── Weekly heatmap ────────────────────────────────────────
                _SectionLabel('Activity heatmap', t),
                const SizedBox(height: 12),
                _ActivityHeatmap(stats: stats, theme: t),
                const SizedBox(height: 24),

                // ── Priority breakdown ────────────────────────────────────
                _SectionLabel('Priority breakdown', t),
                const SizedBox(height: 12),
                _PriorityCard(stats: stats, theme: t),
                const SizedBox(height: 24),

                // ── Category chart ────────────────────────────────────────
                if (stats.tasksByCategory.isNotEmpty) ...[
                  _SectionLabel('By category', t),
                  const SizedBox(height: 12),
                  _CategoryCard(stats: stats, theme: t),
                  const SizedBox(height: 24),
                ],

                // ── Avg completion time ───────────────────────────────────
                _SectionLabel('Average completion time', t),
                const SizedBox(height: 12),
                _AvgTimeCard(stats: stats, theme: t),
                const SizedBox(height: 24),

                // ── Insights ──────────────────────────────────────────────
                _InsightsCard(stats: stats, streak: streak, theme: t),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header background with animated gradient blobs
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderBg extends StatefulWidget {
  final ClockTheme theme;
  const _HeaderBg({required this.theme});

  @override
  State<_HeaderBg> createState() => _HeaderBgState();
}

class _HeaderBgState extends State<_HeaderBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _BlobPainter(
          progress: _anim.value,
          color1: widget.theme.accentColor,
          color2: widget.theme.buttonColor,
          bg: widget.theme.backgroundColor,
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  final Color bg;

  _BlobPainter(
      {required this.progress,
      required this.color1,
      required this.color2,
      required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bg);

    // Blob 1
    final p1 = Paint()
      ..shader = RadialGradient(colors: [
        color1.withValues(alpha: 0.35),
        color1.withValues(alpha: 0)
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width * (0.2 + 0.15 * progress),
              size.height * (0.3 + 0.1 * progress)),
          radius: size.width * 0.5));
    canvas.drawCircle(
        Offset(size.width * (0.2 + 0.15 * progress),
            size.height * (0.3 + 0.1 * progress)),
        size.width * 0.5,
        p1);

    // Blob 2
    final p2 = Paint()
      ..shader = RadialGradient(colors: [
        color2.withValues(alpha: 0.25),
        color2.withValues(alpha: 0)
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width * (0.75 - 0.1 * progress),
              size.height * (0.6 - 0.1 * progress)),
          radius: size.width * 0.45));
    canvas.drawCircle(
        Offset(size.width * (0.75 - 0.1 * progress),
            size.height * (0.6 - 0.1 * progress)),
        size.width * 0.45,
        p2);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter tabs
// ─────────────────────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final ClockTheme theme;
  final TabController controller;
  final List<String> filters;

  const _FilterTabs(
      {required this.theme, required this.controller, required this.filters});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      height: 36,
      decoration: BoxDecoration(
        color: theme.secondaryBackgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.2)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.buttonColor,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: theme.secondaryTextColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: filters.map((f) => Tab(text: f, height: 32)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Headline row — 4 stat chips
// ─────────────────────────────────────────────────────────────────────────────

class _HeadlineRow extends StatelessWidget {
  final TaskStatistics stats;
  final int streak;
  final ClockTheme theme;
  const _HeadlineRow(
      {required this.stats, required this.streak, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final rate = stats.totalTasks == 0
        ? 0
        : ((stats.completedTasks / stats.totalTasks) * 100).round();

    return Row(
      children: [
        _chip('${stats.totalTasks}', 'Total', Icons.list_alt_rounded,
            t.infoColor, t),
        const SizedBox(width: 10),
        _chip('${stats.completedTasks}', 'Done',
            Icons.check_circle_outline_rounded, t.successColor, t),
        const SizedBox(width: 10),
        _chip('$rate%', 'Rate', Icons.percent_rounded, t.accentColor, t),
        const SizedBox(width: 10),
        _chip('$streak', 'Streak 🔥', Icons.local_fire_department_rounded,
            t.warningColor, t),
      ],
    );
  }

  Widget _chip(
      String value, String label, IconData icon, Color color, ClockTheme t) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: 0.08),
              border:
                  Border.all(color: color.withValues(alpha: 0.22), width: 1),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: t.textColor)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: t.secondaryTextColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completion rate — animated ring + centre text
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionRingCard extends StatefulWidget {
  final TaskStatistics stats;
  final ClockTheme theme;
  const _CompletionRingCard({required this.stats, required this.theme});

  @override
  State<_CompletionRingCard> createState() => _CompletionRingCardState();
}

class _CompletionRingCardState extends State<_CompletionRingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_CompletionRingCard old) {
    super.didUpdateWidget(old);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final rate = widget.stats.totalTasks == 0
        ? 0.0
        : widget.stats.completedTasks / widget.stats.totalTasks;

    return _card(
      theme: t,
      child: Row(
        children: [
          // Ring
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _DonutPainter(
                  progress: rate * _anim.value,
                  completed: widget.stats.completedTasks,
                  pending: widget.stats.pendingTasks,
                  colorDone: t.successColor,
                  colorPending: t.borderColor.withValues(alpha: 0.2),
                  strokeWidth: 12,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(rate * 100 * _anim.value).round()}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: t.textColor,
                        ),
                      ),
                      Text('done',
                          style: TextStyle(
                              fontSize: 11, color: t.secondaryTextColor)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(t.successColor, 'Completed',
                    '${widget.stats.completedTasks}', t),
                const SizedBox(height: 10),
                _legendRow(t.warningColor, 'Pending',
                    '${widget.stats.pendingTasks}', t),
                const SizedBox(height: 10),
                _legendRow(
                    t.infoColor, 'Total', '${widget.stats.totalTasks}', t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color c, String label, String value, ClockTheme t) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: t.secondaryTextColor)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.textColor)),
        ],
      );
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final int completed;
  final int pending;
  final Color colorDone;
  final Color colorPending;
  final double strokeWidth;

  _DonutPainter({
    required this.progress,
    required this.completed,
    required this.pending,
    required this.colorDone,
    required this.colorPending,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = colorPending
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final donePaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + 2 * math.pi * progress,
          colors: [colorDone.withValues(alpha: 0.7), colorDone],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        donePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily bar chart with day labels
// ─────────────────────────────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final TaskStatistics stats;
  final ClockTheme theme;
  const _DailyBarChart({required this.stats, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final entries = stats.tasksCompletedByDay.entries.toList();
    if (entries.isEmpty) return _emptyChart(t);

    final maxY = entries
            .map((e) => e.value)
            .fold(0, (a, b) => a > b ? a : b)
            .toDouble() +
        1;

    return _card(
      theme: t,
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: t.borderColor.withValues(alpha: 0.12),
                strokeWidth: 1,
              ),
            ),
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => t.secondaryBackgroundColor,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${rod.toY.toInt()} tasks',
                  TextStyle(color: t.textColor, fontSize: 12),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final parts = entries[i].key.split(' ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            parts.length > 1 ? parts[0] : '',
                            style: TextStyle(
                                fontSize: 9,
                                color: t.secondaryTextColor
                                    .withValues(alpha: 0.6)),
                          ),
                          Text(
                            parts.length > 1 ? parts[1] : parts[0],
                            style: TextStyle(
                                fontSize: 11,
                                color: t.secondaryTextColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: t.secondaryTextColor),
                  ),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(
              entries.length,
              (i) {
                final isToday = i == entries.length - 1;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value.toDouble(),
                      width: 20,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: LinearGradient(
                        colors: isToday
                            ? [t.accentColor, t.buttonColor]
                            : [
                                t.buttonColor.withValues(alpha: 0.5),
                                t.buttonColor.withValues(alpha: 0.8)
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          swapAnimationDuration: const Duration(milliseconds: 500),
          swapAnimationCurve: Curves.easeOut,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity heatmap — 7 columns × N rows showing completion intensity
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityHeatmap extends StatelessWidget {
  final TaskStatistics stats;
  final ClockTheme theme;
  const _ActivityHeatmap({required this.stats, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final entries = stats.tasksCompletedByDay.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return _card(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day-of-week headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 10,
                                color: t.secondaryTextColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Cells — one per day in the entries list padded to full weeks
          _buildGrid(entries, maxVal, t),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less',
                  style: TextStyle(fontSize: 10, color: t.secondaryTextColor)),
              const SizedBox(width: 4),
              for (int i = 0; i < 5; i++) ...[
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _cellColor(i / 4, t),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Text('More',
                  style: TextStyle(fontSize: 10, color: t.secondaryTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
      List<MapEntry<String, int>> entries, int maxVal, ClockTheme t) {
    // Pad to a multiple of 7
    final padded = List<MapEntry<String, int>?>.from(entries);
    while (padded.length % 7 != 0) {
      padded.insert(0, null);
    }

    final rows = padded.length ~/ 7;
    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (col) {
              final entry = padded[row * 7 + col];
              final intensity =
                  (maxVal == 0 || entry == null) ? 0.0 : entry.value / maxVal;
              return Expanded(
                child: Tooltip(
                  message: entry == null
                      ? ''
                      : '${entry.key}: ${entry.value} task(s)',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _cellColor(intensity, t),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Color _cellColor(double intensity, ClockTheme t) {
    if (intensity <= 0) return t.borderColor.withValues(alpha: 0.1);
    return Color.lerp(
      t.successColor.withValues(alpha: 0.25),
      t.successColor,
      intensity,
    )!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Priority breakdown — horizontal stacked bar
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityCard extends StatelessWidget {
  final TaskStatistics stats;
  final ClockTheme theme;
  const _PriorityCard({required this.stats, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final total = stats.highPriorityTasks +
        stats.mediumPriorityTasks +
        stats.lowPriorityTasks;
    if (total == 0) return _emptyChart(t);

    final items = [
      _PItem('High', stats.highPriorityTasks, t.errorColor),
      _PItem('Medium', stats.mediumPriorityTasks, t.warningColor),
      _PItem('Low', stats.lowPriorityTasks, t.successColor),
    ];

    return _card(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: items.map((item) {
                final flex = ((item.count / total) * 100).round();
                if (flex == 0) return const SizedBox.shrink();
                return Flexible(
                  flex: flex,
                  child: Container(
                    height: 18,
                    color: item.color,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Legend rows
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.label,
                          style: TextStyle(fontSize: 14, color: t.textColor)),
                    ),
                    Text('${item.count}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.textColor)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        total == 0
                            ? '0%'
                            : '${((item.count / total) * 100).round()}%',
                        style: TextStyle(
                            fontSize: 12, color: t.secondaryTextColor),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PItem {
  final String label;
  final int count;
  final Color color;
  _PItem(this.label, this.count, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Category horizontal bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final TaskStatistics stats;
  final ClockTheme theme;
  const _CategoryCard({required this.stats, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final entries = stats.tasksByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    final colors = [
      t.buttonColor,
      t.accentColor,
      t.successColor,
      t.warningColor,
      t.infoColor,
      t.errorColor,
    ];

    return _card(
      theme: t,
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: TextStyle(
                            fontSize: 13,
                            color: t.textColor,
                            fontWeight: FontWeight.w500)),
                    Text('${e.value}',
                        style: TextStyle(
                            fontSize: 13,
                            color: t.secondaryTextColor,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 5),
                LayoutBuilder(builder: (_, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 8,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: t.borderColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        height: 8,
                        width: constraints.maxWidth * pct,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.6), color],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Average completion time card
// ─────────────────────────────────────────────────────────────────────────────

class _AvgTimeCard extends StatelessWidget {
  final TaskStatistics stats;
  final ClockTheme theme;
  const _AvgTimeCard({required this.stats, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final hours = stats.averageCompletionTime;
    final display = hours < 24
        ? '${hours.toStringAsFixed(1)}h'
        : '${(hours / 24).toStringAsFixed(1)}d';

    return _card(
      theme: t,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.timer_outlined, color: t.accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hours == 0 ? 'No data yet' : display,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: t.textColor),
                ),
                Text(
                  'average time to complete a task',
                  style: TextStyle(fontSize: 13, color: t.secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights card
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsCard extends StatelessWidget {
  final TaskStatistics stats;
  final int streak;
  final ClockTheme theme;
  const _InsightsCard(
      {required this.stats, required this.streak, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final rate = stats.totalTasks == 0
        ? 0
        : ((stats.completedTasks / stats.totalTasks) * 100).round();

    final insights = <_Insight>[
      if (stats.totalTasks == 0)
        _Insight('📝', 'No tasks this period',
            'Add tasks to start tracking your productivity.', t.infoColor),
      if (rate >= 80 && stats.totalTasks > 0)
        _Insight('🔥', 'On fire!',
            '$rate% of tasks completed. Outstanding work.', t.successColor),
      if (rate >= 50 && rate < 80 && stats.totalTasks > 0)
        _Insight('📈', 'Good progress',
            '$rate% done. Stay consistent to hit 80%.', t.warningColor),
      if (rate < 50 && stats.totalTasks > 0)
        _Insight(
            '💪',
            'Room to grow',
            'Only $rate% completed. Try tackling high-priority tasks first.',
            t.errorColor),
      if (streak >= 3)
        _Insight(
            '🎯',
            '$streak-day streak!',
            'You\'ve completed tasks every day for $streak days.',
            t.accentColor),
      if (stats.highPriorityTasks > 0 && stats.pendingTasks > 0)
        _Insight(
            '⚠️',
            'High priority pending',
            '${stats.highPriorityTasks} high-priority task(s) waiting.',
            t.errorColor),
      if (stats.tasksCompletedThisWeek > 0)
        _Insight(
            '📅',
            'This week',
            '${stats.tasksCompletedThisWeek} task(s) completed in the last 7 days.',
            t.infoColor),
    ];

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Insights', t),
        const SizedBox(height: 12),
        ...insights.map((ins) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _card(
                theme: t,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(ins.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ins.title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ins.color)),
                          const SizedBox(height: 2),
                          Text(ins.body,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: t.secondaryTextColor,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _Insight {
  final String emoji;
  final String title;
  final String body;
  final Color color;
  _Insight(this.emoji, this.title, this.body, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _SectionLabel(String text, ClockTheme t) => Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: t.secondaryTextColor,
        letterSpacing: 0.6,
      ),
    );

Widget _card({
  required ClockTheme theme,
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(18),
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.cardColor.withValues(alpha: 0.7),
          border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.18), width: 1),
        ),
        child: child,
      ),
    ),
  );
}

Widget _emptyChart(ClockTheme t) => SizedBox(
      height: 100,
      child: Center(
        child: Text('No data for this period',
            style: TextStyle(color: t.secondaryTextColor, fontSize: 14)),
      ),
    );

class _ErrorView extends StatelessWidget {
  final ClockTheme theme;
  final String message;
  const _ErrorView({required this.theme, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.errorColor.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text('Failed to load stats',
                style: TextStyle(color: theme.textColor, fontSize: 15)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(message,
                  style:
                      TextStyle(color: theme.secondaryTextColor, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      );
}
