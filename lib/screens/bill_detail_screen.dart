import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/enums.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/bill_item_row.dart';
import '../widgets/bill_pdf.dart';

class BillDetailScreen extends ConsumerWidget {
  final String id;
  const BillDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(billDetailProvider(id));
    return detailAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.error))),
      data: (detail) {
        final bill = detail.bill;
        final items = detail.items;
        final isActive = bill.status == BillStatus.active;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/bills')),
            title: Text(bill.billNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 4),
                child: _ActionBtn(
                  icon: Icons.print,
                  label: 'Reprint',
                  color: AppTheme.primaryRed,
                  onPressed: () async {
                    try {
                      final settings = await ref.read(settingsProvider.future);
                      final lineItems = items.map((i) => LineItem(
                        productId: i.productId,
                        productName: i.productName,
                        productNameHindi: i.productNameHindi,
                        unit: i.unit,
                        quantity: i.quantity,
                        appliedRate: i.appliedRate,
                      )).toList();
                      final pdf = await buildBillPdf(
                        settings: settings,
                        billNumber: bill.billNumber,
                        customerName: bill.customer?.name ?? '',
                        customerMobile: bill.customer?.mobile ?? '',
                        customerAddress: bill.customer?.address,
                        subtotal: bill.subtotal,
                        total: bill.total,
                        deliveryCharge: bill.deliveryCharge,
                        paidNow: bill.paidNow,
                        items: lineItems,
                        billDate: bill.billDate,
                        paymentMode: bill.paymentType,
                        isReprint: true,
                      );
                      await Printing.layoutPdf(onLayout: (_) => pdf);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                      }
                    }
                  },
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _ActionBtn(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    color: AppTheme.error,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Bill'),
                          content: Text('Cancel ${bill.billNumber}? This will reverse the ledger entries.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error)),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await ref.read(billServiceProvider).cancel(id);
                          ref.invalidate(billDetailProvider(id));
                          ref.invalidate(billListProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill cancelled'), backgroundColor: AppTheme.success));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                          }
                        }
                      }
                    },
                  ),
                ),
            ],
          ),
          body: Container(
            color: const Color(0xFFF5F6FA),
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                _PageHeader(billNumber: bill.billNumber, status: bill.status, paymentType: bill.paymentType),
                const SizedBox(height: 24),
                _InfoPanel(customer: bill.customer, bill: bill),
                const SizedBox(height: 28),
                _ProductsSection(items: items),
                const SizedBox(height: 20),
                _SummaryCard(bill: bill),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String billNumber;
  final BillStatus status;
  final String? paymentType;
  const _PageHeader({required this.billNumber, required this.status, required this.paymentType});

  @override
  Widget build(BuildContext context) {
    final isActive = status == BillStatus.active;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Bills', route: '/bills'), Crumb('Bill Detail')]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.success.withAlpha(25) : AppTheme.error.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isActive ? AppTheme.success.withAlpha(60) : AppTheme.error.withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? AppTheme.success : AppTheme.error),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Active' : 'Cancelled',
                style: TextStyle(
                  color: isActive ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.w600, fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final dynamic customer;
  final dynamic bill;
  const _InfoPanel({required this.customer, required this.bill});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final customerPanel = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: AppTheme.primaryRed),
              const SizedBox(width: 8),
              Text('CUSTOMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryRed, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 14),
          Text(customer?.name ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D))),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(customer?.mobile ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          if (customer?.address != null && customer!.address!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(child: Text(customer!.address!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
              ],
            ),
          ],
        ],
      ),
    );
    final billPanel = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_outlined, size: 16, color: AppTheme.primaryRed),
              const SizedBox(width: 8),
              Text('BILL DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryRed, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(label: 'Bill No', value: bill.billNumber),
          const SizedBox(height: 10),
          _DetailRow(label: 'Date', value: AppUtils.formatDate(bill.billDate)),
          if (bill.paymentType != null && bill.paymentType!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(label: 'Payment', value: bill.paymentType!),
          ],
        ],
      ),
    );
    if (isMobile) {
      return Column(
        children: [
          customerPanel,
          const SizedBox(height: 24),
          billPanel,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: customerPanel),
        const SizedBox(width: 24),
        Expanded(child: billPanel),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60, maxWidth: 100),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D))),
        ),
      ],
    );
  }
}

