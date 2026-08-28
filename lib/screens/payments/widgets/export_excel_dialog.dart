import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import '../../../core/download_bytes.dart';
import '../../../config/theme.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../services/api_client.dart';

class ExportExcelDialog extends ConsumerStatefulWidget {
  const ExportExcelDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const ExportExcelDialog());
  }

  @override
  ConsumerState<ExportExcelDialog> createState() => _ExportExcelDialogState();
}

class _ExportExcelDialogState extends ConsumerState<ExportExcelDialog> {
  String _period = 'month';
  bool _exporting = false;
  bool _includePayments = true;
  bool _includeCustomers = true;

  ({DateTime from, DateTime to}) get _dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case 'month':
        return (from: DateTime(today.year, today.month, 1), to: today.add(const Duration(days: 1)));
      case '6months':
        return (from: DateTime(today.year, today.month - 5, 1), to: today.add(const Duration(days: 1)));
      case 'year':
        return (from: DateTime(today.year, 1, 1), to: today.add(const Duration(days: 1)));
      default:
        return (from: DateTime(today.year, today.month, 1), to: today.add(const Duration(days: 1)));
    }
  }

  String get _periodLabel {
    switch (_period) {
      case 'month': return 'This Month';
      case '6months': return 'Last 6 Months';
      case 'year': return 'This Year';
      default: return '';
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      if (_includePayments) {
        await _addPaymentsSheet(excel);
      }
      if (_includeCustomers) {
        await _addCustomersSheet(excel);
      }

      final bytes = excel.save();
      if (bytes != null && kIsWeb) {
        _downloadBytes(Uint8List.fromList(bytes), 'Payment_Report_${_periodLabel.replaceAll(' ', '_')}.xlsx');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel exported successfully'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${ApiClient.humanizeError(e)}'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _addPaymentsSheet(Excel excel) async {
    final sheet = excel['Payments'];
    final range = _dateRange;

    final headerStyle = CellStyle(
      bold: true, backgroundColorHex: ExcelColor.fromHexString('#1E2330'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'), fontSize: 11,
    );

    final headers = ['Date', 'Receipt No', 'Customer', 'Mobile', 'Amount', 'Mode', 'Reference', 'Notes'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    int row = 1;
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final result = await ref.read(paymentServiceProvider).getAll(page: page, limit: 200);
      final payments = result.data.where((p) =>
        !p.isCancelled &&
        p.paymentDate.isAfter(range.from) &&
        p.paymentDate.isBefore(range.to),
      ).toList();

      for (final p in payments) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(DateFormat('dd/MM/yyyy').format(p.paymentDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(p.receiptNumber);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(p.customer?.name ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(p.customer?.mobile ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(p.amount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(p.mode.displayName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(p.reference ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(p.notes ?? '');
        row++;
      }

      hasMore = payments.isNotEmpty && result.data.length >= 200;
      page++;
    }

    sheet.setColumnAutoFit(0);
    sheet.setColumnAutoFit(1);
    sheet.setColumnAutoFit(2);
  }

  Future<void> _addCustomersSheet(Excel excel) async {
    final sheet = excel['Customers'];

    final headerStyle = CellStyle(
      bold: true, backgroundColorHex: ExcelColor.fromHexString('#1E2330'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'), fontSize: 11,
    );

    final headers = ['Name', 'Mobile', 'Address', 'Outstanding', 'Total Paid', 'Bills', 'Status'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    int row = 1;
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final result = await ref.read(customerServiceProvider).getAll(page: page, limit: 100);
      for (final c in result.data) {
        final status = c.currentDue > 0 ? (c.totalPaid > 0 ? 'Partial' : 'Unpaid') : 'Paid';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(c.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(c.mobile);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(c.address ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(c.currentDue);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(c.totalPaid);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = IntCellValue(c.billCount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(status);
        row++;
      }
      hasMore = result.data.length >= 100;
      page++;
    }

    sheet.setColumnAutoFit(0);
    sheet.setColumnAutoFit(2);
  }

  void _downloadBytes(Uint8List bytes, String filename) {
    downloadBytes(bytes, filename);
  }

  @override
  Widget build(BuildContext context) {
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
                      color: AppTheme.primaryRed.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.table_chart, size: 22, color: AppTheme.primaryRed),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Export to Excel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Time Period', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _periodOption('month', 'This Month'),
                  const SizedBox(width: 8),
                  _periodOption('6months', '6 Months'),
                  const SizedBox(width: 8),
                  _periodOption('year', 'This Year'),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Sheets to export', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _sheetOption('Payments', _includePayments, (v) => setState(() => _includePayments = v)),
                  const SizedBox(width: 16),
                  _sheetOption('Customers', _includeCustomers, (v) => setState(() => _includeCustomers = v)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Period: $_periodLabel\n${_includePayments && _includeCustomers ? 'Payments + Customers sheets' : _includePayments ? 'Payments sheet only' : 'Customers sheet only'}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  icon: _exporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download, size: 18),
                  label: Text(_exporting ? 'Exporting...' : 'Download Excel'),
                  onPressed: (_exporting || (!_includePayments && !_includeCustomers)) ? null : _export,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
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

  Widget _periodOption(String value, String label) {
    final active = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryRed : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppTheme.primaryRed : AppTheme.border),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.textPrimary)),
        ),
      ),
    );
  }

  Widget _sheetOption(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: AppTheme.primaryRed,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
      ],
    );
  }
}
