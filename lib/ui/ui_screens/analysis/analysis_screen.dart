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
  late ClockTheme currentTheme;

  @override
  void initState() {
    super.initState();
    currentTheme = widget.theme;
  }

  @override
  void didUpdateWidget(AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      setState(() {
        currentTheme = widget.theme;
      });
    }
  }

  String _getCurrentFilter(StatsState state) {
    if (state is StatsLoadSuccess) return state.filter;
    if (state is StatsLoadInProgress) return "Week";
    return "Week";
  }

  // Placeholder widget
  Widget _buildPlaceholder(ClockTheme theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.secondaryBackgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSummaryGrid(
      TaskStatistics stats, String filter, ClockTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _summaryItem("Tasks Done", stats.completedTasks, theme),
        _summaryItem("Tasks Pending", stats.pendingTasks, theme),
        _summaryItem("High Priority", stats.highPriorityTasks, theme),
        _summaryItem("Medium Priority", stats.mediumPriorityTasks, theme),
        _summaryItem("Low Priority", stats.lowPriorityTasks, theme),
      ],
    );
  }

  Widget _summaryItem(String title, int value, ClockTheme theme) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor),
        ),
        Text(
          title,
          style: TextStyle(color: theme.secondaryTextColor, fontSize: 12),
        ),
      ],
    );
  }

  // Example bar chart
  Widget _buildBarChart(TaskStatistics stats, ClockTheme theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.secondaryBackgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text("Bar Chart Placeholder",
            style: TextStyle(color: theme.textColor)),
      ),
    );
  }

  Widget _buildLineChart(TaskStatistics stats, ClockTheme theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.secondaryBackgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text("Line Chart Placeholder",
            style: TextStyle(color: theme.textColor)),
      ),
    );
  }

  Widget _buildPieChart(TaskStatistics stats, ClockTheme theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.secondaryBackgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text("Pie Chart Placeholder",
            style: TextStyle(color: theme.textColor)),
      ),
    );
  }

  Widget _buildInsights(TaskStatistics stats, int streak, ClockTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Insights",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textColor),
        ),
        const SizedBox(height: 10),
        Text(
          "Your current streak: $streak days",
          style: TextStyle(color: theme.secondaryTextColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsBloc()..add(const LoadStats("Week")),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              currentTheme.backgroundColor,
              currentTheme.secondaryBackgroundColor,
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
                // Title + refresh
                BlocBuilder<StatsBloc, StatsState>(
                  builder: (context, state) {
                    final currentFilter = _getCurrentFilter(state);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Productivity Analytics",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: currentTheme.textColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh,
                              color: currentTheme.textColor),
                          onPressed: () => context
                              .read<StatsBloc>()
                              .add(LoadStats(currentFilter)),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Filter Buttons
                BlocBuilder<StatsBloc, StatsState>(
                  builder: (context, state) {
                    final currentFilter = _getCurrentFilter(state);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ["Week", "Month", "All"].map((filter) {
                        final selected = currentFilter == filter;
                        return GestureDetector(
                          onTap: () => context
                              .read<StatsBloc>()
                              .add(ChangeFilter(filter)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: selected
                                  ? currentTheme.hourHandColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: currentTheme.borderColor,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: currentTheme.textColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 25),

                BlocBuilder<StatsBloc, StatsState>(
                  builder: (context, state) {
                    if (state is StatsLoadInProgress) {
                      return Column(
                        children: [
                          _buildPlaceholder(currentTheme),
                          const SizedBox(height: 30),
                          _buildPlaceholder(currentTheme),
                        ],
                      );
                    } else if (state is StatsLoadSuccess) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryGrid(
                              state.stats, state.filter, currentTheme),
                          const SizedBox(height: 30),
                          _buildBarChart(state.stats, currentTheme),
                          const SizedBox(height: 30),
                          _buildLineChart(state.stats, currentTheme),
                          const SizedBox(height: 30),
                          _buildPieChart(state.stats, currentTheme),
                          const SizedBox(height: 30),
                          _buildInsights(
                              state.stats, state.streak, currentTheme),
                        ],
                      );
                    } else if (state is StatsOperationFailure) {
                      return Center(
                          child: Text('Error: ${state.error}',
                              style: TextStyle(color: currentTheme.textColor)));
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
}

String _getCurrentFilter(StatsState state) {
  if (state is StatsLoadSuccess) return state.filter;
  if (state is StatsLoadInProgress) return state.filter;
  if (state is StatsOperationFailure) return state.filter;
  if (state is StatsInitial) return state.filter;
  return "Week";
}

// ================= SUMMARY GRID =================

Widget _buildSummaryGrid(
    TaskStatistics stats, String filter, ClockTheme theme) {
  final tasksForPeriod = filter == "Week"
      ? stats.tasksCompletedThisWeek
      : filter == "Month"
          ? stats.tasksCompletedThisMonth
          : stats.completedTasks;

  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 15,
    crossAxisSpacing: 15,
    childAspectRatio: 1.3,
    children: [
      _summaryCard("Total Tasks", stats.totalTasks.toString(), theme),
      _summaryCard("Completed", tasksForPeriod.toString(), theme),
      _summaryCard("Pending", stats.pendingTasks.toString(), theme),
      _summaryCard(
        "Completion Rate",
        stats.totalTasks > 0
            ? '${((stats.completedTasks * 100) / stats.totalTasks).round()}%'
            : '--',
        theme,
      ),
    ],
  );
}

Widget _buildPlaceholder(ClockTheme theme) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: theme.buttonColor,
        ),
      ),
    ),
  );
}

Widget _summaryCard(String title, String value, ClockTheme theme) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.borderColor.withOpacity(0.2),
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
                    color: theme.textColor)),
            const SizedBox(height: 6),
            Text(title,
                style:
                    TextStyle(fontSize: 14, color: theme.secondaryTextColor)),
          ],
        ),
      ),
    ),
  );
}

