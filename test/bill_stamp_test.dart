import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/models/business_settings.dart';
import 'package:greengrocer/widgets/bill_item_row.dart';
import 'package:greengrocer/widgets/bill_pdf.dart';
import 'package:greengrocer/widgets/bill_stamp.dart';

Future<Uint8List> buildTestBillPdf() {
  return buildBillPdf(
    settings: const BusinessSettings(id: 's1', businessName: 'RATHOD ENTERPRISES'),
    billNumber: 'B-1',
    customerName: 'Test Customer',
    customerMobile: '9999999999',
    customerAddress: 'Nagpur',
    subtotal: 100,
    total: 100,
    deliveryCharge: 0,
    paidNow: 0,
    items: [
      LineItem(
        productName: 'Tomato',
        productNameHindi: 'टमाटर',
        unit: 'KG',
        quantity: 10,
        appliedRate: 10,
      ),
    ],
    billDate: DateTime(2026, 1, 1),
    isReprint: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stamp asset loads from the bundle', () async {
    final bytes = await loadStampBytes();
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(0));
  });

  test('bill pdf is a valid pdf containing both copies', () async {
    final pdf = await buildTestBillPdf();
    final header = String.fromCharCodes(pdf.take(5));
    expect(header, '%PDF-');
    final count = _countPages(pdf);
    expect(count, 2, reason: 'customer copy and office copy must be one page each');
  });

  test('bill pdf embeds the stamp image as a jpeg', () async {
    final pdf = await buildTestBillPdf();
    expect(_hasJpegMarker(pdf), isTrue,
        reason: 'the stamp jpg must be embedded in the pdf stream');
    expect(_countImages(pdf), greaterThanOrEqualTo(2),
        reason: 'one stamp per copy page');
  });
}

bool _hasJpegMarker(Uint8List pdf) {
  for (var i = 0; i + 2 < pdf.length; i++) {
    if (pdf[i] == 0xFF && pdf[i + 1] == 0xD8 && pdf[i + 2] == 0xFF) {
      return true;
    }
  }
  return false;
}

String _pdfText(Uint8List pdf) {
  final buffer = StringBuffer();
  for (final byte in pdf) {
    if (byte == 0x20 || byte == 0x0A || byte == 0x0D || byte == 0x09) continue;
    buffer.writeCharCode(byte);
  }
  return buffer.toString();
}

int _countImages(Uint8List pdf) {
  final text = _pdfText(pdf);
  var index = 0;
  var count = 0;
  while (true) {
    final found = text.indexOf('/Subtype/Image', index);
    if (found < 0) break;
    count++;
    index = found + 1;
  }
  return count;
}

int _countPages(Uint8List pdf) {
  final text = _pdfText(pdf);
  var index = 0;
  var pages = 0;
  while (true) {
    final found = text.indexOf('/Type/Page', index);
    if (found < 0) break;
    if (found + 10 >= text.length || text[found + 10] != 's') {
      pages++;
    }
    index = found + 1;
  }
  return pages;
}
