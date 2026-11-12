import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklySpendingChart extends StatelessWidget {
  final Map<DateTime, double> dailySpending;
  final DateTime weekStart;

  const WeeklySpendingChart({
    super.key,
    required this.dailySpending,
    required this.weekStart,
  });

  static const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,

      child: BarChart(
        BarChartData(
          barGroups: List.generate(7, (index) {
            final date = weekStart.add(Duration(days: index));
            final amount = dailySpending[date] ?? 0;

            return BarChartGroupData(
              x: index,

              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,

                getTitlesWidget: (value, meta) {
                  return Text(weekdayLabels[value.toInt()]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
