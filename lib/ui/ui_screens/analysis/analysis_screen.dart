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
  late ClockTheme theme;

  @override
  void initState() {
    super.initState();
    theme = widget.theme;

    context.read<StatsBloc>().add(const LoadStats("Week"));
  }

  @override
  void didUpdateWidget(covariant AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      theme = widget.theme;
    }
  }

  String _getCurrentFilter(StatsState state) {
    if (state is StatsLoadSuccess) return state.filter;
    if (state is StatsLoadInProgress) return state.filter;
    if (state is StatsOperationFailure) return state.filter;
    if (state is StatsInitial) return state.filter;
    return "Week";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.backgroundColor,
            theme.secondaryBackgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<StatsBloc, StatsState>(
          builder: (context, state) {
            final filter = _getCurrentFilter(state);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(filter),
                  const SizedBox(height: 20),
                  _buildFilters(filter),
                  const SizedBox(height: 30),
                  if (state is StatsLoadInProgress)
                    Center(
                      child: CircularProgressIndicator(
                        color: theme.buttonColor,
                      ),
                    ),
                  if (state is StatsOperationFailure)
                    Center(
                      child: Text(
                        state.error,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  if (state is StatsLoadSuccess) ...[
                    _buildSummaryGrid(state.stats, filter),
                    const SizedBox(height: 30),
                    RepaintBoundary(child: _buildBarChart(state.stats)),
                    const SizedBox(height: 30),
                    RepaintBoundary(child: _buildLineChart(state.stats)),
                    const SizedBox(height: 30),
                    RepaintBoundary(child: _buildPieChart(state.stats)),
                    const SizedBox(height: 30),
                    _buildInsights(state.stats, state.streak),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// HEADER
  Widget _buildHeader(String filter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Productivity Analytics",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: theme.textColor),
          onPressed: () {
            context.read<StatsBloc>().add(LoadStats(filter));
          },
        )
      ],
    );
  }

  /// FILTERS
  Widget _buildFilters(String filter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["Week", "Month", "All"].map((f) {
        final selected = filter == f;

        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            context.read<StatsBloc>().add(ChangeFilter(f));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: selected ? theme.hourHandColor : Colors.transparent,
              border: Border.all(color: theme.borderColor),
            ),
            child: Text(
              f,
              style: TextStyle(color: theme.textColor),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// SUMMARY GRID
  Widget _buildSummaryGrid(TaskStatistics stats, String filter) {
    final completed = filter == "Week"
        ? stats.tasksCompletedThisWeek
        : filter == "Month"
            ? stats.tasksCompletedThisMonth
            : stats.completedTasks;

    final completionRate =
        stats.totalTasks == 0 ? 0 : (stats.completedTasks / stats.totalTasks);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _summaryCard("Total Tasks", stats.totalTasks.toString()),
        _summaryCard("Completed", completed.toString()),
        _summaryCard("Pending", stats.pendingTasks.toString()),
        _summaryCard(
          "Completion",
          stats.totalTasks == 0 ? "--" : "${(completionRate * 100).round()}%",
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: theme.borderColor.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor)),
              const SizedBox(height: 5),
              Text(title,
                  style:
                      TextStyle(fontSize: 14, color: theme.secondaryTextColor)),
            ],
          ),
        ),
      ),
    );
  }

  /// BAR CHART
  Widget _buildBarChart(TaskStatistics stats) {
    final data = _extractDailyData(stats);
    final maxValue =
        data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          maxY: maxValue + 2,
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].toDouble(),
                  width: 14,
                  color: theme.minuteHandColor,
                  borderRadius: BorderRadius.circular(6),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// LINE CHART
  Widget _buildLineChart(TaskStatistics stats) {
    final data = _extractDailyData(stats);
    final maxValue =
        data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          maxY: maxValue + 2,
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: theme.hourHandColor,
              barWidth: 3,
              spots: List.generate(
                data.length,
                (i) => FlSpot(i.toDouble(), data[i].toDouble()),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.hourHandColor.withOpacity(0.15),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// PIE CHART
  Widget _buildPieChart(TaskStatistics stats) {
    final total = stats.highPriorityTasks +
        stats.mediumPriorityTasks +
        stats.lowPriorityTasks;

    if (total == 0) {
      return Center(
        child: Text(
          "No tasks yet",
          style: TextStyle(color: theme.secondaryTextColor),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: stats.highPriorityTasks.toDouble(),
              color: theme.errorColor,
              title: "High",
            ),
            PieChartSectionData(
              value: stats.mediumPriorityTasks.toDouble(),
              color: theme.warningColor,
              title: "Medium",
            ),
            PieChartSectionData(
              value: stats.lowPriorityTasks.toDouble(),
              color: theme.successColor,
              title: "Low",
            ),
          ],
        ),
      ),
    );
  }

  /// INSIGHTS
  Widget _buildInsights(TaskStatistics stats, int streak) {
    final completionRate = stats.totalTasks == 0
        ? 0
        : ((stats.completedTasks / stats.totalTasks) * 100).round();

    final insights = <String>[
      if (completionRate > 80)
        "🔥 Excellent productivity! $completionRate% completion.",
      if (completionRate >= 50 && completionRate <= 80)
        "📈 Good progress! Keep going.",
      if (completionRate < 50) "💪 Focus on finishing tasks.",
      if (streak > 0) "🎯 Streak: $streak days",
      if (stats.averageCompletionTime > 0)
        "⏱ Avg completion: ${stats.averageCompletionTime.toStringAsFixed(1)} days"
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.secondaryBackgroundColor.withOpacity(0.3),
      ),
      child: Text(
        insights.join("\n"),
        style: TextStyle(color: theme.textColor, height: 1.6),
      ),
    );
  }

  List<int> _extractDailyData(TaskStatistics stats) {
    return List.generate(
      7,
      (i) => stats.tasksCompletedByDay['day_$i'] ?? 0,
    );
  }
}
