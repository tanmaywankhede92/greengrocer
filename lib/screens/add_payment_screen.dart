import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/print_pdf.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../core/params.dart';
import '../core/enums.dart';
import '../models/customer.dart';
import '../services/api_client.dart';
import '../models/payment.dart';
import '../providers/customer_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/payment_mode_select.dart';
import '../widgets/payment_invoice_pdf.dart';
import '../providers/settings_provider.dart';
import 'payments/widgets/statement_dialog.dart';


class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key});
  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  Customer? _selectedCustomer;
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _customerSearch = '';
  String _customerFilter = 'all'; // 'all', 'pending', 'this_month'
  PaymentMode _mode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectCustomer(Customer c) {
    setState(() {
      _selectedCustomer = c;
      if (c.currentDue > 0) {
        _amountCtrl.text = c.currentDue.toStringAsFixed(0);
      } else {
        _amountCtrl.text = '';
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(paymentServiceProvider).create({
        'customerId': _selectedCustomer!.id,
        'amount': amount,
        'mode': _mode.value,
        'reference': _refCtrl.text,
        'notes': _notesCtrl.text,
        'paymentDate': AppUtils.formatDateApi(_paymentDate),
      });
      if (mounted) {
        invalidateCustomerLists(ref);
        invalidatePaymentLists(ref);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded'), backgroundColor: AppTheme.success));
        final recNo = (result['receiptNumber'] as String?) ?? 'INV-0001';
        _showInvoice(_selectedCustomer!.id, paidNow: amount, paymentMode: _mode.value, receiptNumber: recNo);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showInvoice(String customerId, {required double paidNow, required String paymentMode, required String receiptNumber}) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final previousOutstanding = _selectedCustomer!.currentDue + paidNow;
      final remainingOutstanding = _selectedCustomer!.currentDue;
      final now = DateTime.now();
      final pdf = await buildPaymentInvoicePdf(
        settings: settings,
        receiptNumber: receiptNumber,
        customer: _selectedCustomer!,
        amount: paidNow,
        paymentMode: paymentMode,
        previousOutstanding: previousOutstanding,
        remainingOutstanding: remainingOutstanding,
        paymentDate: now,
        remarks: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );
      if (mounted) await printPdf(pdf, filename: 'Invoice-$receiptNumber');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error));
      }
    }
  }

  void _downloadStatement() {
    if (_selectedCustomer == null) return;
    StatementDownloadDialog.show(context, ref: ref, customer: _selectedCustomer!);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    Widget? recentPayments;
    if (_selectedCustomer != null) {
      final paymentsAsync = ref.watch(paymentListProvider(PaymentListParams(customerId: _selectedCustomer!.id, limit: 20)));
      recentPayments = paymentsAsync.when(
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (e, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(ApiClient.humanizeError(e), style: const TextStyle(color: AppTheme.error, fontSize: 13))),
        data: (result) {
          if (result.data.isEmpty) {
            return const Padding(padding: EdgeInsets.only(top: 16),
              child: Center(child: Text('No payments yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))));
          }
          return _buildRecentPayments(result.data, isMobile);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/payments')),
        title: const Text('Add Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Breadcrumb(crumbs: [Crumb('Home', route: '/dashboard'), Crumb('Payments', route: '/payments'), Crumb('Add Payment')]),
              const SizedBox(height: 20),
              if (_selectedCustomer == null)
                _buildCustomerDirectory(isMobile)
              else ...[
                _buildSelectedCustomerBanner(isMobile),
                const SizedBox(height: 20),
                _buildSummaryCard(isMobile),
                const SizedBox(height: 24),
                _buildPaymentForm(isMobile),
                const SizedBox(height: 24),
                _buildStatementSection(isMobile, recentPayments),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCustomerBanner(bool isMobile) {
    final c = _selectedCustomer!;
    final isDue = c.currentDue > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDue ? AppTheme.error.withAlpha(12) : AppTheme.success.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDue ? AppTheme.error.withAlpha(50) : AppTheme.success.withAlpha(50)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDue ? AppTheme.error.withAlpha(25) : AppTheme.success.withAlpha(25),
            child: Icon(Icons.person, color: isDue ? AppTheme.error : AppTheme.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mobile: ${c.mobile}  •  Due: ${AppUtils.formatCurrency(c.currentDue)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDue ? AppTheme.error : AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Change Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            onPressed: () => setState(() => _selectedCustomer = null),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDirectory(bool isMobile) {
    final customersAsync = ref.watch(customersAllProvider(const CustomerListParams()));

    return customersAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(ApiClient.humanizeError(e), style: const TextStyle(color: AppTheme.error)),
        ),
      ),
      data: (customers) {
        final now = DateTime.now();
        final totalCount = customers.length;
        final pendingList = customers.where((c) => c.currentDue > 0).toList();
        final pendingCount = pendingList.length;

        final thisMonthPendingList = pendingList.where((c) {
          final bMatch = c.lastBillDate != null && c.lastBillDate!.month == now.month && c.lastBillDate!.year == now.year;
          final pMatch = c.lastPaymentDate != null && c.lastPaymentDate!.month == now.month && c.lastPaymentDate!.year == now.year;
          final uMatch = c.updatedAt != null && c.updatedAt!.month == now.month && c.updatedAt!.year == now.year;
          final cMatch = c.createdAt != null && c.createdAt!.month == now.month && c.createdAt!.year == now.year;
          return bMatch || pMatch || uMatch || cMatch;
        }).toList();
        final thisMonthPendingCount = thisMonthPendingList.length;

        List<Customer> displayed = customers;
        if (_customerFilter == 'pending') {
          displayed = pendingList;
        } else if (_customerFilter == 'this_month') {
          displayed = thisMonthPendingList;
        }

        if (_customerSearch.trim().isNotEmpty) {
          final q = _customerSearch.trim().toLowerCase();
          displayed = displayed.where((c) {
            return c.name.toLowerCase().contains(q) || c.mobile.contains(q);
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Customer to Record Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search customers, review outstanding balances, and collect payments easily.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customer by name or mobile number...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _customerSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _customerSearch = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
              ),
              onChanged: (v) => setState(() => _customerSearch = v),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All Customers',
                    count: totalCount,
                    isSelected: _customerFilter == 'all',
                    onSelected: () => setState(() => _customerFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Pending Dues',
                    count: pendingCount,
                    isSelected: _customerFilter == 'pending',
                    highlightColor: AppTheme.error,
                    onSelected: () => setState(() => _customerFilter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'This Month Due',
                    count: thisMonthPendingCount,
                    isSelected: _customerFilter == 'this_month',
                    highlightColor: Colors.orange.shade800,
                    onSelected: () => setState(() => _customerFilter = 'this_month'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (displayed.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No customers found', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      _customerSearch.isNotEmpty
                          ? 'No customer matched "$_customerSearch".'
                          : 'No customers match the selected filter.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = displayed[i];
                  final isDue = c.currentDue > 0;
                  final status = c.currentDue <= 0 ? 'Paid' : (c.totalPaid > 0 ? 'Partial' : 'Unpaid');
                  final statusColor = c.currentDue <= 0 ? AppTheme.success : (c.totalPaid > 0 ? AppTheme.info : AppTheme.error);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDue ? AppTheme.error.withAlpha(60) : AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(c.mobile, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pending Due', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  Text(
                                    AppUtils.formatCurrency(c.currentDue),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDue ? AppTheme.error : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Paid', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  Text(
                                    AppUtils.formatCurrency(c.totalPaid),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.success),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDue ? AppTheme.primaryRed : const Color(0xFF1E2330),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.payments_outlined, size: 16),
                            label: Text(isDue ? 'Collect Payment' : 'Record Payment', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            onPressed: () => _selectCustomer(c),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      color: const Color(0xFF1E2330),
                      child: const Row(
                        children: [
                          Expanded(flex: 25, child: Text('Customer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 18, child: Text('Mobile', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 14, child: Text('Status', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 18, child: Text('Pending Amount', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          Expanded(flex: 15, child: Text('Total Paid', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          SizedBox(width: 16),
                          Expanded(flex: 16, child: Text('Action', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayed.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEF0)),
                      itemBuilder: (context, i) {
                        final c = displayed[i];
                        final isDue = c.currentDue > 0;
                        final isOdd = i.isOdd;
                        final status = c.currentDue <= 0 ? 'Paid' : (c.totalPaid > 0 ? 'Partial' : 'Unpaid');
                        final statusColor = c.currentDue <= 0 ? AppTheme.success : (c.totalPaid > 0 ? AppTheme.info : AppTheme.error);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: isOdd ? const Color(0xFFFAFAFC) : Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 25,
                                child: Text(
                                  c.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 18,
                                child: Text(
                                  c.mobile,
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 14,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: statusColor.withAlpha(60)),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 18,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    AppUtils.formatCurrency(c.currentDue),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDue ? AppTheme.error : Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    AppUtils.formatCurrency(c.totalPaid),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.success),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 16,
                                child: SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDue ? AppTheme.primaryRed : const Color(0xFF1E2330),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () => _selectCustomer(c),
                                    child: const Text('Collect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? highlightColor,
  }) {
    final activeColor = highlightColor ?? AppTheme.primaryRed;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(25) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isMobile) {
    final c = _selectedCustomer!;
    final status = c.currentDue <= 0 ? 'Paid' : c.totalPaid > 0 ? 'Partial' : 'Unpaid';
    final statusColor = c.currentDue <= 0 ? AppTheme.success : c.totalPaid > 0 ? AppTheme.info : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statTile('Outstanding', AppUtils.formatCurrency(c.currentDue), AppTheme.textPrimary)),
              Container(width: 1, height: 36, color: AppTheme.border),
              Expanded(child: _statTile('Total Paid', AppUtils.formatCurrency(c.totalPaid), AppTheme.success)),
              Container(width: 1, height: 36, color: AppTheme.border),
              Expanded(child: _statTile('Bills', '${c.billCount}', AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildPaymentForm(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.payments, size: 18, color: AppTheme.primaryRed),
            SizedBox(width: 8),
            Text('Record Payment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: isMobile
              ? Column(children: _formFields())
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(children: _formFields().sublist(0, _formFields().length ~/ 2))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(children: _formFields().sublist(_formFields().length ~/ 2))),
                ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.check_circle, size: 20),
            label: Text(_isSubmitting ? 'Recording...' : 'Record Payment', style: const TextStyle(fontSize: 15)),
            onPressed: _isSubmitting ? null : () => _submit(),
          ),
        ),
      ],
    );
  }

  List<Widget> _formFields() {
    return [
      TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Amount *', prefixIcon: Icon(Icons.currency_rupee, size: 18))),
      const SizedBox(height: 14),
      PaymentModeSelect(value: _mode, onChanged: (v) => setState(() => _mode = v ?? PaymentMode.cash)),
      const SizedBox(height: 14),
      TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference (optional)', prefixIcon: Icon(Icons.receipt, size: 18))),
      const SizedBox(height: 14),
      TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes, size: 18)), maxLines: 2),
      const SizedBox(height: 14),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2020), lastDate: DateTime.now());
          if (picked != null) setState(() => _paymentDate = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Payment Date', prefixIcon: Icon(Icons.calendar_today, size: 18), isDense: true),
          child: Text(DateFormat('dd MMM yyyy').format(_paymentDate), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ),
      ),
    ];
  }

  Widget _buildStatementSection(bool isMobile, Widget? recentPayments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 18, color: AppTheme.primaryRed),
            const SizedBox(width: 8),
            const Text('Recent Transactions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download Statement', style: TextStyle(fontSize: 12)),
              onPressed: _downloadStatement,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: recentPayments ?? const Center(child: Text('Select a customer to view transactions', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        ),
      ],
    );
  }

  Widget _buildRecentPayments(List<Payment> data, bool isMobile) {
    if (isMobile) {
      return Column(
        children: data.take(10).map((p) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${p.receiptNumber}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(DateFormat('dd MMM yy').format(p.paymentDate), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Text(AppUtils.formatCurrency(p.amount), style: const TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            _th('Receipt', 100),
            _th('Date', 100),
            _th('Mode', 90),
            _th('Reference', 120),
            _th('Amount', 100, align: TextAlign.right),
          ],
        ),
        const Divider(height: 1, color: AppTheme.border),
        const SizedBox(height: 4),
        ...data.take(10).map((p) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5))),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text('#${p.receiptNumber}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
              SizedBox(width: 100, child: Text(DateFormat('dd MMM yy').format(p.paymentDate), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              SizedBox(width: 90, child: Text(p.mode.displayName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              SizedBox(width: 120, child: Text(p.reference ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              SizedBox(width: 100, child: Text(AppUtils.formatCurrency(p.amount), style: const TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _th(String label, double width, {TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5), textAlign: align),
    );
  }
}
