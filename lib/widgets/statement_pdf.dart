import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/constants.dart';
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

  Uint8List? logoBytes;
  try {
    final data = await rootBundle.load('assets/logo.png');
    logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {}

  final fromDate = DateFormat('dd MMM yyyy').format(DateTime.parse(from));
  final toDate = DateFormat('dd MMM yyyy').format(DateTime.parse(to));

  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    build: (_) => [
      pw.Container(height: 2, color: PdfColors.red),
      pw.SizedBox(height: 8),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoBytes != null)
            pw.Container(
              width: 50, height: 50,
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
            ),
          if (logoBytes != null) pw.SizedBox(height: 2),
          pw.Text(AppConstants.businessName,
              style: pw.TextStyle(font: fontB, fontSize: 20, color: PdfColors.red, letterSpacing: 1.2)),
          pw.SizedBox(height: 2),
          pw.Text(AppConstants.businessTagline,
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('${AppConstants.businessAddressLine1} ${AppConstants.businessAddressLine2}',
              style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(AppConstants.businessPhone,
              style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey600)),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 0.5, color: PdfColors.grey300),
      pw.SizedBox(height: 8),
      pw.Text('CUSTOMER STATEMENT',
          style: pw.TextStyle(font: fontB, fontSize: 14, color: PdfColors.red, letterSpacing: 1),
          textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 10),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _info('Customer', customerName, font, fontB),
                pw.SizedBox(height: 2),
                _info('Mobile', customerMobile, font, fontB),
                if (customerAddress != null && customerAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  _info('Address', customerAddress, font, fontB),
                ],
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _info('Period', '$fromDate to $toDate', font, fontB, align: pw.TextAlign.right),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(1.2),
          2: pw.FlexColumnWidth(2.5),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(1),
          5: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: ['Date', 'Reference', 'Description', 'Bill', 'Payment', 'Balance'].map((h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: pw.Text(h,
                  style: pw.TextStyle(font: fontB, fontSize: 7.5, color: PdfColors.grey800),
                  textAlign: pw.TextAlign.center),
            )).toList(),
          ),
          if (openingBalance != 0)
            pw.TableRow(
              children: [
                cell(font, '-', textAlign: pw.TextAlign.center),
                cell(font, '', textAlign: pw.TextAlign.center),
                cell(font, 'Opening Balance', bold: true),
                cell(font, '', textAlign: pw.TextAlign.right),
                cell(font, '', textAlign: pw.TextAlign.right),
                cell(font, '\u20B9 ${openingBalance.toStringAsFixed(0)}', textAlign: pw.TextAlign.right, bold: true),
              ],
            ),
          ...rows.map((r) {
            final date = r['date'] != null
                ? DateFormat('dd MMM').format(DateTime.parse(r['date'].toString()))
                : '';
            final desc = r['description']?.toString() ?? '';
            final type = r['type']?.toString() ?? '';
            final ref = type == 'payment' ? 'RCPT' : type == 'bill' ? 'BILL' : '';
            final debit = (r['debit'] ?? 0).toDouble();
            final credit = (r['credit'] ?? 0).toDouble();
            final balance = (r['balance'] ?? 0).toDouble();
            return pw.TableRow(
              children: [
                cell(font, date, textAlign: pw.TextAlign.center),
                cell(font, ref, textAlign: pw.TextAlign.center),
                cell(font, desc),
                cell(font, debit > 0 ? '\u20B9 ${debit.toStringAsFixed(0)}' : '', textAlign: pw.TextAlign.right),
                cell(font, credit > 0 ? '\u20B9 ${credit.toStringAsFixed(0)}' : '', textAlign: pw.TextAlign.right),
                cell(font, '\u20B9 ${balance.toStringAsFixed(0)}', textAlign: pw.TextAlign.right, bold: true),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          children: [
            _sum('Total Bills', '\u20B9 ${totalDebit.toStringAsFixed(0)}', font, fontB),
            pw.SizedBox(height: 2),
            _sum('Total Payments', '\u20B9 ${totalCredit.toStringAsFixed(0)}', font, fontB, color: PdfColors.green700),
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 2),
            _sum('Outstanding Balance', '\u20B9 ${(totalDebit - totalCredit).toStringAsFixed(0)}', font, fontB),
            pw.SizedBox(height: 2),
            _sum('Closing Balance', '\u20B9 ${closingBalance.toStringAsFixed(0)}', font, fontB,
                bold: true, color: closingBalance > 0 ? PdfColors.red : PdfColors.green700),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Container(height: 0.5, color: PdfColors.grey300),
      pw.SizedBox(height: 10),
      pw.Text('Thank You!',
          style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
          textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 1),
      pw.Text('Visit Again',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
          textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 3),
      pw.Text(AppConstants.businessName,
          style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.red, letterSpacing: 1),
          textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 8),
      pw.Container(height: 0.5, color: PdfColors.grey300),
      pw.SizedBox(height: 8),
      pw.Text('STATEMENT',
          style: pw.TextStyle(font: fontB, fontSize: 7, color: PdfColors.grey500, letterSpacing: 1),
          textAlign: pw.TextAlign.center),
    ],
  ));
  return doc.save();
}

pw.Widget cell(pw.Font font, String text,
    {pw.TextAlign textAlign = pw.TextAlign.left, bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: pw.Text(text,
        style: pw.TextStyle(font: bold ? null : font, fontSize: 7.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: textAlign),
  );
}

pw.Widget _info(String label, String value, pw.Font font, pw.Font fontB,
    {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Row(
    mainAxisAlignment: align == pw.TextAlign.right ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
    children: [
      pw.Text('$label: ',
          style: pw.TextStyle(font: fontB, fontSize: 7.5, color: PdfColors.grey600)),
      pw.Text(value,
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.black)),
    ],
  );
}

pw.Widget _sum(String label, String value, pw.Font font, pw.Font fontB,
    {bool bold = false, PdfColor? color}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label,
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
      pw.Text(value,
          style: pw.TextStyle(
              font: bold ? fontB : font,
              fontSize: 9,
              color: color ?? PdfColors.black,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    ],
  );
}
