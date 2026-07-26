import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/print_pdf.dart';
import '../../../core/utils.dart';
import '../../../models/customer.dart';
import '../../../providers/statement_provider.dart';
import '../../../services/api_client.dart';
import '../../../widgets/statement_pdf.dart';

class StatementDownloadDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const StatementDownloadDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, {required WidgetRef ref, required Customer customer}) {
    return showDialog(
      context: context,
      builder: (_) => StatementDownloadDialog(customer: customer),
    );
  }

  @override
  ConsumerState<StatementDownloadDialog> createState() => _StatementDownloadDialogState();
}

class _StatementDownloadDialogState extends ConsumerState<StatementDownloadDialog> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, size: 22, color: AppTheme.info),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Download Statement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(c.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Select Date Range', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _DateField(label: 'From', date: _from, onChanged: (d) => setState(() => _from = d))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateField(label: 'To', date: _to, onChanged: (d) => setState(() => _to = d))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _QuickRange('This Week', () => setState(() {
                    final now = DateTime.now();
                    _from = now.subtract(Duration(days: now.weekday - 1));
                    _to = now;
                  })),
                  const SizedBox(width: 6),
                  _QuickRange('This Month', () => setState(() {
                    final now = DateTime.now();
                    _from = DateTime(now.year, now.month, 1);
                    _to = now;
                  })),
                  const SizedBox(width: 6),
                  _QuickRange('Last 30 Days', () => setState(() {
                    _from = DateTime.now().subtract(const Duration(days: 30));
                    _to = DateTime.now();
                  })),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download, size: 18),
                  label: Text(_loading ? 'Generating Statement...' : 'Download Statement', style: const TextStyle(fontSize: 14)),
                  onPressed: _loading ? null : () => _download(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.info,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      final c = widget.customer;
      final service = ref.read(statementServiceProvider);
      final data = await service.getStatement(c.id,
        from: AppUtils.formatDateApi(_from), to: AppUtils.formatDateApi(_to));
      if (mounted) Navigator.pop(context);
      final pdf = await buildStatementPdf(
        customerName: data['customer']['name'] ?? c.name,
        customerMobile: data['customer']['mobile'] ?? c.mobile,
        customerAddress: c.address,
        from: AppUtils.formatDateApi(_from),
        to: AppUtils.formatDateApi(_to),
        openingBalance: (data['openingBalance'] ?? 0).toDouble(),
        closingBalance: (data['closingBalance'] ?? 0).toDouble(),
        totalDebit: (data['totalDebit'] ?? 0).toDouble(),
        totalCredit: (data['totalCredit'] ?? 0).toDouble(),
        rows: (data['rows'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      );
      if (mounted) await printPdf(pdf, filename: 'Statement-${c.name}');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error));
      }
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.label, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
      ),
    );
  }
}

class _QuickRange extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickRange(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
