import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/clock_theme.dart';
import '../../../blocs/stats_bloc.dart';
import 'package:do_it_now/data/models/task_statistics.dart';

class AnalysisScreen extends StatefulWidget {
  final ClockTheme theme;

  const AnalysisScreen({super.key, required this.theme});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String filter = "Week";
  late StatsBloc _statsBloc;
  TaskStatistics? _stats;
  List<int> _tasksByDay = [];
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _statsBloc = StatsBloc()..add(LoadStats(filter));
  }

  @override
  Widget build(BuildContext context) {
    // re-add structure up to filter row for diagnostics
    return BlocProvider.value(
      value: _statsBloc,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.theme.backgroundColor,
              widget.theme.secondaryBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 Title + refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Productivity Analytics",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: widget.theme.textColor),
                      onPressed: () => _statsBloc.add(LoadStats(filter)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔄 FILTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ["Week", "Month", "All"].map((e) {
                    final selected = filter == e;
                    return GestureDetector(
                      onTap: () {
                        setState(() => filter = e);
                        _statsBloc.add(LoadStats(filter));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: selected
                              ? widget.theme.hourHandColor
                              : Colors.transparent,
                          border: Border.all(
                            color: widget.theme.borderColor,
                          ),
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: widget.theme.textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 25),

                BlocBuilder<StatsBloc, StatsState>(
                  builder: (context, state) {
                    if (state is StatsLoadInProgress) {
                      return Column(
                        children: [
                          _buildPlaceholder(),
                          const SizedBox(height: 30),
                          _buildPlaceholder(),
                        ],
                      );
                    } else if (state is StatsLoadSuccess) {
                      // update locals for later helper widgets
                      _tasksByDay = _extractDailyData(state.stats);
                      _streak = state.streak;
                      _stats = state.stats;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryGrid(),
                          const SizedBox(height: 30),
                          _buildBarChart(),
                          const SizedBox(height: 30),
                          _buildLineChart(),
                          const SizedBox(height: 30),
                          _buildPieChart(),
                          const SizedBox(height: 30),
                          _buildInsights(),
                        ],
                      );
                    } else if (state is StatsOperationFailure) {
                      return Center(
                          child: Text('Error: ${state.error}',
                              style: TextStyle(color: widget.theme.textColor)));
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= SUMMARY GRID =================

  Widget _buildSummaryGrid() {
    if (_stats == null) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.3,
        children: List.generate(4, (index) => _buildPlaceholder()),
      );
    }

    final tasksForPeriod = filter == "Week"
        ? _stats!.tasksCompletedThisWeek
        : filter == "Month"
            ? _stats!.tasksCompletedThisMonth
            : _stats!.completedTasks;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _summaryCard("Total Tasks", _stats?.totalTasks.toString() ?? '--'),
        _summaryCard("Completed", tasksForPeriod.toString()),
        _summaryCard("Pending", _stats?.pendingTasks.toString() ?? '--'),
        _summaryCard(
          "Completion Rate",
          _stats != null
              ? '${(_stats!.totalTasks > 0 ? ((_stats!.completedTasks * 100) / _stats!.totalTasks).round() : 0)}%'
              : '--',
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: widget.theme.buttonColor,
          ),
        ),
      ),
    );
  }

  List<int> _extractDailyData(TaskStatistics? stats) {
    if (stats == null || stats.tasksCompletedByDay.isEmpty) {
      return List.generate(7, (i) => 0);
    }

    final List<int> data = [];
    for (int i = 0; i < 7; i++) {
      final dayKey = 'day_$i';
      data.add(stats.tasksCompletedByDay[dayKey] ?? 0);
    }
    return data;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _summaryCard(String title, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.theme.borderColor.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.textColor)),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 14, color: widget.theme.secondaryTextColor)),
            ],
          ),
        ),
      ),
    );
  }

  // ================= BAR CHART (Tasks by Day) =================

  Widget _buildBarChart() {
    final maxValue = _tasksByDay.isEmpty
        ? 1.0
        : _tasksByDay.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tasks Completed by Day",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      return Text(
                        days[value.toInt() % 7],
                        style: TextStyle(
                          color: widget.theme.secondaryTextColor,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: widget.theme.secondaryTextColor,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(
                _tasksByDay.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: _tasksByDay[index].toDouble(),
                      color: widget.theme.minuteHandColor,
                      width: 14,
                      borderRadius: BorderRadius.circular(6),
                    )
                  ],
                ),
              ),
              maxY: (maxValue + 2).ceilToDouble(),
            ),
          ),
        ),
      ],
    );
  }

  // ================= LINE CHART (Trend) =================

  Widget _buildLineChart() {
    final maxValue = _tasksByDay.isEmpty
        ? 1.0
        : _tasksByDay.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Productivity Trend",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      return Text(
                        days[value.toInt() % 7],
                        style: TextStyle(
                          color: widget.theme.secondaryTextColor,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: widget.theme.secondaryTextColor,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: List.generate(
                    _tasksByDay.length,
                    (index) =>
                        FlSpot(index.toDouble(), _tasksByDay[index].toDouble()),
                  ),
                  color: widget.theme.hourHandColor,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: widget.theme.hourHandColor.withOpacity(0.1),
                  ),
                )
              ],
              maxY: (maxValue + 2).ceilToDouble(),
            ),
          ),
        ),
      ],
    );
  }

  // ================= PIE CHART (Priority Distribution) =================

  Widget _buildPieChart() {
    if (_stats == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: widget.theme.buttonColor),
        ),
      );
    }

    final total = _stats!.highPriorityTasks +
        _stats!.mediumPriorityTasks +
        _stats!.lowPriorityTasks;

    if (total == 0) {
      return Center(
        child: Text(
          "No tasks yet",
          style: TextStyle(color: widget.theme.secondaryTextColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Priority Distribution",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: _stats!.highPriorityTasks.toDouble(),
                  color: widget.theme.errorColor,
                  title: "High (${_stats!.highPriorityTasks})",
                  radius: 50,
                ),
                PieChartSectionData(
                  value: _stats!.mediumPriorityTasks.toDouble(),
                  color: widget.theme.warningColor,
                  title: "Med (${_stats!.mediumPriorityTasks})",
                  radius: 50,
                ),
                PieChartSectionData(
                  value: _stats!.lowPriorityTasks.toDouble(),
                  color: widget.theme.successColor,
                  title: "Low (${_stats!.lowPriorityTasks})",
                  radius: 50,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= INSIGHTS =================

  Widget _buildInsights() {
    if (_stats == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.theme.secondaryBackgroundColor.withOpacity(0.3),
        ),
        child: Center(
          child: CircularProgressIndicator(color: widget.theme.buttonColor),
        ),
      );
    }

    final completionRate = _stats!.totalTasks > 0
        ? ((_stats!.completedTasks * 100) / _stats!.totalTasks).round()
        : 0;

    final highPriorityPending =
        _stats!.highPriorityTasks > 0 ? _stats!.highPriorityTasks : 0;

    final insights = <String>[];

    if (completionRate >= 80) {
      insights.add(
          "🔥 Excellent productivity! ${completionRate}% completion rate!");
    } else if (completionRate >= 50) {
      insights.add("📈 Good progress! Keep it up!");
    } else {
      insights.add("💪 Let's improve! Focus on pending tasks.");
    }

    if (_streak > 0) {
      insights.add("🎯 Current streak: $_streak day${_streak > 1 ? 's' : ''}!");
    }

    if (highPriorityPending > 0) {
      insights.add(
          "⚠️ You have $highPriorityPending high priority task${highPriorityPending > 1 ? 's' : ''}.");
    }

    if (_stats!.averageCompletionTime > 0) {
      insights.add(
          "⏱️ Avg completion time: ${_stats!.averageCompletionTime.toStringAsFixed(1)} days.");
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.theme.secondaryBackgroundColor.withOpacity(0.3),
      ),
      child: Text(
        insights.join("\n"),
        style: TextStyle(
          fontSize: 15,
          color: widget.theme.textColor,
          height: 1.6,
        ),
      ),
    );
  }
}
