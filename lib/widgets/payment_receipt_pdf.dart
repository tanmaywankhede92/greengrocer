import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils.dart';
import '../models/customer.dart';

Future<Uint8List> buildPaymentReceiptPdf({
  required String receiptNumber,
  required Customer customer,
  required double amount,
  required String modeDisplay,
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

  const red = PdfColors.red800;
  const textColor = PdfColors.black;
  const muted = PdfColors.grey700;
  const lineColor = PdfColors.grey400;
  const lightLine = PdfColors.grey300;

  String money(double v) => '₹ ${v.toStringAsFixed(0)}';

  pw.Widget thinLine({double thickness = 0.6}) {
    return pw.Container(height: thickness, color: lineColor);
  }

  pw.Widget infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: fontB, fontSize: 9.5, color: textColor),
          ),
        ),
        pw.Text(
          ': ',
          style: pw.TextStyle(font: fontB, fontSize: 9.5, color: textColor),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 9.5, color: textColor),
          ),
        ),
      ],
    );
  }

  pw.Widget amountRow(String label, String value, {PdfColor? valueColor, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: lightLine, width: 0.6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: textColor)),
          pw.Text(value, style: pw.TextStyle(
            font: bold ? fontB : font,
            fontSize: 10,
            color: valueColor ?? textColor,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          )),
        ],
      ),
    );
  }

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      build: (_) => pw.Column(
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
                    infoRow('Receipt No.', receiptNumber),
                    pw.SizedBox(height: 8),
                    infoRow('Customer', customer.name),
                    pw.SizedBox(height: 8),
                    infoRow('Mobile', customer.mobile),
                    pw.SizedBox(height: 8),
                    infoRow('Address', customer.address?.isNotEmpty == true ? customer.address! : '-'),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Container(width: 1, height: 96, color: lineColor),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    infoRow('Date', '${AppUtils.formatDate(paymentDate)}  ${DateFormat('hh:mm a').format(paymentDate)}'),
                    pw.SizedBox(height: 8),
                    infoRow('Mode', modeDisplay),
                    if (reference != null && reference.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      infoRow('Reference', reference),
                    ],
                    if (notes != null && notes.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      infoRow('Notes', notes),
                    ],
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),
          thinLine(thickness: 0.7),
          pw.SizedBox(height: 10),

          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green700, width: 1.2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text('PAYMENT RECEIPT',
                style: pw.TextStyle(font: fontB, fontSize: 14, color: PdfColors.green700, letterSpacing: 1.2)),
            ),
          ),

          pw.SizedBox(height: 16),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: lineColor, width: 0.7),
            ),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Amount Received:  ',
                        style: pw.TextStyle(font: font, fontSize: 13, color: PdfColors.grey700)),
                      pw.Text(money(amount),
                        style: pw.TextStyle(font: fontB, fontSize: 18, color: PdfColors.green700)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                amountRow('Outstanding Before', money(outstandingBefore)),
                amountRow('Outstanding After', money(outstandingAfter),
                  valueColor: outstandingAfter > 0 ? PdfColors.red800 : PdfColors.green700, bold: true),
              ],
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
                pw.Text('RECEIPT',
                  style: pw.TextStyle(font: fontB, fontSize: 9.5, color: muted, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
