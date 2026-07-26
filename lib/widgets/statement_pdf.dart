import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

String _extractRef(String description) {
  final match = RegExp(r'([A-Za-z]+-\d{6}-\d{4})').firstMatch(description);
  return match != null ? match.group(1)! : '';
}

String _typeLabel(String type) {
  switch (type) {
    case 'bill':
      return 'Bill';
    case 'payment':
      return 'Payment';
    case 'adjustment':
      return 'Adjustment';
    case 'opening_balance':
      return 'Opening Balance';
    default:
      return 'Other';
  }
}

String _shortDesc(String description) {
  if (description.toLowerCase().contains('opening')) return 'Opening Balance';
  return description.length > 40 ? '${description.substring(0, 40)}...' : description;
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
  const altRow = PdfColor(0.97, 0.97, 0.98);

  final fromDate = DateFormat('dd MMM yyyy').format(DateTime.parse(from));
  final toDate = DateFormat('dd MMM yyyy').format(DateTime.parse(to));
  final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
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

  final netChange = totalDebit - totalCredit;
  final hasRows = rows.isNotEmpty;

  pw.Widget buildCompanyHeader() {
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
                  infoRow('Generated', generatedAt),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 14),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget buildTableHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: const pw.BoxDecoration(color: PdfColors.grey900),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 20, child: pw.Text('Date', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
          pw.Expanded(flex: 18, child: pw.Text('Type', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
          pw.Expanded(flex: 28, child: pw.Text('Ref No.', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
          pw.Expanded(flex: 30, child: pw.Text('Description', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
          pw.Expanded(flex: 26, child: pw.Text('Debit', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
          pw.Expanded(flex: 26, child: pw.Text('Credit', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
          pw.Expanded(flex: 28, child: pw.Text('Balance', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.white))),
        ],
      ),
    );
  }

  pw.Widget buildOpeningRow() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 20, child: pw.Text('-', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
          pw.Expanded(flex: 18, child: pw.Text('Opening', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.grey700))),
          pw.Expanded(flex: 28, child: pw.Text('-', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
          pw.Expanded(flex: 30, child: pw.Text('Opening Balance', style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.grey700))),
          pw.Expanded(flex: 26, child: pw.Text('-', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
          pw.Expanded(flex: 26, child: pw.Text('-', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500))),
          pw.Expanded(flex: 28, child: pw.Text(money(openingBalance), textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: fontB, fontSize: 9, color: textColor))),
        ],
      ),
    );
  }

  pw.Widget buildTransactionRow(Map<String, dynamic> r, bool isAlt) {
    final dateStr = r['date']?.toString() ?? '';
    final type = (r['type'] ?? 'other').toString();
    final desc = r['description']?.toString() ?? '';
    final debit = (r['debit'] ?? 0).toDouble();
    final credit = (r['credit'] ?? 0).toDouble();
    final balance = (r['balance'] ?? 0).toDouble();
    final ref = _extractRef(desc);
    final shortDesc = _shortDesc(desc);
    final label = _typeLabel(type);

    final isAdjustment = type == 'adjustment';
    final isPayment = type == 'payment';

    final bgColor = isAdjustment
        ? const PdfColor(1.0, 0.95, 0.88)
        : (isAlt ? altRow : null);

    final typeColor = isAdjustment
        ? const PdfColor(0.9, 0.32, 0.0)
        : (isPayment ? PdfColors.green700 : (type == 'bill' ? red : textColor));

    final dateFormatted = dateStr.isNotEmpty
        ? DateFormat('dd MMM').format(DateTime.parse(dateStr))
        : '-';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
      child: pw.Row(
        children: [
          pw.Expanded(flex: 20, child: pw.Text(dateFormatted,
            style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.grey700))),
          pw.Expanded(flex: 18, child: pw.Text(label,
            style: pw.TextStyle(font: fontB, fontSize: 8.5, color: typeColor))),
          pw.Expanded(flex: 28, child: pw.Text(ref.isNotEmpty ? ref : '-',
            style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.grey700))),
          pw.Expanded(flex: 30, child: pw.Text(shortDesc,
            style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.grey800))),
          pw.Expanded(flex: 26, child: pw.Text(debit > 0 ? money(debit) : '-',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: font, fontSize: 8.5,
              color: isAdjustment ? const PdfColor(0.9, 0.32, 0.0) : red))),
          pw.Expanded(flex: 26, child: pw.Text(credit > 0 ? money(credit) : '-',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: font, fontSize: 8.5,
              color: isAdjustment ? const PdfColor(0.9, 0.32, 0.0) : PdfColors.green700))),
          pw.Expanded(flex: 28, child: pw.Text(money(balance),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: fontB, fontSize: 8.5, color: textColor))),
        ],
      ),
    );
  }

  pw.Widget buildNoTransactions() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: pw.Center(
        child: pw.Text('No transactions found for selected period.',
          style: pw.TextStyle(font: fontI, fontSize: 10, color: PdfColors.grey500)),
      ),
    );
  }

  pw.Widget buildSummary() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 18),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 12),

        pw.Text('Summary', style: pw.TextStyle(font: fontB, fontSize: 12, color: textColor)),
        pw.SizedBox(height: 8),

        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 280,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lineColor, width: 0.7),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _summaryRow('Opening Balance', money(openingBalance), font, fontB),
                  _summaryRow('Bills (Selected Period)', money(totalDebit), font, fontB, valueColor: red),
                  _summaryRow('Payments (Selected Period)', money(totalCredit), font, fontB, valueColor: PdfColors.green700),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: lineColor, width: 0.7)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Net Change', style: pw.TextStyle(font: fontB, fontSize: 10, color: textColor)),
                        pw.Text(money(netChange),
                          style: pw.TextStyle(font: fontB, fontSize: 10, color: netChange >= 0 ? red : PdfColors.green700)),
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
                          color: closingBalance > 0 ? red : PdfColors.green700)),
                    ],
                  ),
                  if (closingBalance > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('Amount Payable', style: pw.TextStyle(font: fontB, fontSize: 10, color: red)),
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
              pw.Text('CUSTOMER LEDGER STATEMENT',
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
      header: (context) {
        if (context.pageNumber == 1) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildCompanyHeader(),
              buildTableHeader(),
            ],
          );
        }
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CUSTOMER LEDGER STATEMENT',
                    style: pw.TextStyle(font: fontB, fontSize: 8, color: muted, letterSpacing: 0.5)),
                  pw.Text('$customerName  |  $fromDate – $toDate',
                    style: pw.TextStyle(font: font, fontSize: 8, color: muted)),
                ],
              ),
            ),
            pw.SizedBox(height: 4),
            buildTableHeader(),
          ],
        );
      },
      build: (context) {
        final List<pw.Widget> content = [];

        if (!hasRows) {
          content.add(buildNoTransactions());
        } else {
          if (openingBalance != 0) {
            content.add(buildOpeningRow());
          }

          for (var i = 0; i < rows.length; i++) {
            content.add(buildTransactionRow(rows[i], i % 2 == 1));
          }
        }

        content.add(buildSummary());
        return content;
      },
      footer: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.SizedBox(height: 6),
            pw.Container(height: 0.5, color: lightLine),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Rathod Enterprises', style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey500)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: fontB, fontSize: 7.5, color: PdfColors.grey600)),
              ],
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

pw.Widget _summaryRow(String label, String value, pw.Font font, pw.Font fontB, {PdfColor? valueColor}) {
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
