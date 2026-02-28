import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/clock_theme.dart';

class AnalysisScreen extends StatefulWidget {
  final ClockTheme theme;

  const AnalysisScreen({super.key, required this.theme});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String filter = "Week";

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // 🔥 Title
              Text(
                "Productivity Analytics",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),

              const SizedBox(height: 20),

              // 🔄 FILTER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["Week", "Month", "All"].map((e) {
                  final selected = filter == e;
                  return GestureDetector(
                    onTap: () => setState(() => filter = e),
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
          ),
        ),
      ),
    );
  }

  // ================= SUMMARY GRID =================

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _summaryCard("Total Tasks", "124"),
        _summaryCard("Completed", "92"),
        _summaryCard("Pending", "32"),
        _summaryCard("Completion Rate", "74%"),
      ],
    );
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

  // ================= BAR CHART =================

  Widget _buildBarChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          barGroups: List.generate(
            7,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (index + 3) * 2,
                  color: widget.theme.minuteHandColor,
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= LINE CHART =================

  Widget _buildLineChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: List.generate(
                7,
                (index) => FlSpot(index.toDouble(), (index + 2) * 3),
              ),
              color: widget.theme.hourHandColor,
              barWidth: 3,
              dotData: FlDotData(show: false),
            )
          ],
        ),
      ),
    );
  }

  // ================= PIE CHART =================

  Widget _buildPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 40,
              color: widget.theme.hourHandColor,
              title: "Study",
            ),
            PieChartSectionData(
              value: 30,
              color: widget.theme.minuteHandColor,
              title: "Work",
            ),
            PieChartSectionData(
              value: 30,
              color: widget.theme.secondHandColor,
              title: "Life",
            ),
          ],
        ),
      ),
    );
  }

  // ================= INSIGHTS =================

  Widget _buildInsights() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.theme.secondaryBackgroundColor.withOpacity(0.3),
      ),
      child: Text(
        "🔥 You are 23% more productive than last week.\n"
        "📈 Friday is your most productive day.\n"
        "⏳ Most tasks are completed in the evening.",
        style: TextStyle(
          fontSize: 15,
          color: widget.theme.textColor,
        ),
      ),
    );
  }
}