class _ProductsSection extends StatelessWidget {
  final List items;
  const _ProductsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                Text('PRODUCTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryRed, letterSpacing: 1.2)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(4)),
                  child: Text('${items.length} items', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 768;
              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: List.generate(items.length, (idx) {
                      final i = items[idx];
                      final name = i.productNameHindi.isNotEmpty ? '${i.productName} (${i.productNameHindi})' : i.productName;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('#${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                                const Spacer(),
                                Text('Qty: ${i.quantity.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 6),
                              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text('Rate: \u20B9${_fmt(i.appliedRate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                const Spacer(),
                                Text('Amount: \u20B9${_fmt(i.amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red)),
                              ]),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalW = constraints.maxWidth;
                    final cSr = 44.0;
                    final cQty = 72.0;
                    final cRate = 96.0;
                    final cAmt = 112.0;
                    final cProd = (totalW - cSr - cQty - cRate - cAmt).clamp(120.0, double.infinity);
                    return Column(
                      children: [
                        _TableHeader(sr: cSr, prod: cProd, qty: cQty, rate: cRate, amt: cAmt),
                        ...List.generate(items.length, (idx) {
                          final i = items[idx];
                          final name = i.productNameHindi.isNotEmpty ? '${i.productName} (${i.productNameHindi})' : i.productName;
                          return _TableRow(
                            idx: idx, sr: cSr, prod: cProd, qty: cQty, rate: cRate, amt: cAmt,
                            name: name, quantity: i.quantity, rateVal: i.appliedRate, amountVal: i.amount,
                            isLast: idx == items.length - 1,
                          );
                        }),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final double sr, prod, qty, rate, amt;
  const _TableHeader({required this.sr, required this.prod, required this.qty, required this.rate, required this.amt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D3A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(width: sr, child: const Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
          SizedBox(width: prod, child: const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
          SizedBox(width: qty, child: const Text('Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
          SizedBox(width: rate, child: const Text('Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.right)),
          SizedBox(width: amt, child: const Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final int idx;
  final double sr, prod, qty, rate, amt;
  final String name;
  final double quantity, rateVal, amountVal;
  final bool isLast;
  const _TableRow({
    required this.idx, required this.sr, required this.prod, required this.qty, required this.rate, required this.amt,
    required this.name, required this.quantity, required this.rateVal, required this.amountVal, required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isOdd = idx.isOdd;
    return Container(
      decoration: BoxDecoration(
        color: isOdd ? const Color(0xFFFAFAFC) : Colors.white,
        border: isLast ? null : Border(bottom: BorderSide(color: const Color(0xFFEEEEF0), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: sr, child: Text('${idx + 1}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700), textAlign: TextAlign.center)),
          SizedBox(width: prod, child: Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFF2D2D2D)), overflow: TextOverflow.ellipsis)),
          SizedBox(width: qty, child: Text(quantity.toStringAsFixed(0), style: TextStyle(fontSize: 12, color: Colors.grey.shade700), textAlign: TextAlign.center)),
          SizedBox(width: rate, child: Text(_fmt(rateVal), style: TextStyle(fontSize: 12, color: Colors.grey.shade700), textAlign: TextAlign.right)),
          SizedBox(width: amt, child: Text(_fmt(amountVal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final dynamic bill;
  const _SummaryCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final double totalDue = bill.total - bill.paidNow;
    final screenWidth = MediaQuery.of(context).size.width;
    final summaryWidth = screenWidth < 768 ? double.infinity : 340.0;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: summaryWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_outlined, size: 16, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                Text('SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryRed, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 18),
            _SummaryLine(label: 'Subtotal', value: bill.subtotal, bold: false, color: null),
            if (bill.deliveryCharge > 0) ...[
              const SizedBox(height: 8),
              _SummaryLine(label: 'Delivery Charge', value: bill.deliveryCharge, bold: false, color: null),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFE0E0E0)),
            ),
            _SummaryLine(label: 'Total', value: bill.total, bold: true, color: Colors.red.shade700),
            if (bill.paidNow > 0) ...[
              const SizedBox(height: 8),
              _SummaryLine(label: 'Paid', value: bill.paidNow, bold: false, color: Colors.green.shade700),
            ],
            if (bill.paidNow > 0 && totalDue > 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE0E0E0)),
              ),
              _SummaryLine(label: 'Balance Due', value: totalDue, bold: true, color: Colors.red.shade700),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final Color? color;
  const _SummaryLine({required this.label, required this.value, required this.bold, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontSize: bold ? 15 : 13,
          color: color ?? Colors.grey.shade600,
        )),
        Text('\u20B9 ${value.toStringAsFixed(0)}', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: bold ? 17 : 14,
          color: color ?? const Color(0xFF2D2D2D),
        )),
      ],
    );
  }
}

String _fmt(double v) => v.toStringAsFixed(0);
