// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import '../core/utils.dart';
// import '../models/business_settings.dart';
// import '../widgets/bill_item_row.dart';

// Future<Uint8List> buildBillPdf({
//   required BusinessSettings settings,
//   required String? billNumber,
//   required String customerName,
//   required String customerMobile,
//   String? customerAddress,
//   required double subtotal,
//   required double total,
//   required double previousDue,
//   required double paidNow,
//   required double newDue,
//   required String deliveryBoyName,
//   String deliveryBoyPhone = '',
//   required List<LineItem> items,
//   required DateTime billDate,
//   String? paymentMode,
//   required bool isReprint,
// }) async {
//   final font = await PdfGoogleFonts.nunitoRegular();
//   final fontB = await PdfGoogleFonts.nunitoBold();
//   final fontI = await PdfGoogleFonts.nunitoItalic();

//   Uint8List? logoBytes;
//   try {
//     final data = await rootBundle.load('assets/logo.png');
//     logoBytes = data.buffer.asUint8List();
//   } catch (_) {}

//   pw.Widget cell(String text, {pw.TextAlign align = pw.TextAlign.center, bool bold = false}) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
//       child: pw.Text(text,
//           style: pw.TextStyle(font: bold ? fontB : font, fontSize: 7.5), textAlign: align),
//     );
//   }

//   pw.Widget sumItem(String label, double amount) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         pw.Text(label,
//             style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.black)),
//         pw.Text('\u20B9 ${amount.toStringAsFixed(0)}',
//             style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.black)),
//       ],
//     );
//   }

//   pw.Widget infoField(String label, String value) {
//     return pw.Row(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text('$label: ',
//             style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey600)),
//         pw.Expanded(
//           child: pw.Text(value,
//               style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.black)),
//         ),
//       ],
//     );
//   }

//   pw.Widget buildPage({required bool isCustomerCopy}) {
//     final copyLabel = isReprint
//         ? 'REPRINT'
//         : isCustomerCopy
//             ? 'ORIGINAL'
//             : 'DUPLICATE';
//     final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';

