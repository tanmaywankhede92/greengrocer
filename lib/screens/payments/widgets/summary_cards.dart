import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../core/params.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/payment_provider.dart';

class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider(const CustomerListParams(limit: 500)));
    final paymentsAsync = ref.watch(paymentListProvider(const PaymentListParams(limit: 500)));

    return customersAsync.when(
      loading: () => const _CardsSkeleton(),
      error: (e, _) => const SizedBox.shrink(),
      data: (custResult) => paymentsAsync.when(
        loading: () => const _CardsSkeleton(),
        error: (e, _) => const _CardsSkeleton(),
        data: (payResult) {
          final customers = custResult.data;
          final payments = payResult.data;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final monthStart = DateTime(now.year, now.month, 1);

          final outstanding = customers.fold<double>(0, (s, c) => s + c.currentDue);
          final todayCollection = payments.where((p) => p.paymentDate.isAfter(today) && !p.isCancelled).fold<double>(0, (s, p) => s + p.amount);
          final monthCollection = payments.where((p) => p.paymentDate.isAfter(monthStart) && !p.isCancelled).fold<double>(0, (s, p) => s + p.amount);
          final pendingCount = customers.where((c) => c.currentDue > 0).length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final cards = [
                _SummaryCardData(Icons.today, 'Today\'s Collection', todayCollection, AppTheme.success, 'collected today'),
                _SummaryCardData(Icons.calendar_month, 'Monthly Collection', monthCollection, AppTheme.info, 'this month'),
                _SummaryCardData(Icons.account_balance_wallet, 'Outstanding', outstanding, AppTheme.error, 'total pending'),
                _SummaryCardData(Icons.receipt_long, 'Total Payments', payments.length.toDouble(), AppTheme.primaryRed, '${pendingCount} pending'),
              ];
              if (isWide) {
                return Row(
                  children: cards.map((c) => Expanded(child: _SummaryCard(data: c))).toList(),
                );
              }
              return Wrap(
                spacing: 8, runSpacing: 8,
                children: cards.map((c) => SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: _SummaryCard(data: c),
                )).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryCardData {
  final IconData icon;
  final String title;
  final double value;
  final Color color;
  final String subtitle;
  const _SummaryCardData(this.icon, this.title, this.value, this.color, this.subtitle);
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isCurrency = data.title.contains('Collection') || data.title.contains('Outstanding');
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 22, color: data.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  isCurrency ? AppUtils.formatCurrency(data.value) : data.value.toInt().toString(),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(data.subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardsSkeleton extends StatelessWidget {
  const _CardsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (_) => Expanded(
        child: Container(
          height: 80,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )),
    );
  }
}
