import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/business_settings.dart';
import 'bill_stamp.dart';

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
  BusinessSettings? settings,
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

  final stampBytes = await loadStampBytes();

  const red = PdfColor(0.717, 0.11, 0.11);
  const muted = PdfColor(0.459, 0.459, 0.459);
  const lineC = PdfColor(0.741, 0.741, 0.741);
  const textPrimary = PdfColor(0.129, 0.129, 0.129);
  const tableHeaderBg = PdfColor(0.18, 0.18, 0.23); // #2D2D3A dark slate
  const altRow = PdfColor(0.97, 0.97, 0.98);

  final businessName = (settings != null && settings.businessName.isNotEmpty)
      ? settings.businessName
      : 'RATHOD ENTERPRISES';
  final tagline = (settings != null && settings.tagline != null && settings.tagline!.isNotEmpty)
      ? settings.tagline!
      : 'Vegetable, Fruits Supplier & Commission Agent';
  final address = (settings != null && settings.address != null && settings.address!.isNotEmpty)
      ? settings.address!
      : 'Shop No.95 Kanji House, Mahatma Phule Market, Cotton Market, Nagpur – 440018';
  final phone = (settings != null && settings.phone != null && settings.phone!.isNotEmpty)
      ? settings.phone!
      : 'Nitesh : 8087344819   |   Vicky : 9529031540   |   7030914867';

  final fromDate = DateFormat('dd MMM yyyy').format(DateTime.parse(from));
  final toDate = DateFormat('dd MMM yyyy').format(DateTime.parse(to));
  final generatedAt = DateFormat('dd MMM yyyy').format(DateTime.now());
  String money(double v) => '₹ ${v.toStringAsFixed(0)}';

  pw.Widget thinLine({double thickness = 0.5}) {
    return pw.Container(height: thickness, color: lineC);
  }

  final netChange = totalDebit - totalCredit;
  final hasRows = rows.isNotEmpty;

  pw.Widget buildHeader() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 80), // balance spacer
              pw.Text(
                businessName,
                style: pw.TextStyle(font: fontB, fontSize: 16, color: red, letterSpacing: 1.0),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  'STATEMENT',
                  style: pw.TextStyle(font: fontB, fontSize: 7, color: textPrimary),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            tagline,
            style: pw.TextStyle(font: fontB, fontSize: 8.5, color: muted),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            address,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: font, fontSize: 7.5, color: muted),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            phone,
            style: pw.TextStyle(font: fontB, fontSize: 8, color: textPrimary),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'FSSAI No. : 21522056000645',
            style: pw.TextStyle(font: fontB, fontSize: 8, color: textPrimary),
          ),
        ],
      ),
    );
  }

  pw.Widget buildInfoCard() {
    pw.Widget infoRow(String label, String value, {bool isBold = false, PdfColor? valueColor}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 52,
              child: pw.Text(
                label,
                style: pw.TextStyle(font: fontB, fontSize: 8, color: muted),
              ),
            ),
            pw.Text(': ', style: pw.TextStyle(font: fontB, fontSize: 8, color: muted)),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  font: isBold ? fontB : font,
                  fontSize: 8,
                  color: valueColor ?? textPrimary,
                ),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: const PdfColor(0.985, 0.985, 0.99),
        border: pw.Border.all(color: lineC, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left Column (Customer Details)
          pw.Expanded(
            flex: 55,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                infoRow('Customer', customerName, isBold: true),
                infoRow('Mobile', customerMobile.isNotEmpty ? customerMobile : '-'),
                infoRow('Address', (customerAddress != null && customerAddress.isNotEmpty) ? customerAddress : '-'),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Vertical divider between columns
          pw.Container(width: 0.6, height: 42, color: lineC),
          pw.SizedBox(width: 12),
          // Right Column (Statement Details) - NO TIME!
          pw.Expanded(
            flex: 45,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                infoRow('Period', '$fromDate – $toDate', isBold: true),
                infoRow('Date', generatedAt, isBold: true),
                infoRow(
                  'Closing',
                  money(closingBalance),
                  isBold: true,
                  valueColor: closingBalance > 0 ? red : PdfColors.green700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget buildTableHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: const pw.BoxDecoration(color: tableHeaderBg),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 20, child: pw.Text('Date', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 18, child: pw.Text('Type', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 28, child: pw.Text('Ref No.', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 30, child: pw.Text('Description', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 26, child: pw.Text('Debit', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 26, child: pw.Text('Credit', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 28, child: pw.Text('Balance', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white))),
        ],
      ),
    );
  }

  pw.Widget buildOpeningRow() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 20, child: pw.Text('-', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500))),
          pw.Expanded(flex: 18, child: pw.Text('Opening', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.grey700))),
          pw.Expanded(flex: 28, child: pw.Text('-', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500))),
          pw.Expanded(flex: 30, child: pw.Text('Opening Balance', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.grey700))),
          pw.Expanded(flex: 26, child: pw.Text('-', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500))),
          pw.Expanded(flex: 26, child: pw.Text('-', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500))),
          pw.Expanded(flex: 28, child: pw.Text(money(openingBalance), textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: fontB, fontSize: 8, color: textPrimary))),
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
        : (isPayment ? PdfColors.green700 : (type == 'bill' ? red : textPrimary));

    final dateFormatted = dateStr.isNotEmpty
        ? DateFormat('dd MMM').format(DateTime.parse(dateStr))
        : '-';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
      child: pw.Row(
        children: [
          pw.Expanded(flex: 20, child: pw.Text(dateFormatted,
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700))),
          pw.Expanded(flex: 18, child: pw.Text(label,
            style: pw.TextStyle(font: fontB, fontSize: 8, color: typeColor))),
          pw.Expanded(flex: 28, child: pw.Text(ref.isNotEmpty ? ref : '-',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700))),
          pw.Expanded(flex: 30, child: pw.Text(shortDesc,
            style: pw.TextStyle(font: font, fontSize: 8, color: textPrimary))),
          pw.Expanded(flex: 26, child: pw.Text(debit > 0 ? money(debit) : '-',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: font, fontSize: 8,
              color: isAdjustment ? const PdfColor(0.9, 0.32, 0.0) : red))),
          pw.Expanded(flex: 26, child: pw.Text(credit > 0 ? money(credit) : '-',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: font, fontSize: 8,
              color: isAdjustment ? const PdfColor(0.9, 0.32, 0.0) : PdfColors.green700))),
          pw.Expanded(flex: 28, child: pw.Text(money(balance),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: fontB, fontSize: 8, color: textPrimary))),
        ],
      ),
    );
  }

  pw.Widget buildNoTransactions() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: pw.Center(
        child: pw.Text('No transactions found for selected period.',
          style: pw.TextStyle(font: fontI, fontSize: 9, color: PdfColors.grey500)),
      ),
    );
  }

  pw.Widget buildSummary() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 30, bottom: 2),
            child: stampBytes != null
                ? buildStampPdf(stampBytes, width: 120)
                : pw.SizedBox(),
          ),
          pw.SizedBox(
            width: 240,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lineC, width: 0.6),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _summaryRow('Opening Balance', money(openingBalance), font, fontB),
                  _summaryRow('Bills (Selected Period)', money(totalDebit), font, fontB, valueColor: red),
                  _summaryRow('Payments (Selected Period)', money(totalCredit), font, fontB, valueColor: PdfColors.green700),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: lineC, width: 0.6)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Net Change', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: textPrimary)),
                        pw.Text(money(netChange),
                          style: pw.TextStyle(font: fontB, fontSize: 8.5, color: netChange >= 0 ? red : PdfColors.green700)),
                      ],
                    ),
                  ),
                  pw.Divider(thickness: 0.5, color: lineC),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Closing Balance', style: pw.TextStyle(font: fontB, fontSize: 9.5, color: textPrimary)),
                      pw.Text(money(closingBalance),
                        style: pw.TextStyle(font: fontB, fontSize: 9.5,
                          color: closingBalance > 0 ? red : PdfColors.green700)),
                    ],
                  ),
                  if (closingBalance > 0) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('Amount Payable', style: pw.TextStyle(font: fontB, fontSize: 8, color: red)),
                  ],
                  if (closingBalance <= 0 && totalCredit > 0) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('Advance / Paid Up', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.green700)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      header: (context) {
        if (context.pageNumber == 1) {
          return pw.SizedBox();
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
            pw.SizedBox(height: 6),
          ],
        );
      },
      build: (context) {
        final List<pw.Widget> content = [];
        content.add(pw.Container(height: 2.5, color: red));
        content.add(pw.SizedBox(height: 3));
        content.add(buildHeader());
        content.add(pw.SizedBox(height: 4));
        content.add(buildInfoCard());
        content.add(pw.SizedBox(height: 6));
        content.add(buildTableHeader());

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

        content.add(thinLine(thickness: 0.5));
        content.add(buildSummary());
        return content;
      },
    ),
  );
  return doc.save();
}

pw.Widget _summaryRow(String label, String value, pw.Font font, pw.Font fontB, {PdfColor? valueColor}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.black)),
        pw.Text(value, style: pw.TextStyle(
          font: fontB, fontSize: 8.5, color: valueColor ?? PdfColors.black)),
      ],
    ),
  );
}
