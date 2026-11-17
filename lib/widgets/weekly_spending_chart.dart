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

  static const weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,

      child: BarChart(
        BarChartData(
          barGroups: List.generate(7, (index) {
            final date = DateTime(
              weekStart.year,
              weekStart.month,
              weekStart.day + index,
            );
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
                  if (value < 0 ||
                      value >= weekdayLabels.length ||
                      value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
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
