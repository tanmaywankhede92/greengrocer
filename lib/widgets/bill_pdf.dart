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
  const muted = PdfColor(0.42, 0.42, 0.42);
  const lineC = PdfColor(0.82, 0.82, 0.82);
  const textPrimary = PdfColor(0.12, 0.12, 0.12);
  const tableHeaderBg = PdfColor(0.18, 0.18, 0.23); // Statement dark slate header
  const altRow = PdfColor(0.97, 0.97, 0.98);

  final businessName = settings.businessName.isNotEmpty ? settings.businessName : 'RATHOD ENTERPRISES';
  final tagline = settings.tagline ?? 'Vegetable, Fruits Supplier & Commission Agent';
  final dateStr = DateFormat('dd MMM yyyy').format(billDate);
  final grandTotal = total > 0 ? total : subtotal;

  String money(double v) => v == v.roundToDouble()
      ? '₹ ${v.toStringAsFixed(0)}'
      : '₹ ${v.toStringAsFixed(2)}';

  pw.Widget thinLine({double thickness = 0.5}) {
    return pw.Container(height: thickness, color: lineC);
  }

  pw.Widget amountRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8.5, color: textPrimary)),
          pw.Text(money(value), style: pw.TextStyle(font: font, fontSize: 8.5, color: textPrimary)),
        ],
      ),
    );
  }

  pw.Widget buildHeader(String copyLabel) {
    final address = (settings.address != null && settings.address!.isNotEmpty)
        ? settings.address!
        : 'Shop No.95 Kanji House, Mahatma Phule Market, Cotton Market, Nagpur – 440018';
    final phone = (settings.phone != null && settings.phone!.isNotEmpty)
        ? settings.phone!
        : 'Nitesh : 8087344819   |   Vicky : 9529031540   |   7030914867';

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
                  copyLabel,
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
        ],
      ),
    );
  }

  pw.Widget buildInfoCard() {
    final formattedPayment = (paymentMode != null && paymentMode.isNotEmpty)
        ? (paymentMode.toLowerCase() == 'upi'
            ? 'UPI'
            : paymentMode[0].toUpperCase() + paymentMode.substring(1).toLowerCase())
        : 'Credit';

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
          // Right Column (Bill Details) - NO TIME!
          pw.Expanded(
            flex: 45,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                infoRow('Bill No.', billNumber ?? 'N/A', isBold: true, valueColor: red),
                infoRow('Date', dateStr, isBold: true),
                infoRow('Payment', formattedPayment),
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
          pw.SizedBox(
            width: 22,
            child: pw.Text('Sr.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white)),
          ),
          pw.Expanded(
            flex: 30,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(left: 4),
              child: pw.Text('Product', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white)),
            ),
          ),
          pw.SizedBox(
            width: 38,
            child: pw.Text('Unit', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white)),
          ),
          pw.SizedBox(
            width: 36,
            child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white)),
          ),
          pw.SizedBox(
            width: 48,
            child: pw.Text('Rate (₹)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white)),
          ),
          pw.SizedBox(
            width: 58,
            child: pw.Text('Amount (₹)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.white)),
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
      final qtyStr = displayQty == displayQty.roundToDouble()
          ? displayQty.toStringAsFixed(0)
          : displayQty.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');

      final bgColor = isAdjusted
          ? const PdfColor(1.0, 0.96, 0.90)
          : (i.isOdd ? altRow : null);

      result.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.2, horizontal: 4),
          decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: 22,
                child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 8, color: textPrimary)),
              ),
              pw.Expanded(
                flex: 30,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        productName,
                        style: pw.TextStyle(
                          font: pickFont(productName, bold: false),
                          fontSize: 8,
                          color: textPrimary,
                        ),
                      ),
                      if (isAdjusted)
                        pw.Text(
                          '${item.quantity.toStringAsFixed(0)} → $qtyStr (${item.adjustmentReason ?? "Adjusted"})',
                          style: pw.TextStyle(font: font, fontSize: 6.5, color: const PdfColor(0.9, 0.5, 0.0)),
                        ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(
                width: 38,
                child: pw.Text(item.unit, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 8, color: textPrimary)),
              ),
              pw.SizedBox(
                width: 36,
                child: pw.Text(
                  qtyStr,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: isAdjusted ? const PdfColor(0.9, 0.5, 0.0) : textPrimary,
                  ),
                ),
              ),
              pw.SizedBox(
                width: 48,
                child: pw.Text(
                  item.appliedRate.toStringAsFixed(2),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(font: font, fontSize: 8, color: textPrimary),
                ),
              ),
              pw.SizedBox(
                width: 58,
                child: pw.Text(
                  item.amount.toStringAsFixed(2),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    font: fontB,
                    fontSize: 8,
                    color: isAdjusted ? const PdfColor(0.9, 0.5, 0.0) : textPrimary,
                  ),
                ),
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
      width: 190,
      padding: const pw.EdgeInsets.only(right: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          amountRow('Subtotal', subtotal),
          if (deliveryCharge > 0) amountRow('Delivery Charge', deliveryCharge),
          if (adjustmentAmount > 0) ...[
            amountRow('Grand Total', grandTotal),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Adjustment', style: pw.TextStyle(font: font, fontSize: 8.5, color: const PdfColor(0.9, 0.5, 0.0))),
                  pw.Text('- ${money(adjustmentAmount)}', style: pw.TextStyle(font: font, fontSize: 8.5, color: const PdfColor(0.9, 0.5, 0.0))),
                ],
              ),
            ),
            if (adjustmentNote.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(adjustmentNote, style: pw.TextStyle(font: fontI, fontSize: 7, color: muted)),
              ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: lineC, width: 0.6),
                  bottom: pw.BorderSide(color: lineC, width: 0.6),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Final Amount', style: pw.TextStyle(font: fontB, fontSize: 10.5, color: red)),
                  pw.Text(money(adjustedTotal), style: pw.TextStyle(font: fontB, fontSize: 10.5, color: red)),
                ],
              ),
            ),
          ] else
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: lineC, width: 0.6),
                  bottom: pw.BorderSide(color: lineC, width: 0.6),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Grand Total', style: pw.TextStyle(font: fontB, fontSize: 10.5, color: textPrimary)),
                  pw.Text(money(grandTotal), style: pw.TextStyle(font: fontB, fontSize: 10.5, color: textPrimary)),
                ],
              ),
            ),
          if (paidNow > 0) amountRow('Paid', paidNow),
        ],
      ),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 30, bottom: 2),
            child: stampBytes != null
                ? buildStampPdf(stampBytes, width: 105)
                : pw.SizedBox(),
          ),
          totalsBlock,
        ],
      ),
    );
  }

  // One copy = MultiPage flat list so large bills can paginate cleanly
  List<pw.Widget> buildCopy(String copyLabel) {
    return <pw.Widget>[
      pw.Container(height: 2.5, color: red),
      pw.SizedBox(height: 3),
      buildHeader(copyLabel),
      pw.SizedBox(height: 4),
      buildInfoCard(),
      pw.SizedBox(height: 6),
      buildTableHeader(),
      ...buildTableRows(),
      thinLine(thickness: 0.5),
      buildSummary(),
      pw.SizedBox(height: 6),
    ];
  }

  pw.MultiPage oneCopy(String copyLabel) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      build: (context) => buildCopy(copyLabel),
    );
  }

  final doc = pw.Document();
  doc.addPage(oneCopy('ORIGINAL – Customer Copy'));
  doc.addPage(oneCopy('DUPLICATE – Office Copy'));

  return doc.save();
}