// ================= BAR CHART (Tasks by Day) =================

Widget _buildBarChart(TaskStatistics stats, ClockTheme theme) {
  final tasksByDay = _extractDailyData(stats);
  final maxValue = tasksByDay.isEmpty
      ? 1.0
      : tasksByDay.reduce((a, b) => a > b ? a : b).toDouble();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Tasks Completed by Day",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
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
                        color: theme.secondaryTextColor,
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
                        color: theme.secondaryTextColor,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(
              tasksByDay.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: tasksByDay[index].toDouble(),
                    color: theme.minuteHandColor,
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

Widget _buildLineChart(TaskStatistics stats, ClockTheme theme) {
  final tasksByDay = _extractDailyData(stats);
  final maxValue = tasksByDay.isEmpty
      ? 1.0
      : tasksByDay.reduce((a, b) => a > b ? a : b).toDouble();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Productivity Trend",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
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
                        color: theme.secondaryTextColor,
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
                        color: theme.secondaryTextColor,
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
                  tasksByDay.length,
                  (index) =>
                      FlSpot(index.toDouble(), tasksByDay[index].toDouble()),
                ),
                color: theme.hourHandColor,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.hourHandColor.withOpacity(0.1),
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

Widget _buildPieChart(TaskStatistics stats, ClockTheme theme) {
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

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Priority Distribution",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      const SizedBox(height: 15),
      SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: stats.highPriorityTasks.toDouble(),
                color: theme.errorColor,
                title: "High (${stats.highPriorityTasks})",
                radius: 50,
              ),
              PieChartSectionData(
                value: stats.mediumPriorityTasks.toDouble(),
                color: theme.warningColor,
                title: "Med (${stats.mediumPriorityTasks})",
                radius: 50,
              ),
              PieChartSectionData(
                value: stats.lowPriorityTasks.toDouble(),
                color: theme.successColor,
                title: "Low (${stats.lowPriorityTasks})",
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

Widget _buildInsights(TaskStatistics stats, int streak, ClockTheme theme) {
  final completionRate = stats.totalTasks > 0
      ? ((stats.completedTasks * 100) / stats.totalTasks).round()
      : 0;

  final highPriorityPending =
      stats.highPriorityTasks > 0 ? stats.highPriorityTasks : 0;

  final insights = <String>[];

  if (completionRate >= 80) {
    insights
        .add("🔥 Excellent productivity! ${completionRate}% completion rate!");
  } else if (completionRate >= 50) {
    insights.add("📈 Good progress! Keep it up!");
  } else {
    insights.add("💪 Let's improve! Focus on pending tasks.");
  }

  if (streak > 0) {
    insights.add("🎯 Current streak: $streak day${streak > 1 ? 's' : ''}!");
  }

  if (highPriorityPending > 0) {
    insights.add(
        "⚠️ You have $highPriorityPending high priority task${highPriorityPending > 1 ? 's' : ''}.");
  }

  if (stats.averageCompletionTime > 0) {
    insights.add(
        "⏱️ Avg completion time: ${stats.averageCompletionTime.toStringAsFixed(1)} days.");
  }

  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: theme.secondaryBackgroundColor.withOpacity(0.3),
    ),
    child: Text(
      insights.join("\n"),
      style: TextStyle(
        fontSize: 15,
        color: theme.textColor,
        height: 1.6,
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

//   Widget _summaryCard(String title, String value) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: widget.theme.borderColor.withOpacity(0.2),
//             ),
//           ),
//           padding: const EdgeInsets.all(15),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(value,
//                   style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: widget.theme.textColor)),
//               const SizedBox(height: 6),
//               Text(title,
//                   style: TextStyle(
//                       fontSize: 14, color: widget.theme.secondaryTextColor)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= BAR CHART (Tasks by Day) =================

//   Widget _buildBarChart() {
//     final maxValue = _tasksByDay.isEmpty
//         ? 1.0
//         : _tasksByDay.reduce((a, b) => a > b ? a : b).toDouble();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Tasks Completed by Day",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: widget.theme.textColor,
//           ),
//         ),
//         const SizedBox(height: 15),
//         SizedBox(
//           height: 200,
//           child: BarChart(
//             BarChartData(
//               borderData: FlBorderData(show: false),
//               titlesData: FlTitlesData(
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (value, meta) {
//                       const days = [
//                         'Mon',
//                         'Tue',
//                         'Wed',
//                         'Thu',
//                         'Fri',
//                         'Sat',
//                         'Sun'
//                       ];
//                       return Text(
//                         days[value.toInt() % 7],
//                         style: TextStyle(
//                           color: widget.theme.secondaryTextColor,
//                           fontSize: 12,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 leftTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (value, meta) {
//                       return Text(
//                         value.toInt().toString(),
//                         style: TextStyle(
//                           color: widget.theme.secondaryTextColor,
//                           fontSize: 10,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               barGroups: List.generate(
//                 _tasksByDay.length,
//                 (index) => BarChartGroupData(
//                   x: index,
//                   barRods: [
//                     BarChartRodData(
//                       toY: _tasksByDay[index].toDouble(),
//                       color: widget.theme.minuteHandColor,
//                       width: 14,
//                       borderRadius: BorderRadius.circular(6),
//                     )
//                   ],
//                 ),
//               ),
//               maxY: (maxValue + 2).ceilToDouble(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ================= LINE CHART (Trend) =================

//   Widget _buildLineChart() {
//     final maxValue = _tasksByDay.isEmpty
//         ? 1.0
//         : _tasksByDay.reduce((a, b) => a > b ? a : b).toDouble();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Productivity Trend",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: widget.theme.textColor,
//           ),
//         ),
//         const SizedBox(height: 15),
//         SizedBox(
//           height: 200,
//           child: LineChart(
//             LineChartData(
//               borderData: FlBorderData(show: false),
//               titlesData: FlTitlesData(
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (value, meta) {
//                       const days = [
//                         'Mon',
//                         'Tue',
//                         'Wed',
//                         'Thu',
//                         'Fri',
//                         'Sat',
//                         'Sun'
//                       ];
//                       return Text(
//                         days[value.toInt() % 7],
//                         style: TextStyle(
//                           color: widget.theme.secondaryTextColor,
//                           fontSize: 12,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 leftTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (value, meta) {
//                       return Text(
//                         value.toInt().toString(),
//                         style: TextStyle(
//                           color: widget.theme.secondaryTextColor,
//                           fontSize: 10,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               lineBarsData: [
//                 LineChartBarData(
//                   isCurved: true,
//                   spots: List.generate(
//                     _tasksByDay.length,
//                     (index) =>
//                         FlSpot(index.toDouble(), _tasksByDay[index].toDouble()),
//                   ),
//                   color: widget.theme.hourHandColor,
//                   barWidth: 3,
//                   dotData: FlDotData(show: true),
//                   belowBarData: BarAreaData(
//                     show: true,
//                     color: widget.theme.hourHandColor.withOpacity(0.1),
//                   ),
//                 )
//               ],
//               maxY: (maxValue + 2).ceilToDouble(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ================= PIE CHART (Priority Distribution) =================

//   Widget _buildPieChart() {
//     if (_stats == null) {
//       return SizedBox(
//         height: 200,
//         child: Center(
//           child: CircularProgressIndicator(color: widget.theme.buttonColor),
//         ),
//       );
//     }

//     final total = _stats!.highPriorityTasks +
//         _stats!.mediumPriorityTasks +
//         _stats!.lowPriorityTasks;

//     if (total == 0) {
//       return Center(
//         child: Text(
//           "No tasks yet",
//           style: TextStyle(color: widget.theme.secondaryTextColor),
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Priority Distribution",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: widget.theme.textColor,
//           ),
//         ),
//         const SizedBox(height: 15),
//         SizedBox(
//           height: 200,
//           child: PieChart(
//             PieChartData(
//               sections: [
//                 PieChartSectionData(
//                   value: _stats!.highPriorityTasks.toDouble(),
//                   color: widget.theme.errorColor,
//                   title: "High (${_stats!.highPriorityTasks})",
//                   radius: 50,
//                 ),
//                 PieChartSectionData(
//                   value: _stats!.mediumPriorityTasks.toDouble(),
//                   color: widget.theme.warningColor,
//                   title: "Med (${_stats!.mediumPriorityTasks})",
//                   radius: 50,
//                 ),
//                 PieChartSectionData(
//                   value: _stats!.lowPriorityTasks.toDouble(),
//                   color: widget.theme.successColor,
//                   title: "Low (${_stats!.lowPriorityTasks})",
//                   radius: 50,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ================= INSIGHTS =================

//   Widget _buildInsights(TaskStatistics stats, int streak, ClockTheme theme) {
//     final completionRate = stats.totalTasks > 0
//         ? ((stats.completedTasks * 100) / stats.totalTasks).round()
//         : 0;

//     final highPriorityPending =
//         stats.highPriorityTasks > 0 ? stats.highPriorityTasks : 0;

//     final insights = <String>[];

//     if (completionRate >= 80) {
//       insights.add(
//           "🔥 Excellent productivity! ${completionRate}% completion rate!");
//     } else if (completionRate >= 50) {
//       insights.add("📈 Good progress! Keep it up!");
//     } else {
//       insights.add("💪 Let's improve! Focus on pending tasks.");
//     }

//     if (streak > 0) {
//       insights.add("🎯 Current streak: $streak day${streak > 1 ? 's' : ''}!");
//     }

//     if (highPriorityPending > 0) {
//       insights.add(
//           "⚠️ You have $highPriorityPending high priority task${highPriorityPending > 1 ? 's' : ''}.");
//     }

//     if (_stats!.averageCompletionTime > 0) {
//       insights.add(
//           "⏱️ Avg completion time: ${_stats!.averageCompletionTime.toStringAsFixed(1)} days.");
//     }

//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         color: widget.theme.secondaryBackgroundColor.withOpacity(0.3),
//       ),
//       child: Text(
//         insights.join("\n"),
//         style: TextStyle(
//           fontSize: 15,
//           color: widget.theme.textColor,
//           height: 1.6,
//         ),
//       ),
//     );
//   }
// }
