import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../providers/bill_provider.dart';

class SalesChart extends ConsumerStatefulWidget {
  const SalesChart({super.key});

  @override
  ConsumerState<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends ConsumerState<SalesChart> {
  late int _selectedYear;
  bool _loading = false;
  List<_MonthSales> _monthlyData = [];
  double _yearTotal = 0;

  static const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final from = '$_selectedYear-01-01';
      final to = '$_selectedYear-12-31';
      final service = ref.read(billServiceProvider);

      int page = 1;
      bool hasMore = true;
      final Map<int, double> monthTotals = {};

      while (hasMore) {
        final result = await service.getAll(
          from: from,
          to: to,
          status: 'active',
          page: page,
          limit: 200,
        );
        for (final b in result.data) {
          final month = b.billDate.month - 1;
          monthTotals[month] = (monthTotals[month] ?? 0) + b.total;
        }
        hasMore = result.data.isNotEmpty && result.data.length >= 200;
        page++;
      }

      final data = List.generate(12, (i) => _MonthSales(
        month: _monthNames[i],
        sales: monthTotals[i] ?? 0,
      ));

      if (mounted) {
        setState(() {
          _monthlyData = data;
          _yearTotal = data.fold(0.0, (s, m) => s + m.sales);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _currentYear => DateTime.now().year;

  List<int> get _availableYears {
    final years = <int>[];
    for (var y = _currentYear; y >= _currentYear - 5; y--) {
      years.add(y);
    }
    return years;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          _buildPeriodLabel(),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed))
                : _yearTotal == 0
                    ? Center(child: Text('No sales data for $_selectedYear', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)))
                    : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.bar_chart, size: 20, color: AppTheme.primaryRed),
        const SizedBox(width: 8),
        const Text('Sales', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryRed.withAlpha(40)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedYear,
              isDense: true,
              style: const TextStyle(color: AppTheme.primaryRed, fontSize: 13, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.primaryRed),
              items: _availableYears.map((y) => DropdownMenuItem(
                value: y,
                child: Text(y.toString()),
              )).toList(),
              onChanged: (v) {
                if (v != null && v != _selectedYear) {
                  setState(() => _selectedYear = v);
                  _loadData();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodLabel() {
    final now = DateTime.now();
    final isCurrentYear = _selectedYear == now.year;

    final String periodText;
    if (isCurrentYear) {
      periodText = 'Jan — ${_monthNames[now.month - 1]} $_selectedYear  •  Total: ${AppUtils.formatCurrency(_yearTotal)}';
    } else {
      periodText = 'Jan — Dec $_selectedYear  •  Total: ${AppUtils.formatCurrency(_yearTotal)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              periodText,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final maxY = _monthlyData.map((e) => e.sales).reduce((a, b) => a > b ? a : b);
    final interval = (maxY / 4).clamp(100.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.25,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= _monthlyData.length) return null;
                final m = _monthlyData[groupIndex];
                return BarTooltipItem(
                  '${m.month} $_selectedYear\n${AppUtils.formatCurrency(m.sales)}',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _monthlyData.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _monthlyData[idx].month,
                    style: TextStyle(
                      color: _isCurrentMonth(idx) ? AppTheme.primaryRed : AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: _isCurrentMonth(idx) ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            )),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.border.withAlpha(180),
              strokeWidth: 0.6,
              dashArray: [4, 3],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _monthlyData.asMap().entries.map((entry) {
            final isCurrent = _isCurrentMonth(entry.key);
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.sales,
                  width: 20,
                  color: isCurrent ? AppTheme.primaryRed : AppTheme.primaryRed.withAlpha(120),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.25,
                    color: AppTheme.background,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isCurrentMonth(int index) {
    return _selectedYear == DateTime.now().year && index == DateTime.now().month - 1;
  }
}

class _MonthSales {
  final String month;
  final double sales;
  const _MonthSales({required this.month, required this.sales});
}
