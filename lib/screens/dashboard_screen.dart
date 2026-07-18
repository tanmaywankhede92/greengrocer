import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/sales_chart.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/top_customers.dart';
import '../widgets/loading_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    return dashboardAsync.when(
      loading: () => const LoadingWidget(message: 'Loading dashboard...'),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error.withAlpha(150)),
              const SizedBox(height: 16),
              Text('Failed to load dashboard', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              Text('$e', style: TextStyle(color: AppTheme.error, fontSize: 13)),
            ],
          ),
        ),
      ),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Wrap(
                  spacing: 16, runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                      child: StatCard(title: "Today's Revenue", value: stats.todayRevenue, icon: Icons.trending_up, color: AppTheme.success),
                    ),
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                      child: StatCard(title: "Today's Orders", value: stats.todayOrders.toDouble(), icon: Icons.receipt_long, color: AppTheme.info, isCurrency: false),
                    ),
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                      child: StatCard(title: 'Monthly Collection', value: stats.monthlyCollection, icon: Icons.account_balance_wallet, color: AppTheme.warning),
                    ),
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                      child: StatCard(title: 'Outstanding', value: stats.outstanding, icon: Icons.warning, color: AppTheme.error),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: isWide ? 3 : 1, child: Column(
                      children: [
                        SizedBox(height: 280, child: SalesChart(data: stats.salesSeries)),
                        const SizedBox(height: 16),
                        RecentTransactions(bills: stats.recentBills),
                      ],
                    )),
                    if (isWide) const SizedBox(width: 16),
                    if (isWide) Expanded(flex: 2, child: TopCustomers(customers: stats.topCustomers)),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
