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
        child: SingleChildScrollView(
          key: const PageStorageKey("analytics_scroll"),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(theme),
              const SizedBox(height: 20),
              _FilterSelector(theme),
              const SizedBox(height: 30),
              _SummaryGrid(theme),
              const SizedBox(height: 30),
              _BarChartWidget(theme),
              const SizedBox(height: 30),
              _LineChartWidget(theme),
              const SizedBox(height: 30),
              _PieChartWidget(theme),
              const SizedBox(height: 30),
              _InsightsWidget(theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ClockTheme theme;

  const _Header(this.theme);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatsBloc, StatsState, String>(
      selector: (state) {
        if (state is StatsLoadSuccess) return state.filter;
        if (state is StatsLoadInProgress) return state.filter;
        if (state is StatsInitial) return state.filter;
        if (state is StatsOperationFailure) return state.filter;
        return "Week";
      },
      builder: (context, filter) {
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
      },
    );
  }
}

class _FilterSelector extends StatelessWidget {
  final ClockTheme theme;

  const _FilterSelector(this.theme);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatsBloc, StatsState, String>(
      selector: (state) {
        if (state is StatsLoadSuccess) return state.filter;
        if (state is StatsLoadInProgress) return state.filter;
        if (state is StatsInitial) return state.filter;
        if (state is StatsOperationFailure) return state.filter;
        return "Week";
      },
      builder: (context, filter) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: selected ? theme.buttonColor : Colors.transparent,
                  border: Border.all(
                    color: selected ? theme.buttonColor : theme.borderColor,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: selected ? Colors.white : theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final ClockTheme theme;

  const _SummaryGrid(this.theme);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatsBloc, StatsState, TaskStatistics>(
      selector: (state) {
        if (state is StatsLoadSuccess) return state.stats;
        return TaskStatistics.empty();
      },
      builder: (context, stats) {
        final completionRate =
            stats.totalTasks == 0 ? 0 : stats.completedTasks / stats.totalTasks;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.4,
          children: [
            _card("Total Tasks", stats.totalTasks.toString()),
            _card("Completed", stats.completedTasks.toString()),
            _card("Pending", stats.pendingTasks.toString()),
            _card("${(completionRate * 100).round()}%", "Completion"),
          ],
        );
      },
    );
  }

  Widget _card(String value, String title) {
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
}

class _BarChartWidget extends StatelessWidget {
  final ClockTheme theme;

  const _BarChartWidget(this.theme);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatsBloc, StatsState, TaskStatistics>(
      selector: (state) {
        if (state is StatsLoadSuccess) return state.stats;
        return TaskStatistics.empty();
      },
      builder: (context, stats) {
        final data =
            List.generate(7, (i) => stats.tasksCompletedByDay['day_$i'] ?? 0);

        final max = data.reduce((a, b) => a > b ? a : b).toDouble();

        return SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              maxY: max + 2,
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
      },
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final ClockTheme theme;

  const _LineChartWidget(this.theme);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatsBloc, StatsState, TaskStatistics>(
      selector: (state) {
        if (state is StatsLoadSuccess) return state.stats;
        return TaskStatistics.empty();
      },
      builder: (context, stats) {
        final data =
            List.generate(7, (i) => stats.tasksCompletedByDay['day_$i'] ?? 0);

        final max = data.reduce((a, b) => a > b ? a : b).toDouble();

        return SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              borderData: FlBorderData(show: false),
              maxY: max + 2,
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: theme.hourHandColor,
                  barWidth: 3,
                  spots: List.generate(
                    data.length,
                    (i) => FlSpot(i.toDouble(), data[i].toDouble()),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  final ClockTheme theme;

  const _PieChartWidget(this.theme);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatsBloc, StatsState, TaskStatistics>(
      selector: (state) {
        if (state is StatsLoadSuccess) return state.stats;
        return TaskStatistics.empty();
      },
      builder: (context, stats) {
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
      },
    );
  }
}

class _InsightsWidget extends StatelessWidget {
  final ClockTheme theme;

  const _InsightsWidget(this.theme);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StatsBloc, StatsState, (TaskStatistics?, int)>(
      selector: (state) {
        if (state is StatsLoadSuccess) {
          return (state.stats, state.streak);
        }
        return (null, 0);
      },
      builder: (context, data) {
        final stats = data.$1;
        final streak = data.$2;

        if (stats == null) return const SizedBox();

        final completionRate = stats.totalTasks == 0
            ? 0
            : ((stats.completedTasks / stats.totalTasks) * 100).round();

        final insights = <String>[
          if (completionRate > 80)
            "🔥 Excellent productivity! $completionRate% completion.",
          if (completionRate >= 50 && completionRate <= 80)
            "📈 Good progress! Keep going.",
          if (completionRate < 50) "💪 Focus on finishing tasks.",
          if (streak > 0) "🎯 Streak: $streak days"
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
      },
    );
  }
}
