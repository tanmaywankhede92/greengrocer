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
              const Text('Failed to load dashboard', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              Text('$e', style: const TextStyle(color: AppTheme.error, fontSize: 13)),
            ],
          ),
        ),
      ),
      data: (stats) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 900;
            final isTablet = w >= 600 && w < 900;
            final cardCount = isDesktop ? 4 : isTablet ? 2 : 1;
            const cardGap = 16.0;
            final cardW = (w - 48 - (cardCount - 1) * cardGap) / cardCount;

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(dashboardProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dashboard', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                        if (isDesktop)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20, color: AppTheme.textSecondary),
                            onPressed: () => ref.invalidate(dashboardProvider),
                            tooltip: 'Refresh',
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: cardGap, runSpacing: cardGap,
                      children: [
                        SizedBox(width: cardW, child: StatCard(title: "Today's Revenue", value: stats.todayRevenue, icon: Icons.trending_up, color: AppTheme.success)),
                        SizedBox(width: cardW, child: StatCard(title: "Today's Orders", value: stats.todayOrders.toDouble(), icon: Icons.receipt_long, color: AppTheme.info, isCurrency: false)),
                        SizedBox(width: cardW, child: StatCard(title: 'Monthly Collection', value: stats.monthlyCollection, icon: Icons.account_balance_wallet, color: AppTheme.warning)),
                        SizedBox(width: cardW, child: StatCard(title: 'Outstanding', value: stats.outstanding, icon: Icons.warning_amber_rounded, color: AppTheme.error)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 3, child: SizedBox(height: 300, child: SalesChart())),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: SizedBox(height: 300, child: TopCustomers(customers: stats.topCustomers))),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(height: isTablet ? 280 : 260, child: const SalesChart()),
                          const SizedBox(height: 16),
                          SizedBox(height: 300, child: TopCustomers(customers: stats.topCustomers)),
                        ],
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: isDesktop ? 340 : (isTablet ? 360 : 400),
                      child: RecentTransactions(bills: stats.recentBills),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
