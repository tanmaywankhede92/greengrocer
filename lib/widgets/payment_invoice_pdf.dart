import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/business_settings.dart';
import '../models/customer.dart';

Future<Uint8List> buildPaymentInvoicePdf({
  required BusinessSettings settings,
  required String receiptNumber,
  required Customer customer,
  required double amount,
  required String paymentMode,
  required double previousOutstanding,
  required double remainingOutstanding,
  required DateTime paymentDate,
  String? remarks,
}) async {
  final font = await PdfGoogleFonts.nunitoRegular();
  final fontB = await PdfGoogleFonts.nunitoBold();
  final fontI = await PdfGoogleFonts.nunitoItalic();
  final fontHi = await PdfGoogleFonts.notoSansDevanagariRegular();
  final fontHiB = await PdfGoogleFonts.notoSansDevanagariBold();

  bool hasDevanagari(String text) => text.codeUnits.any((c) => c >= 0x0900 && c <= 0x097F);
  pw.Font pickFont(String text, {required bool bold}) {
    return hasDevanagari(text) ? (bold ? fontHiB : fontHi) : (bold ? fontB : font);
  }

  const red = PdfColor(0.717, 0.11, 0.11);
  const muted = PdfColor(0.459, 0.459, 0.459);
  const lineC = PdfColor(0.741, 0.741, 0.741);
  const textPrimary = PdfColor(0.129, 0.129, 0.129);
  const green = PdfColor(0.298, 0.686, 0.314);
  const headerBg = PdfColor(0.961, 0.961, 0.961);
  const cardBorder = PdfColor(0.85, 0.85, 0.85);

  final businessName = settings.businessName.isNotEmpty ? settings.businessName : 'RATHOD ENTERPRISES';
  final tagline = settings.tagline ?? 'Vegetable, Fruits Supplier & Commission Agent';
  final dateStr = DateFormat('dd MMM yyyy').format(paymentDate);
  final timeStr = DateFormat('hh:mm a').format(paymentDate);

  final invoiceNumber = 'INV-${paymentDate.year}${paymentDate.month.toString().padLeft(2, '0')}${paymentDate.day.toString().padLeft(2, '0')}-${paymentDate.millisecond.toString().padLeft(4, '0')}';

  String money(double v) => '₹ ${v.toStringAsFixed(0)}';

  pw.Widget thinLine({double thickness = 0.5, PdfColor color = lineC}) {
    return pw.Container(height: thickness, color: color);
  }

  pw.Widget sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(title, style: pw.TextStyle(font: fontB, fontSize: 11, color: red, letterSpacing: 0.8)),
    );
  }

  pw.Widget tableRow(String label, String value, {bool bold = false, bool usePickFont = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(font: fontB, fontSize: 10, color: muted)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: usePickFont ? pickFont(value, bold: bold) : (bold ? fontB : font),
                fontSize: bold ? 11 : 10.5,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget amountRow(String label, double value, {bool highlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: highlight ? fontB : font, fontSize: highlight ? 12 : 10.5, color: textPrimary)),
          pw.Text(money(value), style: pw.TextStyle(font: highlight ? fontB : font, fontSize: highlight ? 13 : 10.5, color: highlight ? green : textPrimary)),
        ],
      ),
    );
  }

  pw.Widget infoCard({required String title, required List<pw.Widget> children}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: cardBorder, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          sectionTitle(title),
          ...children,
        ],
      ),
    );
  }

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      build: (_) => [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(height: 4, color: red),
            pw.SizedBox(height: 16),

            // Company Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessName, style: pw.TextStyle(font: fontB, fontSize: 18, color: red, letterSpacing: 0.8)),
                      pw.SizedBox(height: 2),
                      pw.Text(tagline, style: pw.TextStyle(font: fontB, fontSize: 9.5, color: muted)),
                      pw.SizedBox(height: 2),
                      pw.Text('Green & Fresh  •  Every Day', style: pw.TextStyle(font: fontI, fontSize: 9, color: green)),
                      pw.SizedBox(height: 5),
                      if (settings.address != null && settings.address!.isNotEmpty)
                        pw.Text(settings.address!, style: pw.TextStyle(font: font, fontSize: 9, color: muted))
                      else ...[
                        pw.Text('Shop No.95 Kanji House, Mahatma Phule Market,', style: pw.TextStyle(font: font, fontSize: 9, color: muted)),
                        pw.Text('Cotton Market, Nagpur – 440018', style: pw.TextStyle(font: font, fontSize: 9, color: muted)),
                      ],
                      if (settings.phone != null && settings.phone!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(settings.phone!, style: pw.TextStyle(font: font, fontSize: 9, color: textPrimary)),
                      ],
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const pw.BoxDecoration(color: red),
                  child: pw.Column(
                    children: [
                      pw.Text('PAYMENT', style: pw.TextStyle(font: fontB, fontSize: 11, color: PdfColors.white, letterSpacing: 1.5)),
                      pw.Text('INVOICE', style: pw.TextStyle(font: fontB, fontSize: 14, color: PdfColors.white, letterSpacing: 2)),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            thinLine(thickness: 1, color: red),
            pw.SizedBox(height: 14),

            // Invoice Number — prominent
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const pw.BoxDecoration(color: headerBg),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('Invoice No: ', style: pw.TextStyle(font: font, fontSize: 10.5, color: muted)),
                      pw.Text(invoiceNumber, style: pw.TextStyle(font: fontB, fontSize: 13, color: textPrimary, letterSpacing: 0.5)),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text('Receipt No: ', style: pw.TextStyle(font: font, fontSize: 10.5, color: muted)),
                      pw.Text(receiptNumber, style: pw.TextStyle(font: fontB, fontSize: 10.5, color: textPrimary)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Two-column cards: Invoice Info | Customer Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: infoCard(
                    title: 'Invoice Information',
                    children: [
                      tableRow('Invoice Date', dateStr),
                      thinLine(thickness: 0.3),
                      tableRow('Payment Time', timeStr),
                      thinLine(thickness: 0.3),
                      tableRow('Payment Mode', paymentMode.toUpperCase()),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: infoCard(
                    title: 'Customer Information',
                    children: [
                      tableRow('Name', customer.name, usePickFont: true),
                      thinLine(thickness: 0.3),
                      tableRow('Mobile', customer.mobile),
                      if (customer.address != null && customer.address!.isNotEmpty) ...[
                        thinLine(thickness: 0.3),
                        tableRow('Address', customer.address!),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Payment Summary card
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: cardBorder, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  sectionTitle('Payment Summary'),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(left: pw.BorderSide(color: green, width: 3)),
                    ),
                    child: pw.Column(
                      children: [
                        amountRow('Amount Received', amount, highlight: true),
                        thinLine(thickness: 0.3),
                        amountRow('Previous Outstanding', previousOutstanding),
                        thinLine(thickness: 0.3),
                        amountRow('Remaining Outstanding', remainingOutstanding),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (remarks != null && remarks.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: cardBorder, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Remarks'),
                    pw.Text(remarks, style: pw.TextStyle(font: font, fontSize: 10.5, color: textPrimary)),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 40),

            // Signature Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const pw.BoxDecoration(color: headerBg),
                      child: pw.Text('Authorized Signature', style: pw.TextStyle(font: fontB, fontSize: 9, color: muted)),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 140, height: 1, color: lineC),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: $dateStr', style: pw.TextStyle(font: font, fontSize: 8, color: muted)),
                  ],
                ),
                pw.SizedBox(width: 60),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const pw.BoxDecoration(color: headerBg),
                      child: pw.Text('Customer Signature', style: pw.TextStyle(font: fontB, fontSize: 9, color: muted)),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 140, height: 1, color: lineC),
                    pw.SizedBox(height: 4),
                    pw.Text('Received with thanks', style: pw.TextStyle(font: fontI, fontSize: 8, color: muted)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 24),
            thinLine(thickness: 0.5, color: red),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Thank You!  Visit Again', style: pw.TextStyle(font: fontI, fontSize: 11, color: muted)),
                  pw.SizedBox(height: 3),
                  pw.Text(businessName, style: pw.TextStyle(font: fontB, fontSize: 11, color: red, letterSpacing: 1)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 4, color: red),
          ],
        ),
      ],
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(height: 4),
          thinLine(thickness: 0.3),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ORIGINAL – Payment Invoice', style: pw.TextStyle(font: font, fontSize: 7.5, color: muted)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: fontB, fontSize: 7.5, color: muted)),
            ],
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
