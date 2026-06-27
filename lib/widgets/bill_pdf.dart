import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils.dart';
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
  required double previousDue,
  required double paidNow,
  required double newDue,
  required String deliveryBoyName,
  required List<LineItem> items,
  required DateTime billDate,
  String? paymentMode,
  required bool isReprint,
}) async {
  final font = await PdfGoogleFonts.nunitoRegular();
  final fontB = await PdfGoogleFonts.nunitoBold();

  pw.Widget buildPage({required bool isCustomerCopy}) {
    return pw.Column(
      children: [
        pw.Header(
          level: 0,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(settings.businessName.toUpperCase(),
                        style: pw.TextStyle(font: fontB, fontSize: 20, letterSpacing: 1.2)),
                    if (settings.tagline != null && settings.tagline!.isNotEmpty)
                      pw.Text(settings.tagline!,
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    if (settings.address != null && settings.address!.isNotEmpty)
                      pw.Text(settings.address!,
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                    if (settings.phone != null && settings.phone!.isNotEmpty)
                      pw.Text('Phone: ${settings.phone}',
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                    if (settings.gstNumber != null && settings.gstNumber!.isNotEmpty)
                      pw.Text('GST: ${settings.gstNumber}',
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: isCustomerCopy ? PdfColors.red50 : PdfColors.blue50,
                      border: pw.Border.all(color: isCustomerCopy ? PdfColors.red : PdfColors.blue, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      isCustomerCopy ? 'ORIGINAL - Customer Copy' : 'DUPLICATE - Office Copy',
                      style: pw.TextStyle(
                        font: fontB, fontSize: 9,
                        color: isCustomerCopy ? PdfColors.red : PdfColors.blue,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                    child: pw.Text(
                      billNumber != null ? 'Bill #: $billNumber' : 'Bill #: ____________',
                      style: pw.TextStyle(font: fontB, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 1.5),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date: ${AppUtils.formatDate(billDate)}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.SizedBox(height: 6),
                  pw.Text('Delivery Boy: ${deliveryBoyName.isNotEmpty ? deliveryBoyName : '-'}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.SizedBox(height: 6),
                  pw.Text('Payment: ${paymentMode ?? '-'}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Bill To:', style: pw.TextStyle(font: fontB, fontSize: 10, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Text(customerName, style: pw.TextStyle(font: fontB, fontSize: 12)),
                  pw.Text(customerMobile, style: pw.TextStyle(font: font, fontSize: 10)),
                  if (customerAddress != null && customerAddress.isNotEmpty)
                    pw.Text(customerAddress, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.6),
            1: pw.FlexColumnWidth(2.8),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1.2),
            4: pw.FlexColumnWidth(1.4),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey800),
              children: ['#', 'Item', 'Qty', 'Rate', 'Amount'].map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(h, style: pw.TextStyle(font: fontB, fontSize: 10, color: PdfColors.white)),
              )).toList(),
            ),
            ...items.asMap().entries.map((e) {
              final i = e.value;
              return pw.TableRow(
                decoration: e.key.isOdd ? pw.BoxDecoration(color: PdfColors.grey100) : null,
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${e.key + 1}', style: pw.TextStyle(font: font, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(i.productName, style: pw.TextStyle(font: font, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${i.quantity.toStringAsFixed(0)} ${i.unit}', style: pw.TextStyle(font: font, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs ${i.appliedRate.toStringAsFixed(0)}', style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs ${i.amount.toStringAsFixed(0)}', style: pw.TextStyle(font: fontB, fontSize: 10), textAlign: pw.TextAlign.right)),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 280,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _totRow('Subtotal:', subtotal, font, fontB),
                  pw.Divider(),
                  _totRow('Total:', total, font, fontB, bold: true, fontSize: 14),
                  pw.SizedBox(height: 4),
                  _totRow('Previous Due:', previousDue, font, fontB, color: PdfColors.orange700),
                  pw.Divider(),
                  _totRow('Paid:', paidNow, font, fontB, color: PdfColors.green700),
                  pw.SizedBox(height: 4),
                  _totRow('New Due:', newDue, font, fontB,
                      bold: true, fontSize: 13,
                      color: newDue > 0 ? PdfColors.red : PdfColors.green700),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(settings.footerNote ?? '',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Authorised Signature',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                pw.SizedBox(height: 20),
                pw.Text('_________________________',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        if (isCustomerCopy) pw.SizedBox(height: 8),
        if (isCustomerCopy)
          pw.Text('Thank you! Visit Again',
              style: pw.TextStyle(font: fontB, fontSize: 10, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center),
      ],
    );
  }

  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (_) => [buildPage(isCustomerCopy: true)],
  ));
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (_) => [buildPage(isCustomerCopy: false)],
  ));
  return doc.save();
}

pw.Widget _totRow(String label, double amount, pw.Font font, pw.Font fontB,
    {bool bold = false, double fontSize = 11, PdfColor? color}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(font: bold ? fontB : font, fontSize: fontSize)),
      pw.Text('Rs ${amount.toStringAsFixed(0)}',
          style: pw.TextStyle(font: fontB, fontSize: fontSize, color: color)),
    ],
  );
}
