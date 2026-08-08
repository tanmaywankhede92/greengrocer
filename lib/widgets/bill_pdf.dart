import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/business_settings.dart';
import '../widgets/bill_item_row.dart';

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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 16),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 220,
            padding: const pw.EdgeInsets.only(right: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                amountRow('Subtotal', subtotal),
                if (deliveryCharge > 0) amountRow('Delivery Charge', deliveryCharge),
                amountRow('Grand Total', grandTotal),
                if (adjustmentAmount > 0) ...[
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
          ),
        ),
      ],
    );
  }

  pw.Widget buildCopy(String copyLabel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
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
        pw.SizedBox(height: 18),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Thank You!  Visit Again', style: pw.TextStyle(font: font, fontSize: 11, color: muted)),
              pw.SizedBox(height: 4),
              pw.Text(businessName, style: pw.TextStyle(font: fontB, fontSize: 12, color: red, letterSpacing: 1.2)),
              pw.SizedBox(height: 8),
              pw.Container(height: 1, color: lineC),
              pw.SizedBox(height: 8),
              pw.Text('ORIGINAL – $copyLabel', style: pw.TextStyle(font: font, fontSize: 10, color: muted)),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Page oneCopy(String copyLabel) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      // Each copy is a single atomic page: never split a bill across pages.
      // FittedBox(scaleDown) shrinks oversized bills to fit and keeps small
      // bills at their natural size. The SizedBox pins the content width so
      // flex-width tables compute their columns correctly.
      build: (_) => pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: pw.Alignment.topCenter,
        child: pw.SizedBox(
          width: PdfPageFormat.a4.width - 40,
          child: buildCopy(copyLabel),
        ),
      ),
    );
  }

  final doc = pw.Document();
  doc.addPage(oneCopy('Customer Copy'));
  doc.addPage(oneCopy('Office Copy'));

  return doc.save();
}
