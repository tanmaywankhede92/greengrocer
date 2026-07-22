import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../models/dashboard_stats.dart';

class SalesChart extends StatelessWidget {
  final List<SalesData> data;
  const SalesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Monthly Sales', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  if (data.isNotEmpty)
                    Text('${data.length} months', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              if (data.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No sales data available', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: data.map((e) => e.sales).reduce((a, b) => a > b ? a : b) * 1.25,
                        barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final idx = group.x;
                            if (idx < 0 || idx >= data.length) return null;
                            return BarTooltipItem('${data[idx].month}\n₹ ${data[idx].sales.toStringAsFixed(0)}',
                              TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
                          },
                        )),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(data[idx].month,
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: constraints.maxWidth < 500 ? 8 : 10),
                                  overflow: TextOverflow.visible,
                                  maxLines: 1,
                                ),
                              );
                            },
                          )),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (data.map((e) => e.sales).reduce((a, b) => a > b ? a : b) / 4).clamp(100, double.infinity),
                          getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.border, strokeWidth: 0.8),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: data.asMap().entries.map((entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [BarChartRodData(
                            toY: entry.value.sales,
                            color: AppTheme.primaryRed,
                            width: constraints.maxWidth < 500 ? 12 : 18,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4), topRight: Radius.circular(4),
                            ),
                          )],
                        )).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
