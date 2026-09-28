import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';
import '../../../core/params.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/payment_provider.dart';

class SummaryCards extends ConsumerWidget {
  final PaymentListParams paymentsParams;

  const SummaryCards({super.key, this.paymentsParams = const PaymentListParams()});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersAllProvider(const CustomerListParams()));
    final paymentsAsync = ref.watch(paymentsAllProvider(paymentsParams));

    final hasRange = paymentsParams.from != null && paymentsParams.to != null;

    return customersAsync.when(
      loading: () => const _CardsSkeleton(),
      error: (e, _) => const SizedBox.shrink(),
      data: (customers) => paymentsAsync.when(
        loading: () => const _CardsSkeleton(),
        error: (e, _) => const _CardsSkeleton(),
        data: (payments) {
          final now = DateTime.now();
          final dayStart = DateTime(now.year, now.month, now.day);
          final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          final monthStart = DateTime(now.year, now.month, 1);

          double sumWhere(bool Function(DateTime date) test) => payments
              .where((p) => !p.isCancelled && test(p.paymentDate))
              .fold<double>(0, (s, p) => s + p.amount);

          final active = payments.where((p) => !p.isCancelled).toList();
          final outstanding = customers.fold<double>(0, (s, c) => s + c.currentDue);
          final pendingCount = customers.where((c) => c.currentDue > 0).length;
          final periodTotal = active.fold<double>(0, (s, p) => s + p.amount);

          final cards = <_SummaryCardData>[
            if (hasRange)
              _SummaryCardData(
                Icons.calendar_month,
                'Period Collection',
                periodTotal,
                AppTheme.success,
                'in selected period',
                isCurrency: true,
              )
            else
              _SummaryCardData(
                Icons.today,
                'Today\'s Collection',
                sumWhere((d) => !d.isBefore(dayStart) && !d.isAfter(dayEnd)),
                AppTheme.success,
                'collected today',
                isCurrency: true,
              ),
            if (hasRange)
              _SummaryCardData(
                Icons.receipt_long,
                'Period Transactions',
                active.length.toDouble(),
                AppTheme.primaryRed,
                'in selected period',
              )
            else
              _SummaryCardData(
                Icons.calendar_month,
                'Monthly Collection',
                sumWhere((d) => !d.isBefore(monthStart)),
                AppTheme.info,
                'this month',
                isCurrency: true,
              ),
            _SummaryCardData(
              Icons.account_balance_wallet,
              'Outstanding',
              outstanding,
              AppTheme.error,
              'total pending',
              isCurrency: true,
            ),
            _SummaryCardData(
              Icons.people_outline,
              hasRange ? 'Period Customers' : 'Total Customers',
              customers.length.toDouble(),
              AppTheme.primaryRed,
              '$pendingCount pending',
            ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: cards.map((c) => Expanded(child: _SummaryCard(data: c))).toList(),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cards
                    .map((c) => SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _SummaryCard(data: c),
                        ))
                    .toList(),
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
  final bool isCurrency;
  const _SummaryCardData(this.icon, this.title, this.value, this.color, this.subtitle, {this.isCurrency = false});
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
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
                Text(data.title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  data.isCurrency ? AppUtils.formatCurrency(data.value) : data.value.toInt().toString(),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(data.subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
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