//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Container(height: 2, color: PdfColors.red),
//         pw.SizedBox(height: 8),
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.center,
//           children: [
//             if (logoBytes != null)
//               pw.Container(
//                 width: 35, height: 35,
//                 child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
//               ),
//             if (logoBytes != null) pw.SizedBox(height: 2),
//             pw.Text('RATHOD ENTERPRISES',
//                 style: pw.TextStyle(font: fontB, fontSize: 20, color: PdfColors.red, letterSpacing: 1.2)),
//             pw.SizedBox(height: 2),
//             pw.Text('Vegetable, Fruits Supplier & Commission Agent',
//                 style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
//             pw.SizedBox(height: 2),
//             pw.Text('Green & Fresh  \u2022  Every Day',
//                 style: pw.TextStyle(font: fontI, fontSize: 8, color: PdfColors.grey500)),
//             pw.SizedBox(height: 4),
//             pw.Text('Shop No.95 Kanji House,',
//                 style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
//             pw.Text('Mahatma Phule Market, Cotton Market,',
//                 style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
//             pw.Text('Nagpur \u2013 440018',
//                 style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
//             pw.SizedBox(height: 2),
//             pw.Text('Nitesh : 8087344819  |  Vicky : 9529031540  |  7030914867',
//                 style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey600)),
//           ],
//         ),
//         pw.SizedBox(height: 8),
//         pw.Container(height: 0.5, color: PdfColors.grey300),
//         pw.SizedBox(height: 6),
//         pw.Row(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Expanded(
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   infoField('Bill No', billNumber ?? '____________'),
//                   pw.SizedBox(height: 2),
//                   pw.Text(customerName,
//                       style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.black)),
//                   pw.SizedBox(height: 1),
//                   pw.Text(customerMobile,
//                       style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.black)),
//                   pw.SizedBox(height: 1),
//                   if (customerAddress != null && customerAddress.isNotEmpty)
//                     pw.Text(customerAddress,
//                         style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
//                 ],
//               ),
//             ),
//             pw.Expanded(
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   infoField('Date', AppUtils.formatDate(billDate)),
//                   pw.SizedBox(height: 1),
//                   infoField('Time', DateFormat('hh:mm a').format(billDate)),
//                   if (deliveryBoyName.isNotEmpty) ...[
//                     pw.SizedBox(height: 1),
//                     infoField('Delivery', deliveryBoyName),
//                   ],
//                   if (deliveryBoyPhone.isNotEmpty) ...[
//                     pw.SizedBox(height: 1),
//                     infoField('Phone', deliveryBoyPhone),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//         pw.SizedBox(height: 10),
//         pw.Table(
//           border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
//           columnWidths: const {
//             0: pw.FlexColumnWidth(0.5),
//             1: pw.FlexColumnWidth(3),
//             2: pw.FlexColumnWidth(0.8),
//             3: pw.FlexColumnWidth(0.7),
//             4: pw.FlexColumnWidth(0.9),
//             5: pw.FlexColumnWidth(1),
//           },
//           children: [
//             pw.TableRow(
//               decoration: const pw.BoxDecoration(color: PdfColors.white),
//               children: ['Sr', 'Product', 'Unit', 'Qty', 'Rate', 'Amount'].map((h) => pw.Padding(
//                 padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
//                 child: pw.Text(h,
//                     style: pw.TextStyle(font: fontB, fontSize: 7.5, color: PdfColors.grey800),
//                     textAlign: h == 'Product' ? pw.TextAlign.left : pw.TextAlign.center),
//               )).toList(),
//             ),
//             ...items.asMap().entries.map((e) {
//               final i = e.value;
//               final productName = i.productNameHindi.isNotEmpty
//                   ? '${i.productName} (${i.productNameHindi})'
//                   : i.productName;
//               return pw.TableRow(
//                 children: [
//                   cell('${e.key + 1}'),
//                   pw.Padding(
//                     padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
//                     child: pw.Text(productName,
//                         style: pw.TextStyle(font: fontB, fontSize: 7.5)),
//                   ),
//                   cell(i.unit),
//                   cell(i.quantity.toStringAsFixed(0)),
//                   pw.Padding(
//                     padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
//                     child: pw.Text('\u20B9${i.appliedRate.toStringAsFixed(0)}',
//                         style: pw.TextStyle(font: font, fontSize: 7.5),
//                         textAlign: pw.TextAlign.right),
//                   ),
//                   pw.Padding(
//                     padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
//                     child: pw.Text('\u20B9${i.amount.toStringAsFixed(0)}',
//                         style: pw.TextStyle(font: fontB, fontSize: 7.5),
//                         textAlign: pw.TextAlign.right),
//                   ),
//                 ],
//               );
//             }),
//           ],
//         ),
//         pw.SizedBox(height: 10),
//         pw.Row(
//           mainAxisAlignment: pw.MainAxisAlignment.end,
//           children: [
//             pw.SizedBox(
//               width: 240,
//               child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//               children: [
//                 sumItem('Subtotal', subtotal),
//                 if (previousDue > 0) ...[
//                   pw.SizedBox(height: 2),
//                   sumItem('Previous Due', previousDue),
//                 ],
//                 pw.SizedBox(height: 2),
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Text('Grand Total',
//                         style: pw.TextStyle(font: fontB, fontSize: 10, color: PdfColors.black)),
//                     pw.Text('\u20B9 ${(subtotal + previousDue).toStringAsFixed(0)}',
//                         style: pw.TextStyle(font: fontB, fontSize: 10, color: PdfColors.red)),
//                   ],
//                 ),
//                 pw.Divider(thickness: 0.5, color: PdfColors.grey300),
//                 pw.SizedBox(height: 2),
//                 sumItem('Paid', paidNow),
//                 pw.SizedBox(height: 2),
//                 sumItem('Remaining Due', newDue),
//               ],
//             ),
//             ),
//           ],
//         ),
//         pw.SizedBox(height: 16),
//         pw.Container(height: 0.5, color: PdfColors.grey300),
//         pw.SizedBox(height: 8),
//         pw.Text('Thank You!',
//             style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
//             textAlign: pw.TextAlign.center),
//         pw.SizedBox(height: 1),
//         pw.Text('Visit Again',
//             style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
//             textAlign: pw.TextAlign.center),
//         pw.SizedBox(height: 3),
//         pw.Text('RATHOD ENTERPRISES',
//             style: pw.TextStyle(font: fontB, fontSize: 9, color: PdfColors.red, letterSpacing: 1),
//             textAlign: pw.TextAlign.center),
//         pw.SizedBox(height: 6),
//         pw.Container(height: 0.5, color: PdfColors.grey300),
//         pw.SizedBox(height: 6),
//         pw.Text('$copyLabel \u2013 $copySuffix',
//             style: pw.TextStyle(font: fontB, fontSize: 7, color: PdfColors.grey500, letterSpacing: 1),
//             textAlign: pw.TextAlign.center),
//       ],
//     );
//   }

//   final doc = pw.Document();
//   doc.addPage(pw.MultiPage(
//     pageFormat: PdfPageFormat.a4,
//     margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     build: (_) => [buildPage(isCustomerCopy: true)],
//   ));
//   doc.addPage(pw.MultiPage(
//     pageFormat: PdfPageFormat.a4,
//     margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     build: (_) => [buildPage(isCustomerCopy: false)],
//   ));
//   return doc.save();
// }

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  String deliveryBoyPhone = '',
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
    logoBytes = data.buffer.asUint8List();
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
          width: 88,
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

  pw.Widget amountRow(String label, double value, {bool grand = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: lightLine, width: 0.6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: grand ? fontB : font,
              fontSize: grand ? 11.5 : 10,
              color: textColor,
            ),
          ),
          pw.Text(
            money(value),
            style: pw.TextStyle(
              font: grand ? fontB : font,
              fontSize: grand ? 11.5 : 10,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget buildCopy({required bool isCustomerCopy}) {
    final copyLabel = isReprint
        ? 'REPRINT'
        : isCustomerCopy
            ? 'ORIGINAL'
            : 'DUPLICATE';
    final copySuffix = isCustomerCopy ? 'Customer Copy' : 'Office Copy';
    final grandTotal = total > 0 ? total : (subtotal + previousDue);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 3, color: red),
        pw.SizedBox(height: 12),

        pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null) ...[
                pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 44,
                  height: 44,
                  fit: pw.BoxFit.contain,
                ),
                pw.SizedBox(height: 4),
              ],
              pw.Text(
                'RATHOD ENTERPRISES',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontB,
                  fontSize: 24,
                  color: red,
                  letterSpacing: 1.0,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Vegetable, Fruits Supplier & Commission Agent',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: fontB, fontSize: 10.5, color: muted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Green & Fresh  •  Every Day',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontI,
                  fontSize: 9.5,
                  color: PdfColors.green700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Shop No.95 Kanji House, Mahatma Phule Market,',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 9.5, color: muted),
              ),
              pw.Text(
                'Cotton Market, Nagpur – 440018',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 9.5, color: muted),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Nitesh : 8087344819   |   Vicky : 9529031540   |   7030914867',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 8.8, color: textColor),
              ),
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
                  infoRow('Bill No.', billNumber ?? '__________'),
                  pw.SizedBox(height: 8),
                  infoRow('Customer', customerName),
                  pw.SizedBox(height: 8),
                  infoRow('Mobile', customerMobile),
                  pw.SizedBox(height: 8),
                  infoRow('Address', customerAddress?.isNotEmpty == true ? customerAddress! : '-'),
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
                  infoRow('Date', AppUtils.formatDate(billDate)),
                  pw.SizedBox(height: 8),
                  infoRow('Time', DateFormat('hh:mm a').format(billDate)),
                  pw.SizedBox(height: 8),
                  infoRow('Delivery Boy', deliveryBoyName.isNotEmpty ? deliveryBoyName : '-'),
                  pw.SizedBox(height: 8),
                  infoRow('Phone', deliveryBoyPhone.isNotEmpty ? deliveryBoyPhone : '-'),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 12),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 10),

        pw.Table(
          border: pw.TableBorder.all(color: lineColor, width: 0.7),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.55),
            1: pw.FlexColumnWidth(2.25),
            2: pw.FlexColumnWidth(1.0),
            3: pw.FlexColumnWidth(0.85),
            4: pw.FlexColumnWidth(1.0),
            5: pw.FlexColumnWidth(1.15),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                'Sr.',
                'Product',
                'Unit',
                'Qty',
                'Rate (₹)',
                'Amount (₹)',
              ].map((h) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: pw.Text(
                    h,
                    textAlign: h == 'Product' ? pw.TextAlign.left : pw.TextAlign.center,
                    style: pw.TextStyle(font: fontB, fontSize: 9.5, color: textColor),
                  ),
                );
              }).toList(),
            ),
            ...items.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              final productName = item.productNameHindi.isNotEmpty
                  ? '${item.productName} (${item.productNameHindi})'
                  : item.productName;

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    child: pw.Text(
                      '$index',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: font, fontSize: 9.5),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    child: pw.Text(
                      productName,
                      style: pw.TextStyle(font: font, fontSize: 9.5),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    child: pw.Text(
                      item.unit,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: font, fontSize: 9.5),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    child: pw.Text(
                      item.quantity.toStringAsFixed(0),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: font, fontSize: 9.5),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    child: pw.Text(
                      item.appliedRate.toStringAsFixed(2),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: font, fontSize: 9.5),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    child: pw.Text(
                      item.amount.toStringAsFixed(2),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: font, fontSize: 9.5),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 18),

        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 240,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                amountRow('Subtotal', subtotal),
                if (previousDue > 0) amountRow('Previous Due', previousDue),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: lineColor, width: 0.7),
                      bottom: pw.BorderSide(color: lineColor, width: 0.7),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Grand Total',
                        style: pw.TextStyle(font: fontB, fontSize: 12, color: textColor),
                      ),
                      pw.Text(
                        money(grandTotal),
                        style: pw.TextStyle(font: fontB, fontSize: 12, color: textColor),
                      ),
                    ],
                  ),
                ),
                amountRow('Paid', paidNow),
                amountRow('Remaining Due', newDue),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 20),
        thinLine(thickness: 0.7),
        pw.SizedBox(height: 10),

        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Thank You!  Visit Again',
                style: pw.TextStyle(font: font, fontSize: 10, color: muted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'RATHOD ENTERPRISES',
                style: pw.TextStyle(
                  font: fontB,
                  fontSize: 11.5,
                  color: red,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.grey500,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '$copyLabel – $copySuffix',
                style: pw.TextStyle(font: font, fontSize: 9.5, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      build: (_) => buildCopy(isCustomerCopy: true),
    ),
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      build: (_) => buildCopy(isCustomerCopy: false),
    ),
  );

  return doc.save();
}