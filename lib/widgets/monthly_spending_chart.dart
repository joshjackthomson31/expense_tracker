import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlySpendingChart extends StatelessWidget {
  final Map<DateTime, double> monthlySpending;

  const MonthlySpendingChart({super.key, required this.monthlySpending});

  static const monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final months = monthlySpending.keys.toList();

    return SizedBox(
      height: 300,

      child: BarChart(
        BarChartData(
          barGroups: List.generate(months.length, (index) {
            final amount = monthlySpending[months[index]] ?? 0;

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
                  final index = value.toInt();

                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }

                  return Text(monthLabels[months[index].month - 1]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
