import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/print_pdf.dart';
import '../core/share_pdf.dart';
import '../core/params.dart';
import '../core/utils.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../providers/customer_provider.dart';
import '../providers/payment_provider.dart';
import '../services/api_client.dart';
import '../providers/settings_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/payment_invoice_pdf.dart';
import 'payments/widgets/summary_cards.dart';
import 'payments/widgets/payment_toolbar.dart';
import 'payments/widgets/payment_filter_bar.dart';
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
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _loadingAction;

  bool get _hasDateFilter => _fromDate != null || _toDate != null;

  PaymentListParams get _paymentsParams => PaymentListParams(
        from: _fromDate != null ? AppUtils.formatDate(_fromDate!) : null,
        to: _toDate != null ? AppUtils.formatDate(_toDate!) : null,
      );

  CustomerListParams get _customersParams => CustomerListParams(search: _search);

  void _refresh() {
    invalidateCustomerLists(ref);
    invalidatePaymentLists(ref);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final customersAsync = ref.watch(customersAllProvider(_customersParams));
    final paymentsAsync = ref.watch(paymentsAllProvider(_paymentsParams));

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
              onSearchChanged: (v) => setState(() => _search = v.trim()),
              hasActiveFilters: _activeFilter != 'all' || _hasDateFilter,
              filtersPanel: PaymentFilterBar(
                fromDate: _fromDate,
                toDate: _toDate,
                onFromDateChanged: (d) => setState(() => _fromDate = d),
                onToDateChanged: (d) => setState(() => _toDate = d),
                onClearDates: () => setState(() { _fromDate = null; _toDate = null; }),
                activeFilter: _activeFilter,
                onFilterChanged: (v) => setState(() => _activeFilter = v),
              ),
              onRefresh: _refresh,
              onAddPayment: () => context.go('/payments/add'),
              onExport: () => ExportExcelDialog.show(context),
              isMobile: isMobile,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _ViewToggle(
              activeTab: _activeTab,
              onChanged: (t) => setState(() => _activeTab = t),
              isMobile: isMobile,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SummaryCards(paymentsParams: _paymentsParams),
                  ),
                  const SizedBox(height: 10),
                  _activeTab == _ViewTab.customers
                      ? _buildCustomersView(customersAsync, isMobile)
                      : _buildPaymentsView(paymentsAsync, isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersView(AsyncValue<List<Customer>> async, bool isMobile) {
    return async.when(
      loading: () => const _TableLoader(),
      error: (e, _) => _ErrorCard(message: ApiClient.humanizeError(e), onRetry: _refresh),
      data: (customers) {
        final filtered = _applyCustomerFilter(customers);
        if (filtered.isEmpty) {
          return const _EmptyView(
            icon: Icons.people_outline,
            title: 'No customers found',
            subtitle: 'Try adjusting your search or filters',
          );
        }
        if (isMobile) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) => CustomerOutstandingCard(
              customer: filtered[i],
              loadingAction: _loadingAction,
              onPay: (c) => AddPaymentDialog.show(context, ref: ref, customer: c, onPaymentRecorded: _refresh),
              onStatement: (c) => StatementDownloadDialog.show(context, ref: ref, customer: c),
              onInvoice: (c) => _downloadInvoice(c, actionKey: 'inv_${c.id}'),
              onShare: (c) => _shareInvoice(c, actionKey: 'sh_${c.id}'),
              onViewLedger: (c) => context.go('/customers/${c.id}'),
            ),
          );
        }
        return CustomerOutstandingTable(
          customers: filtered,
          loadingAction: _loadingAction,
          onPay: (c) => AddPaymentDialog.show(context, ref: ref, customer: c, onPaymentRecorded: _refresh),
          onStatement: (c) => StatementDownloadDialog.show(context, ref: ref, customer: c),
          onInvoice: (c) => _downloadInvoice(c, actionKey: 'inv_${c.id}'),
          onShare: (c) => _shareInvoice(c, actionKey: 'sh_${c.id}'),
          onViewLedger: (c) => context.go('/customers/${c.id}'),
        );
      },
    );
  }

  Widget _buildPaymentsView(AsyncValue<List<Payment>> async, bool isMobile) {
    return async.when(
      loading: () => const _TableLoader(),
      error: (e, _) => _ErrorCard(message: ApiClient.humanizeError(e), onRetry: _refresh),
      data: (all) {
        final payments = _applyPaymentFilter(_applyPaymentSearch(all));
        if (payments.isEmpty) {
          return const _EmptyView(
            icon: Icons.receipt_long,
            title: 'No transactions found',
            subtitle: 'Try adjusting your search, filters or date range',
          );
        }
        if (isMobile) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                  onDownload: p.customer != null ? () => _downloadInvoice(p.customer!, payment: p, actionKey: 'dl_pay_${p.id}') : null,
                  onShare: p.customer != null ? () => _shareInvoice(p.customer!, payment: p, actionKey: 'sh_pay_${p.id}') : null),
                onPrint: cust != null ? (_) => _downloadInvoice(cust, payment: pay, actionKey: 'print_pay_${pay.id}') : (_) {},
                onDownload: cust != null ? (_) => _downloadInvoice(cust, payment: pay, actionKey: 'dl_pay_${pay.id}') : (_) {},
                onShare: cust != null ? (_) => _shareInvoice(cust, payment: pay, actionKey: 'sh_pay_${pay.id}') : (_) {},
              );
            },
          );
        }
        return RecentTransactionsTable(
          payments: payments,
          loadingAction: _loadingAction,
          onView: (p) => PaymentDetailsDialog.show(context, payment: p, loadingAction: _loadingAction,
            onPrint: p.customer != null ? () => _downloadInvoice(p.customer!, payment: p, actionKey: 'print_pay_${p.id}') : null,
            onDownload: p.customer != null ? () => _downloadInvoice(p.customer!, payment: p, actionKey: 'dl_pay_${p.id}') : null,
            onShare: p.customer != null ? () => _shareInvoice(p.customer!, payment: p, actionKey: 'sh_pay_${p.id}') : null),
          onPrint: (p) => p.customer != null ? _downloadInvoice(p.customer!, payment: p, actionKey: 'print_pay_${p.id}') : null,
          onDownload: (p) => p.customer != null ? _downloadInvoice(p.customer!, payment: p, actionKey: 'dl_pay_${p.id}') : null,
          onShare: (p) => p.customer != null ? _shareInvoice(p.customer!, payment: p, actionKey: 'sh_pay_${p.id}') : null,
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

  List<Payment> _applyPaymentSearch(List<Payment> data) {
    if (_search.isEmpty) return data;
    final q = _search.toLowerCase();
    return data.where((p) {
      if (p.receiptNumber.toLowerCase().contains(q)) return true;
      final cust = p.customer;
      if (cust == null) return false;
      return cust.name.toLowerCase().contains(q) ||
          cust.mobile.contains(q) ||
          (p.mode.displayName.toLowerCase().contains(q));
    }).toList();
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
      final pdf = await _buildInvoicePdf(customer, payment: payment);
      if (pdf == null) return;
      if (mounted) {
        await printPdf(pdf, filename: 'Invoice-${_lastReceiptNumber}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice downloaded'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted && actionKey != null) setState(() => _loadingAction = null);
    }
  }

  String? _lastReceiptNumber;

  Future<void> _shareInvoice(Customer customer, {Payment? payment, String? actionKey}) async {
    if (actionKey != null) setState(() => _loadingAction = actionKey);
    try {
      final pdf = await _buildInvoicePdf(customer, payment: payment);
      if (pdf == null) return;
      final settings = await ref.read(settingsProvider.future);
      final message = buildShareMessage(
        businessName: settings.businessName,
        docLabel: 'Payment Invoice',
        amount: _lastInvoiceAmount,
        balance: _lastRemainingOutstanding,
      );
      if (mounted) {
        await sharePdf(pdf, filename: 'Invoice-${_lastReceiptNumber}', message: message);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice ready to share'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted && actionKey != null) setState(() => _loadingAction = null);
    }
  }

  double _lastInvoiceAmount = 0;
  double _lastRemainingOutstanding = 0;

  Future<Uint8List?> _buildInvoicePdf(Customer customer, {Payment? payment}) async {
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
        return null;
      }
      pay = result.data.first;
    }

    final settings = await ref.read(settingsProvider.future);
    final previousOutstanding = customer.currentDue + pay.amount;
    final remainingOutstanding = customer.currentDue;
    _lastInvoiceAmount = pay.amount;
    _lastRemainingOutstanding = remainingOutstanding;
    _lastReceiptNumber = pay.receiptNumber;

    return buildPaymentInvoicePdf(
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

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _EmptyView({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
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
    );
  }
}

class _TableLoader extends StatelessWidget {
  const _TableLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryRed),
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
    return Container(
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
    );
  }
}
