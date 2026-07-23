import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/print_pdf.dart';
import '../core/params.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../providers/customer_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/payment_invoice_pdf.dart';
import 'payments/widgets/summary_cards.dart';
import 'payments/widgets/payment_toolbar.dart';
import 'payments/widgets/customer_outstanding_table.dart';
import 'payments/widgets/customer_outstanding_cards.dart';
import 'payments/widgets/recent_transactions_table.dart';
import 'payments/widgets/recent_transactions_cards.dart';
import 'payments/widgets/payment_details_dialog.dart';
import 'payments/widgets/statement_dialog.dart';
import 'payments/widgets/add_payment_dialog.dart';
import 'payments/widgets/export_excel_dialog.dart';

enum _ViewTab { customers, payments }

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});
  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  _ViewTab _activeTab = _ViewTab.customers;
  String _search = '';
  String _activeFilter = 'all';
  int _customerPage = 1;
  int _paymentPage = 1;
  String? _loadingAction;
  static const _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final customersParams = CustomerListParams(search: _search, page: _customerPage, limit: _pageSize);
    final customersAsync = ref.watch(customerListProvider(customersParams));
    final paymentsAsync = ref.watch(paymentListProvider(PaymentListParams(page: _paymentPage, limit: _pageSize)));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Payments')]),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: PaymentToolbar(
              searchQuery: _search,
              onSearchChanged: (v) => setState(() { _search = v.trim(); _customerPage = 1; _paymentPage = 1; }),
              activeFilter: _activeFilter,
              onFilterChanged: (v) => setState(() => _activeFilter = v),
              onRefresh: () => setState(() {}),
              onAddPayment: () => context.go('/payments/add'),
              onExport: () => ExportExcelDialog.show(context),
              isMobile: isMobile,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _ViewToggle(
              activeTab: _activeTab,
              onChanged: (t) => setState(() => _activeTab = t),
              isMobile: isMobile,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SummaryCards(),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _activeTab == _ViewTab.customers
                ? _buildCustomersView(customersAsync, isMobile)
                : _buildPaymentsView(paymentsAsync, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersView(AsyncValue<({List<Customer> data, Map<String, dynamic>? meta})> async, bool isMobile) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      error: (e, _) => _ErrorCard(message: '$e', onRetry: () => setState(() {})),
      data: (result) {
        final filtered = _applyCustomerFilter(result.data);
        final meta = result.meta;
        final totalPages = meta != null ? ((meta['totalPages'] ?? 1) as int) : 1;
        if (isMobile) {
          return Column(
            children: [
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyView(icon: Icons.people_outline, title: 'No customers found', subtitle: 'Try adjusting your search')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => CustomerOutstandingCard(
                          customer: filtered[i],
                          loadingAction: _loadingAction,
                          onPay: (c) => AddPaymentDialog.show(context, ref: ref, customer: c, onPaymentRecorded: () => setState(() {})),
                          onStatement: (c) => StatementDownloadDialog.show(context, ref: ref, customer: c),
                          onInvoice: (c) => _downloadInvoice(c, actionKey: 'inv_${c.id}'),
                          onViewLedger: (c) => context.go('/customers/${c.id}'),
                        ),
                      ),
              ),
              if (totalPages > 1) _PaginationBar(
                page: _customerPage, totalPages: totalPages,
                onPrev: _customerPage > 1 ? () => setState(() => _customerPage--) : null,
                onNext: _customerPage < totalPages ? () => setState(() => _customerPage++) : null,
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyView(icon: Icons.people_outline, title: 'No customers found', subtitle: 'Try adjusting your search')
                  : CustomerOutstandingTable(
                      customers: filtered,
                      loadingAction: _loadingAction,
                      onPay: (c) => AddPaymentDialog.show(context, ref: ref, customer: c, onPaymentRecorded: () => setState(() {})),
                      onStatement: (c) => StatementDownloadDialog.show(context, ref: ref, customer: c),
                      onInvoice: (c) => _downloadInvoice(c, actionKey: 'inv_${c.id}'),
                      onViewLedger: (c) => context.go('/customers/${c.id}'),
                    ),
            ),
            if (totalPages > 1) _PaginationBar(
              page: _customerPage, totalPages: totalPages,
              onPrev: _customerPage > 1 ? () => setState(() => _customerPage--) : null,
              onNext: _customerPage < totalPages ? () => setState(() => _customerPage++) : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentsView(AsyncValue<({List<Payment> data, Map<String, dynamic>? meta})> async, bool isMobile) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      error: (e, _) => _ErrorCard(message: '$e', onRetry: () => setState(() {})),
      data: (result) {
        final payments = _applyPaymentFilter(result.data);
        final meta = result.meta;
        final totalPages = meta != null ? ((meta['totalPages'] ?? 1) as int) : 1;
        if (isMobile) {
          return Column(
            children: [
              Expanded(
                child: payments.isEmpty
                    ? const _EmptyView(icon: Icons.receipt_long, title: 'No transactions found', subtitle: 'Payments will appear here')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: payments.length,
                        itemBuilder: (_, i) {
                          final pay = payments[i];
                          final cust = pay.customer;
                          return TransactionCard(
                            payment: pay,
                            loadingAction: _loadingAction,
                            onView: (p) => PaymentDetailsDialog.show(context, payment: p, loadingAction: _loadingAction,
                              onPrint: p.customer != null ? () => _downloadInvoice(p.customer!, payment: p, actionKey: 'print_pay_${p.id}') : null,
                              onDownload: p.customer != null ? () => _downloadInvoice(p.customer!, payment: p, actionKey: 'dl_pay_${p.id}') : null),
                            onPrint: cust != null ? (_) => _downloadInvoice(cust, payment: pay, actionKey: 'print_pay_${pay.id}') : (_) {},
                            onDownload: cust != null ? (_) => _downloadInvoice(cust, payment: pay, actionKey: 'dl_pay_${pay.id}') : (_) {},
                          );
                        },
                      ),
              ),
              if (totalPages > 1) _PaginationBar(
                page: _paymentPage, totalPages: totalPages,
                onPrev: _paymentPage > 1 ? () => setState(() => _paymentPage--) : null,
                onNext: _paymentPage < totalPages ? () => setState(() => _paymentPage++) : null,
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: payments.isEmpty
                  ? const _EmptyView(icon: Icons.receipt_long, title: 'No transactions found', subtitle: 'Payments will appear here')
                  : RecentTransactionsTable(
                      payments: payments,
                      loadingAction: _loadingAction,
                      onView: (p) => PaymentDetailsDialog.show(context, payment: p, loadingAction: _loadingAction,
                        onPrint: p.customer != null ? () => _downloadInvoice(p.customer!, payment: p, actionKey: 'print_pay_${p.id}') : null,
                        onDownload: p.customer != null ? () => _downloadInvoice(p.customer!, payment: p, actionKey: 'dl_pay_${p.id}') : null),
                      onPrint: (p) => p.customer != null ? _downloadInvoice(p.customer!, payment: p, actionKey: 'print_pay_${p.id}') : null,
                      onDownload: (p) => p.customer != null ? _downloadInvoice(p.customer!, payment: p, actionKey: 'dl_pay_${p.id}') : null,
                    ),
            ),
            if (totalPages > 1) _PaginationBar(
              page: _paymentPage, totalPages: totalPages,
              onPrev: _paymentPage > 1 ? () => setState(() => _paymentPage--) : null,
              onNext: _paymentPage < totalPages ? () => setState(() => _paymentPage++) : null,
            ),
          ],
        );
      },
    );
  }

  List<Customer> _applyCustomerFilter(List<Customer> data) {
    switch (_activeFilter) {
      case 'paid': return data.where((c) => c.currentDue <= 0).toList();
      case 'unpaid': return data.where((c) => c.currentDue > 0 && c.totalPaid <= 0).toList();
      case 'partial': return data.where((c) => c.currentDue > 0 && c.totalPaid > 0).toList();
      default: return data;
    }
  }

  List<Payment> _applyPaymentFilter(List<Payment> data) {
    switch (_activeFilter) {
      case 'cash': return data.where((p) => p.mode.value == 'cash').toList();
      case 'upi': return data.where((p) => p.mode.value == 'upi').toList();
      case 'bank': return data.where((p) => p.mode.value == 'bank_transfer').toList();
      default: return data;
    }
  }

  Future<void> _downloadInvoice(Customer customer, {Payment? payment, String? actionKey}) async {
    if (actionKey != null) setState(() => _loadingAction = actionKey);
    try {
      Payment? pay = payment;
      if (pay == null) {
        final paymentService = ref.read(paymentServiceProvider);
        final result = await paymentService.getAll(customerId: customer.id, limit: 1);
        if (result.data.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No payments found for ${customer.name}'), backgroundColor: AppTheme.error),
            );
          }
          return;
        }
        pay = result.data.first;
      }

      final settings = await ref.read(settingsProvider.future);
      final previousOutstanding = customer.currentDue + pay.amount;
      final remainingOutstanding = customer.currentDue;

      final pdf = await buildPaymentInvoicePdf(
        settings: settings,
        receiptNumber: pay.receiptNumber,
        customer: pay.customer ?? customer,
        amount: pay.amount,
        paymentMode: pay.mode.displayName,
        previousOutstanding: previousOutstanding,
        remainingOutstanding: remainingOutstanding,
        paymentDate: pay.paymentDate,
        remarks: pay.notes,
      );
      if (mounted) {
        await printPdf(pdf, filename: 'Invoice-${pay.receiptNumber}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice downloaded'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted && actionKey != null) setState(() => _loadingAction = null);
    }
  }
}

class _ViewToggle extends StatelessWidget {
  final _ViewTab activeTab;
  final ValueChanged<_ViewTab> onChanged;
  final bool isMobile;

  const _ViewToggle({required this.activeTab, required this.onChanged, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(child: _ToggleBtn(
            icon: Icons.people_outline,
            label: 'Customers',
            isActive: activeTab == _ViewTab.customers,
            onTap: () => onChanged(_ViewTab.customers),
            isMobile: isMobile,
          )),
          Container(width: 1, color: AppTheme.border),
          Expanded(child: _ToggleBtn(
            icon: Icons.receipt_long,
            label: 'Payments',
            isActive: activeTab == _ViewTab.payments,
            onTap: () => onChanged(_ViewTab.payments),
            isMobile: isMobile,
          )),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isMobile;

  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryRed.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? AppTheme.primaryRed : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppTheme.primaryRed : AppTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({required this.page, required this.totalPages, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border.withAlpha(128))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: onPrev,
            color: onPrev != null ? AppTheme.primaryRed : Colors.grey.shade300,
          ),
          const SizedBox(width: 8),
          Text('Page $page of $totalPages', style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
          )),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: onNext,
            color: onNext != null ? AppTheme.primaryRed : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _EmptyView({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textSecondary.withAlpha(80)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error.withAlpha(60)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            const Text('Something went wrong', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            ),
          ],
        ),
      ),
    );
  }
}
