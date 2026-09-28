import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/business_settings.dart';
import '../widgets/bill_item_row.dart';
import '../widgets/bill_stamp.dart';

class BillPdfFonts {
  static pw.Font? nunitoRegular;
  static pw.Font? nunitoBold;
  static pw.Font? nunitoItalic;
  static pw.Font? notoSansDevanagariRegular;
  static pw.Font? notoSansDevanagariBold;
  static Uint8List? cachedStampBytes;

  static Future<void> preload() async {
    try {
      final results = await Future.wait([
        PdfGoogleFonts.nunitoRegular(),
        PdfGoogleFonts.nunitoBold(),
        PdfGoogleFonts.nunitoItalic(),
        PdfGoogleFonts.notoSansDevanagariRegular(),
        PdfGoogleFonts.notoSansDevanagariBold(),
      ]);
      nunitoRegular = results[0];
      nunitoBold = results[1];
      nunitoItalic = results[2];
      notoSansDevanagariRegular = results[3];
      notoSansDevanagariBold = results[4];
      cachedStampBytes = await loadStampBytes();
    } catch (_) {}
  }
}

Future<Uint8List> buildBillPdf({
  required BusinessSettings settings,
  required String? billNumber,
  required String customerName,
  required String customerMobile,
  String? customerAddress,
  required double subtotal,
  required double total,
  required double deliveryCharge,
  required double paidNow,
  required List<LineItem> items,
  required DateTime billDate,
  String? paymentMode,
  required bool isReprint,
  double adjustmentAmount = 0,
  String adjustmentNote = '',
}) async {
  final font = BillPdfFonts.nunitoRegular ?? await PdfGoogleFonts.nunitoRegular();
  final fontB = BillPdfFonts.nunitoBold ?? await PdfGoogleFonts.nunitoBold();
  final fontI = BillPdfFonts.nunitoItalic ?? await PdfGoogleFonts.nunitoItalic();
  final fontHi = BillPdfFonts.notoSansDevanagariRegular ?? await PdfGoogleFonts.notoSansDevanagariRegular();
  final fontHiB = BillPdfFonts.notoSansDevanagariBold ?? await PdfGoogleFonts.notoSansDevanagariBold();

  BillPdfFonts.nunitoRegular ??= font;
  BillPdfFonts.nunitoBold ??= fontB;
  BillPdfFonts.nunitoItalic ??= fontI;
  BillPdfFonts.notoSansDevanagariRegular ??= fontHi;
  BillPdfFonts.notoSansDevanagariBold ??= fontHiB;

  final stampBytes = BillPdfFonts.cachedStampBytes ?? await loadStampBytes();
  BillPdfFonts.cachedStampBytes ??= stampBytes;

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

  final businessName = settings.businessName.isNotEmpty ? settings.businessName : 'RATHOD ENTERPRISES';
  final tagline = settings.tagline ?? 'Vegetable, Fruits Supplier & Commission Agent';
  final dateStr = DateFormat('dd MMM yyyy').format(billDate);
  final timeStr = DateFormat('hh:mm a').format(billDate);
  final grandTotal = total > 0 ? total : subtotal;

  String money(double v) => '₹ ${v.toStringAsFixed(0)}';

  pw.Widget thinLine({double thickness = 0.7}) {
    return pw.Container(height: thickness, color: lineC);
  }

  pw.Widget infoField(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 72,
          child: pw.Text(label, style: pw.TextStyle(font: fontB, fontSize: 10.5, color: textPrimary)),
        ),
        pw.Text(':  ', style: const pw.TextStyle(fontSize: 10.5)),
        pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10.5, color: textPrimary))),
      ],
    );
  }

  pw.Widget amountRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11, color: textPrimary)),
          pw.Text(money(value), style: pw.TextStyle(font: font, fontSize: 11, color: textPrimary)),
        ],
      ),
    );
  }

  pw.Widget buildTableHeader() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12),
      child: pw.Table(
        border: pw.TableBorder.all(color: lineC, width: 0.7),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.55),
          1: const pw.FlexColumnWidth(2.25),
          2: const pw.FlexColumnWidth(1.0),
          3: const pw.FlexColumnWidth(0.85),
          4: const pw.FlexColumnWidth(1.0),
          5: const pw.FlexColumnWidth(1.15),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: headerBg),
            children: ['Sr.', 'Product', 'Unit', 'Qty', 'Rate (₹)', 'Amount (₹)'].map((h) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Text(
                  h,
                  textAlign: h == 'Product' ? pw.TextAlign.left : pw.TextAlign.center,
                  style: pw.TextStyle(font: fontB, fontSize: 10, color: textPrimary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  List<pw.Widget> buildTableRows() {
    final List<pw.Widget> result = [];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final productName = item.productNameHindi.isNotEmpty
          ? '${item.productName} (${item.productNameHindi})'
          : item.productName;
      final isAdjusted = item.adjustedQuantity != null;
      final displayQty = item.adjustedQuantity ?? item.quantity;
      final qtyStr = displayQty == displayQty.roundToDouble() ? displayQty.toStringAsFixed(0) : displayQty.toStringAsFixed(1);

      result.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Table(
            border: pw.TableBorder.all(color: lineC, width: 0.7),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.55),
              1: const pw.FlexColumnWidth(2.25),
              2: const pw.FlexColumnWidth(1.0),
              3: const pw.FlexColumnWidth(0.85),
              4: const pw.FlexColumnWidth(1.0),
              5: const pw.FlexColumnWidth(1.15),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(productName, style: pw.TextStyle(font: pickFont(productName, bold: false), fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        if (isAdjusted)
                          pw.Text(
                            '${item.quantity.toStringAsFixed(0)} → $qtyStr (${item.adjustmentReason ?? "Adjusted"})',
                            style: pw.TextStyle(font: font, fontSize: 8, color: const PdfColor(0.9, 0.5, 0.0)),
                          ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Text(item.unit, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Text(qtyStr,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: font, fontSize: 10, color: isAdjusted ? const PdfColor(0.9, 0.5, 0.0) : null),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Text(money(item.appliedRate), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Text(money(item.amount), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 10, color: isAdjusted ? const PdfColor(0.9, 0.5, 0.0) : null)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return result;
  }

  pw.Widget buildSummary() {
    final adjustedTotal = grandTotal - adjustmentAmount;
    final totalsBlock = pw.Container(
      width: 220,
      padding: const pw.EdgeInsets.only(right: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          amountRow('Subtotal', subtotal),
          if (deliveryCharge > 0) amountRow('Delivery Charge', deliveryCharge),
          if (adjustmentAmount > 0) ...[
            amountRow('Grand Total', grandTotal),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Adjustment', style: pw.TextStyle(font: font, fontSize: 11, color: const PdfColor(0.9, 0.5, 0.0))),
                  pw.Text('- ${money(adjustmentAmount)}', style: pw.TextStyle(font: font, fontSize: 11, color: const PdfColor(0.9, 0.5, 0.0))),
                ],
              ),
            ),
            if (adjustmentNote.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(adjustmentNote, style: pw.TextStyle(font: fontI, fontSize: 8.5, color: muted)),
              ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: lineC, width: 0.7),
                  bottom: pw.BorderSide(color: lineC, width: 0.7),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Final Amount', style: pw.TextStyle(font: fontB, fontSize: 13, color: red)),
                  pw.Text(money(adjustedTotal), style: pw.TextStyle(font: fontB, fontSize: 13, color: red)),
                ],
              ),
            ),
          ] else
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: lineC, width: 0.7),
                  bottom: pw.BorderSide(color: lineC, width: 0.7),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Grand Total', style: pw.TextStyle(font: fontB, fontSize: 13, color: textPrimary)),
                  pw.Text(money(grandTotal), style: pw.TextStyle(font: fontB, fontSize: 13, color: textPrimary)),
                ],
              ),
            ),
          if (paidNow > 0) amountRow('Paid', paidNow),
        ],
      ),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 110, bottom: 4),
            child: stampBytes != null
                ? buildStampPdf(stampBytes, width: 150)
                : pw.SizedBox(),
          ),
          totalsBlock,
        ],
      ),
    );
  }

  pw.Widget buildFooter(String copyLabel) {
    return pw.Container(
      width: PdfPageFormat.a4.width - 40,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          thinLine(thickness: 0.7),
          pw.SizedBox(height: 8),
          pw.Text('Thank You!  Visit Again', style: pw.TextStyle(font: font, fontSize: 10.5, color: muted)),
          pw.SizedBox(height: 4),
          pw.Text(businessName, style: pw.TextStyle(font: fontB, fontSize: 11.5, color: red, letterSpacing: 1.2)),
          pw.SizedBox(height: 8),
          pw.Container(height: 1, color: lineC),
          pw.SizedBox(height: 8),
          pw.Text(copyLabel, style: pw.TextStyle(font: font, fontSize: 9.5, color: muted)),
        ],
      ),
    );
  }

  // Returned as a flat list (not a single Column) so that MultiPage can break
  // the content across as many pages as it needs. One copy always starts on a
  // fresh page; anything that does not fit moves to the next page.
  List<pw.Widget> buildCopy(String copyLabel) {
    return <pw.Widget>[
      pw.Container(height: 3, color: red),
      pw.SizedBox(height: 12),
      pw.Center(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              businessName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: fontB, fontSize: 20, color: red, letterSpacing: 1),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              tagline,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: fontB, fontSize: 11, color: muted),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Green & Fresh  •  Every Day',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: fontI, fontSize: 10, color: green),
            ),
            pw.SizedBox(height: 6),
            if (settings.address != null && settings.address!.isNotEmpty)
              pw.Text(settings.address!, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 10, color: muted))
            else ...[
              pw.Text('Shop No.95 Kanji House, Mahatma Phule Market,', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 10, color: muted)),
              pw.Text('Cotton Market, Nagpur – 440018', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 10, color: muted)),
            ],
            if (settings.phone != null && settings.phone!.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(settings.phone!, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 9.5, color: textPrimary)),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 14),
      thinLine(thickness: 0.7),
      pw.SizedBox(height: 12),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  infoField('Bill No.', billNumber ?? 'N/A'),
                  pw.SizedBox(height: 6),
                  infoField('Customer', customerName),
                  pw.SizedBox(height: 6),
                  infoField('Mobile', customerMobile),
                  pw.SizedBox(height: 6),
                  infoField('Address', (customerAddress != null && customerAddress.isNotEmpty) ? customerAddress : '-'),
                ],
              ),
            ),
            pw.Container(width: 1, height: 80, color: lineC),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    infoField('Date', dateStr),
                    pw.SizedBox(height: 6),
                    infoField('Time', timeStr),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      thinLine(thickness: 0.7),
      pw.SizedBox(height: 8),
      buildTableHeader(),
      ...buildTableRows(),
      buildSummary(),
      pw.SizedBox(height: 20),
      buildFooter(copyLabel),
      pw.SizedBox(height: 12),
    ];
  }

  // One copy = one MultiPage. It always begins on a fresh sheet, and a bill with
  // a lot of items grows extra pages instead of being shrunk to fit, so the
  // customer copy and the office copy never share a page.
  // The office copy is the duplicate, not a second original.
  pw.MultiPage oneCopy(String copyLabel) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      build: (context) => buildCopy(copyLabel),
    );
  }

  final doc = pw.Document();
  doc.addPage(oneCopy('ORIGINAL – Customer Copy'));
  doc.addPage(oneCopy('DUPLICATE – Office Copy'));

  return doc.save();
}
