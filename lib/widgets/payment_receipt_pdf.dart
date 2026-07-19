import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../core/utils.dart';
import '../models/customer.dart';

Future<Uint8List> buildPaymentReceiptPdf({
  required String receiptNumber,
  required Customer customer,
  required double amount,
  required PaymentMode mode,
  String? reference,
  String? notes,
  required DateTime paymentDate,
  required double outstandingBefore,
  required double outstandingAfter,
}) async {
  final font = await PdfGoogleFonts.nunitoRegular();
  final fontB = await PdfGoogleFonts.nunitoBold();
  final fontI = await PdfGoogleFonts.nunitoItalic();

  Uint8List? logoBytes;
  try {
    final data = await rootBundle.load('assets/logo.png');
    logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {}

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
          pw.SizedBox(height: 2),
          pw.Text(AppConstants.businessSlogan,
              style: pw.TextStyle(font: fontI, fontSize: 8, color: PdfColors.grey500)),
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
      pw.Text('PAYMENT RECEIPT',
          style: pw.TextStyle(font: fontB, fontSize: 14, color: PdfColors.red, letterSpacing: 1),
          textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          children: [
            _row('Receipt No', receiptNumber, font, fontB),
            pw.SizedBox(height: 3),
            _row('Date', '${AppUtils.formatDate(paymentDate)}  ${DateFormat('hh:mm a').format(paymentDate)}', font, fontB),
            pw.SizedBox(height: 3),
            _row('Customer', customer.name, font, fontB),
            pw.SizedBox(height: 3),
            _row('Mobile', customer.mobile, font, fontB),
            if (customer.address != null && customer.address!.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _row('Address', customer.address!, font, fontB),
            ],
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            _row('Amount Paid', '\u20B9 ${amount.toStringAsFixed(0)}', font, fontB, bold: true, amountColor: PdfColors.green700),
            pw.SizedBox(height: 2),
            _row('Payment Mode', mode.displayName, font, fontB),
            if (reference != null && reference.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              _row('Reference', reference, font, fontB),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              _row('Notes', notes, font, fontB),
            ],
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            _row('Outstanding Before', '\u20B9 ${outstandingBefore.toStringAsFixed(0)}', font, fontB),
            pw.SizedBox(height: 3),
            _row('Outstanding After', '\u20B9 ${outstandingAfter.toStringAsFixed(0)}', font, fontB,
                bold: true, amountColor: outstandingAfter > 0 ? PdfColors.red : PdfColors.green700),
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
      pw.Text('RECEIPT',
          style: pw.TextStyle(font: fontB, fontSize: 7, color: PdfColors.grey500, letterSpacing: 1),
          textAlign: pw.TextAlign.center),
    ],
  ));
  return doc.save();
}

pw.Widget _row(String label, String value, pw.Font font, pw.Font fontB,
    {bool bold = false, PdfColor? amountColor}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label,
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
      pw.Text(value,
          style: pw.TextStyle(
              font: bold ? fontB : font,
              fontSize: 9,
              color: amountColor ?? PdfColors.black,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    ],
  );
}
