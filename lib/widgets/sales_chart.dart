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

class _SalesChartState extends ConsumerState<SalesChart>
    with SingleTickerProviderStateMixin {
  late int _selectedYear;
  bool _loading = false;
  List<_MonthSales> _monthlyData = [];
  double _yearTotal = 0;
  int _touchedIndex = -1;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

      final data = List.generate(
        12,
        (i) => _MonthSales(month: _monthNames[i], sales: monthTotals[i] ?? 0),
      );

      if (mounted) {
        setState(() {
          _monthlyData = data;
          _yearTotal = data.fold(0.0, (s, m) => s + m.sales);
          _loading = false;
        });
        _animController
          ..reset()
          ..forward();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _currentYear => DateTime.now().year;

  List<int> get _availableYears {
    return [for (var y = _currentYear; y >= _currentYear - 5; y--) y];
  }

  bool _isCurrentMonth(int index) {
    return _selectedYear == DateTime.now().year &&
        index == DateTime.now().month - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          _buildPeriodLabel(),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryRed,
                    ),
                  )
                : _yearTotal == 0
                    ? _buildEmptyState()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildChart(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.show_chart,
            size: 18,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Sales Analytics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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
              style: const TextStyle(
                color: AppTheme.primaryRed,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.primaryRed,
              ),
              items: _availableYears
                  .map((y) => DropdownMenuItem(
                      value: y, child: Text(y.toString())))
                  .toList(),
              onChanged: (v) {
                if (v != null && v != _selectedYear) {
                  setState(() {
                    _selectedYear = v;
                    _touchedIndex = -1;
                  });
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
      periodText =
          'Jan \u2014 ${_monthNames[now.month - 1]} $_selectedYear  \u2022  Total: ${AppUtils.formatCurrency(_yearTotal)}';
    } else {
      periodText =
          'Jan \u2014 Dec $_selectedYear  \u2022  Total: ${AppUtils.formatCurrency(_yearTotal)}';
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
          const Icon(
            Icons.date_range,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              periodText,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 40,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Sales Data Available',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No bills were recorded for $_selectedYear',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final maxY =
        _monthlyData.map((e) => e.sales).reduce((a, b) => a > b ? a : b);
    final topValue = maxY > 0 ? maxY * 1.3 : 100.0;
    final interval = (topValue / 4).clamp(100.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: topValue,
          lineTouchData: LineTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (response?.lineBarSpots != null &&
                  response!.lineBarSpots!.isNotEmpty) {
                setState(() =>
                    _touchedIndex = response.lineBarSpots!.first.spotIndex);
              } else {
                setState(() => _touchedIndex = -1);
              }
            },
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 12,
              getTooltipColor: (_) => AppTheme.primaryRed,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final m = _monthlyData[spot.spotIndex];
                  return LineTooltipItem(
                    '${m.month} $_selectedYear\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: AppUtils.formatCurrency(m.sales),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, indicators) {
              return indicators.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: AppTheme.primaryRed.withAlpha(80),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppTheme.primaryRed,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _monthlyData.length) {
                    return const SizedBox.shrink();
                  }
                  final isCurrent = _isCurrentMonth(idx);
                  final isTouched = idx == _touchedIndex;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      _monthlyData[idx].month,
                      style: TextStyle(
                        color: isCurrent
                            ? AppTheme.primaryRed
                            : isTouched
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                        fontSize: isCurrent || isTouched ? 11 : 10,
                        fontWeight: isCurrent || isTouched
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.border.withAlpha(120),
              strokeWidth: 0.6,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(i.toDouble(), _monthlyData[i].sales),
              ),
              isCurved: true,
              preventCurveOverShooting: true,
              barWidth: 2.5,
              isStrokeCapRound: true,
              color: AppTheme.primaryRed,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isCurrent = _isCurrentMonth(index);
                  final isTouched = index == _touchedIndex;
                  if (isCurrent) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: AppTheme.primaryRed,
                      strokeWidth: 2.5,
                      strokeColor: Colors.white,
                    );
                  }
                  if (isTouched) {
                    return FlDotCirclePainter(
                      radius: 4.5,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppTheme.primaryRed,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppTheme.primaryRed.withAlpha(180),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryRed.withAlpha(50),
                    AppTheme.primaryRed.withAlpha(5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSales {
  final String month;
  final double sales;
  const _MonthSales({required this.month, required this.sales});
}
