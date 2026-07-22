import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/business_settings.dart';
import '../widgets/bill_item_row.dart';

String _toInvoiceNumber(String? billNumber, DateTime billDate, String prefix) {
  if (billNumber == null || billNumber.isEmpty) {
    return 'INV-${billDate.year}-000001';
  }
  final parts = billNumber.split('-');
  if (parts.length >= 3) {
    final seq = parts.last;
    return '$prefix-${billDate.year}-$seq';
  }
  return '$prefix-${billDate.year}-0001';
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
}) async {
  final font = await PdfGoogleFonts.nunitoRegular();
  final fontB = await PdfGoogleFonts.nunitoBold();
  final fontI = await PdfGoogleFonts.nunitoItalic();

  Uint8List? logoBytes;
  try {
    final data = await rootBundle.load('assets/logo.png');
    logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {}

  const primary = PdfColor(0.72, 0.08, 0.08);
  const darkText = PdfColor(0.15, 0.15, 0.15);
  const muted = PdfColor(0.45, 0.45, 0.45);
  const lightMuted = PdfColor(0.6, 0.6, 0.6);
  const lineC = PdfColor(0.82, 0.82, 0.85);
  const lightBg = PdfColor(0.97, 0.97, 0.98);
  const green = PdfColor(0.15, 0.55, 0.25);
  const red = PdfColor(0.8, 0.15, 0.1);

  final invoiceNumber = _toInvoiceNumber(billNumber, billDate, settings.invoicePrefix);
  final grandTotal = total > 0 ? total : subtotal;
  final remaining = grandTotal - paidNow;
  final billDateStr = DateFormat('dd MMM yyyy').format(billDate);
  final billTimeStr = DateFormat('hh:mm a').format(billDate);
  final mode = paymentMode ?? 'Cash';

  String money(double v) => '₹ ${v.toStringAsFixed(0)}';

  pw.Widget divider({double thickness = 0.5, PdfColor color = lineC}) {
    return pw.Container(height: thickness, color: color);
  }

  pw.Widget label(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColor(0.95, 0.95, 0.96),
      ),
      child: pw.Text(text, style: pw.TextStyle(font: fontB, fontSize: 7.5, color: lightMuted, letterSpacing: 0.8)),
    );
  }

  pw.Widget infoLine(String info, String val) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 72,
          child: pw.Text(info, style: pw.TextStyle(font: font, fontSize: 9, color: lightMuted)),
        ),
        pw.Expanded(
          child: pw.Text(val, style: pw.TextStyle(font: fontB, fontSize: 9, color: darkText)),
        ),
      ],
    );
  }

  pw.Widget summaryRow(String lbl, String val, {PdfColor? vc, bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(lbl, style: pw.TextStyle(font: bold ? fontB : font, fontSize: bold ? 10 : 9.5, color: vc ?? darkText)),
        pw.Text(val, style: pw.TextStyle(font: fontB, fontSize: bold ? 10 : 9.5, color: vc ?? darkText)),
      ],
    );
  }

  pw.Widget buildCompanyHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 4, color: primary),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoBytes != null) ...[
              pw.Container(
                width: 52, height: 52,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: lineC, width: 0.5),
                ),
                child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 14),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    settings.businessName.isNotEmpty ? settings.businessName : 'RATHOD ENTERPRISES',
                    style: pw.TextStyle(font: fontB, fontSize: 20, color: primary, letterSpacing: 0.8),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    settings.tagline ?? 'Vegetable, Fruits Supplier & Commission Agent',
                    style: pw.TextStyle(font: font, fontSize: 9, color: muted),
                  ),
                  pw.SizedBox(height: 4),
                  if (settings.address != null && settings.address!.isNotEmpty)
                    pw.Text(settings.address!, style: pw.TextStyle(font: font, fontSize: 8.5, color: lightMuted)),
                  if (settings.gstNumber != null && settings.gstNumber!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('GSTIN: ${settings.gstNumber}', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: darkText)),
                  ],
                  if (settings.phone != null && settings.phone!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(settings.phone!, style: pw.TextStyle(font: font, fontSize: 8.5, color: lightMuted)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const pw.BoxDecoration(color: primary),
              child: pw.Text('TAX INVOICE', style: pw.TextStyle(font: fontB, fontSize: 13, color: PdfColors.white, letterSpacing: 1.5)),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        divider(thickness: 1),
      ],
    );
  }

  pw.Widget buildInfoSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  label('INVOICE TO'),
                  pw.SizedBox(height: 4),
                  pw.Text(customerName, style: pw.TextStyle(font: fontB, fontSize: 11, color: darkText)),
                  pw.SizedBox(height: 2),
                  pw.Text(customerMobile, style: pw.TextStyle(font: font, fontSize: 9.5, color: muted)),
                   if (customerAddress != null && customerAddress.isNotEmpty) ...[
                     pw.SizedBox(height: 2),
                     pw.Text(customerAddress, style: pw.TextStyle(font: font, fontSize: 9, color: lightMuted)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Container(width: 1, height: 72, color: lineC),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  infoLine('Invoice No.', invoiceNumber),
                  pw.SizedBox(height: 5),
                  infoLine('Date', billDateStr),
                  pw.SizedBox(height: 5),
                  infoLine('Time', billTimeStr),
                  pw.SizedBox(height: 5),
                  infoLine('Payment', mode),
                  if (isReprint) ...[
                    pw.SizedBox(height: 5),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: const pw.BoxDecoration(color: PdfColor(1.0, 0.94, 0.87)),
                      child: pw.Text('REPRINT', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColor(0.8, 0.5, 0.0), letterSpacing: 1)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        divider(thickness: 0.5),
      ],
    );
  }

  pw.Widget buildTableHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColor(0.15, 0.15, 0.2)),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 30, child: pw.Text('#', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: PdfColors.white), textAlign: pw.TextAlign.center)),
          pw.Expanded(flex: 40, child: pw.Text('Description', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: PdfColors.white))),
          pw.SizedBox(width: 45, child: pw.Text('Unit', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: PdfColors.white), textAlign: pw.TextAlign.center)),
          pw.SizedBox(width: 40, child: pw.Text('Qty', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: PdfColors.white), textAlign: pw.TextAlign.right)),
          pw.SizedBox(width: 65, child: pw.Text('Rate', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: PdfColors.white), textAlign: pw.TextAlign.right)),
          pw.SizedBox(width: 72, child: pw.Text('Amount', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: PdfColors.white), textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  List<pw.Widget> buildRows() {
    final List<pw.Widget> result = [];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final productName = item.productNameHindi.isNotEmpty
          ? '${item.productName} (${item.productNameHindi})'
          : item.productName;

      result.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: i.isOdd ? const pw.BoxDecoration(color: lightBg) : null,
          child: pw.Row(
            children: [
              pw.SizedBox(width: 30, child: pw.Text('${i + 1}', style: pw.TextStyle(font: font, fontSize: 9, color: muted), textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 40, child: pw.Text(productName, style: pw.TextStyle(font: font, fontSize: 9, color: darkText))),
              pw.SizedBox(width: 45, child: pw.Text(item.unit, style: pw.TextStyle(font: font, fontSize: 9, color: muted), textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 40, child: pw.Text(item.quantity == item.quantity.roundToDouble() ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1), style: pw.TextStyle(font: font, fontSize: 9, color: darkText), textAlign: pw.TextAlign.right)),
              pw.SizedBox(width: 65, child: pw.Text(money(item.appliedRate), style: pw.TextStyle(font: font, fontSize: 9, color: darkText), textAlign: pw.TextAlign.right)),
              pw.SizedBox(width: 72, child: pw.Text(money(item.amount), style: pw.TextStyle(font: fontB, fontSize: 9, color: darkText), textAlign: pw.TextAlign.right)),
            ],
          ),
        ),
      );
      result.add(divider(thickness: 0.3));
    }
    return result;
  }

  pw.Widget buildTableFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: const pw.BoxDecoration(color: lightBg),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text('Total ${items.length} item(s)', style: pw.TextStyle(font: font, fontSize: 8.5, color: muted))),
          pw.SizedBox(width: 40),
          pw.SizedBox(width: 65),
          pw.SizedBox(
            width: 72,
            child: pw.Text(money(subtotal), style: pw.TextStyle(font: fontB, fontSize: 9, color: darkText), textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  pw.Widget buildSummary() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 55,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (settings.footerNote != null && settings.footerNote!.isNotEmpty) ...[
                    label('NOTES'),
                    pw.SizedBox(height: 4),
                    pw.Text(settings.footerNote!, style: pw.TextStyle(font: font, fontSize: 8.5, color: lightMuted)),
                    pw.SizedBox(height: 12),
                  ],
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor(0.98, 0.98, 0.99),
                      border: pw.Border.all(color: lineC, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Terms & Conditions', style: pw.TextStyle(font: fontB, fontSize: 8.5, color: darkText)),
                        pw.SizedBox(height: 4),
                        pw.Text('1. Goods once sold will not be taken back or exchanged.', style: pw.TextStyle(font: font, fontSize: 8, color: lightMuted)),
                        pw.Text('2. Payment due as per agreed terms.', style: pw.TextStyle(font: font, fontSize: 8, color: lightMuted)),
                        pw.Text('3. Subject to local jurisdiction.', style: pw.TextStyle(font: font, fontSize: 8, color: lightMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              flex: 45,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: lineC, width: 0.7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    summaryRow('Subtotal', money(subtotal)),
                    if (deliveryCharge > 0) ...[
                      pw.SizedBox(height: 4),
                      summaryRow('Delivery Charge', money(deliveryCharge)),
                    ],
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 6),
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
                          pw.Text('Grand Total', style: pw.TextStyle(font: fontB, fontSize: 11, color: darkText)),
                          pw.Text(money(grandTotal), style: pw.TextStyle(font: fontB, fontSize: 11, color: darkText)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    summaryRow('Amount Received', money(paidNow), vc: green, bold: true),
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 6),
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: pw.BoxDecoration(
                        color: remaining > 0 ? PdfColor(1.0, 0.94, 0.93) : PdfColor(0.93, 0.97, 0.93),
                        border: pw.Border.all(
                          color: remaining > 0 ? PdfColor(0.9, 0.6, 0.5) : PdfColor(0.6, 0.85, 0.65),
                          width: 0.7,
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            remaining > 0 ? 'Balance Due' : 'PAID IN FULL',
                            style: pw.TextStyle(font: fontB, fontSize: 10, color: remaining > 0 ? red : green),
                          ),
                          pw.Text(
                            remaining > 0 ? money(remaining) : 'Paid',
                            style: pw.TextStyle(font: fontB, fontSize: 10, color: remaining > 0 ? red : green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 24),
        divider(thickness: 0.7),
        pw.SizedBox(height: 14),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Thank You for Your Business!', style: pw.TextStyle(font: fontI, fontSize: 10, color: muted)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    settings.businessName.isNotEmpty ? settings.businessName : 'RATHOD ENTERPRISES',
                    style: pw.TextStyle(font: fontB, fontSize: 9, color: primary, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 120, height: 1, color: darkText),
                pw.SizedBox(height: 4),
                pw.Text('Authorized Signature', style: pw.TextStyle(font: font, fontSize: 8, color: lightMuted)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),
        divider(thickness: 0.3),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('This is a computer-generated invoice. No physical signature required.', style: pw.TextStyle(font: fontI, fontSize: 7.5, color: lightMuted)),
            pw.Text(isReprint ? 'REPRINT' : (billNumber ?? ''), style: pw.TextStyle(font: fontB, fontSize: 7.5, color: lightMuted, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  pw.Widget continuationHeader(String copyTitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: const pw.BoxDecoration(color: lightBg),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(copyTitle, style: pw.TextStyle(font: fontB, fontSize: 8, color: lightMuted, letterSpacing: 0.5)),
              pw.Text('$invoiceNumber  |  $customerName', style: pw.TextStyle(font: font, fontSize: 8, color: lightMuted)),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        buildTableHeader(),
      ],
    );
  }

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      header: (context) {
        if (context.pageNumber == 1) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [buildCompanyHeader(), buildInfoSection(), buildTableHeader()],
          );
        }
        return continuationHeader('TAX INVOICE');
      },
      build: (_) => [...buildRows(), buildTableFooter(), buildSummary()],
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(height: 4),
          divider(thickness: 0.3),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Customer Copy', style: pw.TextStyle(font: font, fontSize: 7.5, color: lightMuted)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: fontB, fontSize: 7.5, color: lightMuted)),
            ],
          ),
        ],
      ),
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      header: (context) {
        if (context.pageNumber == 1) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [buildCompanyHeader(), buildInfoSection(), buildTableHeader()],
          );
        }
        return continuationHeader('TAX INVOICE – OFFICE COPY');
      },
      build: (_) => [...buildRows(), buildTableFooter(), buildSummary()],
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(height: 4),
          divider(thickness: 0.3),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Office Copy', style: pw.TextStyle(font: font, fontSize: 7.5, color: lightMuted)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: fontB, fontSize: 7.5, color: lightMuted)),
            ],
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
