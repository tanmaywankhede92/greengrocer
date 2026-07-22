import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

String _extractRef(String description) {
  final match = RegExp(r'([A-Za-z]+-\d{6}-\d{4})').firstMatch(description);
  return match != null ? match.group(1)! : '';
}

String _shortLabel(String description) {
  if (description.toLowerCase().contains('opening')) return 'Opening Balance';
  if (description.toLowerCase().contains('payment')) return 'Payment';
  if (description.toLowerCase().contains('cancel')) return 'Cancelled Bill';
  return description.length > 30 ? '${description.substring(0, 30)}...' : description;
}

String _entryType(String description) {
  if (description.toLowerCase().contains('opening')) return 'opening';
  if (description.toLowerCase().contains('payment')) return 'payment';
  if (description.toLowerCase().contains('bill') || description.toLowerCase().contains('sale')) return 'bill';
  if (description.toLowerCase().contains('cancel') || description.toLowerCase().contains('revers')) return 'cancel';
  return 'other';
}

Future<Uint8List> buildStatementPdf({
  required String customerName,
  required String customerMobile,
  String? customerAddress,
  required String from,
  required String to,
  required double openingBalance,
  required double closingBalance,
  required double totalDebit,
  required double totalCredit,
  required List<Map<String, dynamic>> rows,
}) async {
  final font = await PdfGoogleFonts.nunitoRegular();
  final fontB = await PdfGoogleFonts.nunitoBold();
  final fontI = await PdfGoogleFonts.nunitoItalic();

  Uint8List? logoBytes;
  try {
    final data = await rootBundle.load('assets/logo.png');
    logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {}

  const red = PdfColors.red800;
  const textColor = PdfColors.black;
  const muted = PdfColors.grey700;
  const lineColor = PdfColors.grey400;
  const lightLine = PdfColors.grey300;

  final fromDate = DateFormat('dd MMM yyyy').format(DateTime.parse(from));
  final toDate = DateFormat('dd MMM yyyy').format(DateTime.parse(to));
  String money(double v) => '₹ ${v.toStringAsFixed(0)}';

  pw.Widget thinLine({double thickness = 0.6}) {
    return pw.Container(height: thickness, color: lineColor);
  }

  pw.Widget infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 88,
          child: pw.Text(label,
            style: pw.TextStyle(font: fontB, fontSize: 9.5, color: textColor)),
        ),
        pw.Text(': ', style: pw.TextStyle(font: fontB, fontSize: 9.5, color: textColor)),
        pw.Expanded(
          child: pw.Text(value,
            style: pw.TextStyle(font: font, fontSize: 9.5, color: textColor)),
        ),
      ],
    );
  }

  // ── Group rows by date ──
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final r in rows) {
    final dateStr = r['date']?.toString() ?? '';
    final key = dateStr.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr)) : 'Unknown';
    grouped.putIfAbsent(key, () => []).add(r);
  }

  pw.Widget buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 3, color: red),
        pw.SizedBox(height: 12),

        pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null) ...[
                pw.Image(pw.MemoryImage(logoBytes), width: 44, height: 44, fit: pw.BoxFit.contain),
                pw.SizedBox(height: 4),
              ],
              pw.Text('RATHOD ENTERPRISES',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: fontB, fontSize: 24, color: red, letterSpacing: 1.0)),
              pw.SizedBox(height: 4),
              pw.Text('Vegetable, Fruits Supplier & Commission Agent',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: fontB, fontSize: 10.5, color: muted)),
              pw.SizedBox(height: 4),
              pw.Text('Green & Fresh  •  Every Day',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: fontI, fontSize: 9.5, color: PdfColors.green700)),
              pw.SizedBox(height: 8),
              pw.Text('Shop No.95 Kanji House, Mahatma Phule Market,',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 9.5, color: muted)),
              pw.Text('Cotton Market, Nagpur – 440018',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 9.5, color: muted)),
              pw.SizedBox(height: 6),
              pw.Text('Nitesh : 8087344819   |   Vicky : 9529031540   |   7030914867',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 8.8, color: textColor)),
            ],
          ),
        ),

        pw.SizedBox(height: 14),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 12),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  infoRow('Customer', customerName),
                  pw.SizedBox(height: 6),
                  infoRow('Mobile', customerMobile),
                  pw.SizedBox(height: 6),
                  infoRow('Address', customerAddress?.isNotEmpty == true ? customerAddress! : '-'),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Container(width: 1, height: 80, color: lineColor),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  infoRow('Period', '$fromDate – $toDate'),
                  pw.SizedBox(height: 6),
                  infoRow('Generated', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 14),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 10),

        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: pw.BoxDecoration(color: PdfColors.grey900),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 2, child: pw.Text('Date', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
              pw.Expanded(flex: 2, child: pw.Text('Bill No.', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
              pw.Expanded(flex: 2, child: pw.Text('Bill Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
              pw.Expanded(flex: 2, child: pw.Text('Payment', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
              pw.Expanded(flex: 2, child: pw.Text('Balance', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
            ],
          ),
        ),

        if (openingBalance != 0)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 2, child: pw.Text('-', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
                pw.Expanded(flex: 2, child: pw.Text('Opening Balance', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.grey700))),
                pw.Expanded(flex: 2, child: pw.Text('-', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
                pw.Expanded(flex: 2, child: pw.Text('-', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
                pw.Expanded(flex: 2, child: pw.Text(money(openingBalance), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 9, color: textColor))),
              ],
            ),
          ),
      ],
    );
  }

  List<pw.Widget> buildRows() {
    final List<pw.Widget> result = [];
    for (final entry in grouped.entries) {
      final dateKey = entry.key;
      final entries = entry.value;
      result.add(pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: pw.Text(dateKey, style: pw.TextStyle(font: fontB, fontSize: 9, color: red)),
          ),
          ...entries.map((r) {
            final desc = r['description']?.toString() ?? '';
            final ref = _extractRef(desc);
            final label = ref.isNotEmpty ? ref : _shortLabel(desc);
            final debit = (r['debit'] ?? 0).toDouble();
            final credit = (r['credit'] ?? 0).toDouble();
            final balance = (r['balance'] ?? 0).toDouble();
            final type = _entryType(desc);
            final isCancel = type == 'cancel';
            final isPayment = type == 'payment';

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: isCancel ? pw.BoxDecoration(color: PdfColor(0.0, 0.95, 0.88)) : null,
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('-', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9,
                      color: isCancel ? PdfColor(0.9, 0.32, 0.0) : (isPayment ? PdfColors.green700 : textColor)))),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(debit > 0 ? money(debit) : '-', textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: font, fontSize: 9, color: isCancel ? PdfColor(0.9, 0.32, 0.0) : PdfColors.red800))),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(credit > 0 ? money(credit) : '-', textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.green700))),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(money(balance), textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: fontB, fontSize: 9, color: textColor))),
                ],
              ),
            );
          }),
        ],
      ));
    }
    return result;
  }

  pw.Widget buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 14),

        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 260,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lineColor, width: 0.7),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _amountRow('Opening Balance', money(openingBalance), font, fontB),
                  _amountRow('Total Bills', money(totalDebit), font, fontB, valueColor: PdfColors.red800),
                  _amountRow('Total Payments', money(totalCredit), font, fontB, valueColor: PdfColors.green700),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: lineColor, width: 0.7)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Outstanding', style: pw.TextStyle(font: fontB, fontSize: 10, color: textColor)),
                        pw.Text(money(totalDebit - totalCredit),
                          style: pw.TextStyle(font: fontB, fontSize: 10, color: textColor)),
                      ],
                    ),
                  ),
                  pw.Divider(thickness: 0.6, color: lightLine),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Closing Balance', style: pw.TextStyle(font: fontB, fontSize: 11, color: textColor)),
                      pw.Text(money(closingBalance),
                        style: pw.TextStyle(font: fontB, fontSize: 11,
                          color: closingBalance > 0 ? PdfColors.red800 : PdfColors.green700)),
                    ],
                  ),
                  if (closingBalance > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('Amount Payable', style: pw.TextStyle(font: fontB, fontSize: 10, color: PdfColors.red800)),
                  ],
                  if (closingBalance <= 0 && totalCredit > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('Advance / Paid Up', style: pw.TextStyle(font: fontB, fontSize: 10, color: PdfColors.green700)),
                  ],
                ],
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 20),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 10),

        pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Thank You!  Visit Again',
                style: pw.TextStyle(font: font, fontSize: 10, color: muted)),
              pw.SizedBox(height: 4),
              pw.Text('RATHOD ENTERPRISES',
                style: pw.TextStyle(font: fontB, fontSize: 11.5, color: red, letterSpacing: 1.2)),
              pw.SizedBox(height: 8),
              pw.Container(width: double.infinity, height: 1, color: PdfColors.grey500),
              pw.SizedBox(height: 8),
              pw.Text('STATEMENT',
                style: pw.TextStyle(font: fontB, fontSize: 9.5, color: muted, letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      header: (_) => buildHeader(),
      build: (_) => buildRows(),
      footer: (_) => buildFooter(),
    ),
  );
  return doc.save();
}

pw.Widget _amountRow(String label, String value, pw.Font font, pw.Font fontB, {PdfColor? valueColor}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black)),
        pw.Text(value, style: pw.TextStyle(
          font: fontB, fontSize: 10, color: valueColor ?? PdfColors.black)),
      ],
    ),
  );
}
