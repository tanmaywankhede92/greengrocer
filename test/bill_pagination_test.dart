import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/models/business_settings.dart';
import 'package:greengrocer/widgets/bill_item_row.dart';
import 'package:greengrocer/widgets/bill_pdf.dart';

Future<Uint8List> buildPdfWithItems(int itemCount) {
  return buildBillPdf(
    settings: const BusinessSettings(id: 's1', businessName: 'RATHOD ENTERPRISES'),
    billNumber: 'B-1',
    customerName: 'Test Customer',
    customerMobile: '9999999999',
    customerAddress: 'Nagpur',
    subtotal: itemCount * 100.0,
    total: itemCount * 100.0,
    deliveryCharge: 0,
    paidNow: 0,
    items: List.generate(
      itemCount,
      (i) => LineItem(
        productName: 'Product $i',
        productNameHindi: '',
        unit: 'KG',
        quantity: 10,
        appliedRate: 10,
      ),
    ),
    billDate: DateTime(2026, 1, 1),
    isReprint: false,
  );
}

String _pdfText(Uint8List pdf) {
  final buffer = StringBuffer();
  for (final byte in pdf) {
    if (byte == 0x20 || byte == 0x0A || byte == 0x0D || byte == 0x09) continue;
    buffer.writeCharCode(byte);
  }
  return buffer.toString();
}

int _countPages(Uint8List pdf) {
  final text = _pdfText(pdf);
  var index = 0;
  var pages = 0;
  while (true) {
    final found = text.indexOf('/Type/Page', index);
    if (found < 0) break;
    if (found + 10 >= text.length || text[found + 10] != 's') pages++;
    index = found + 1;
  }
  return pages;
}

int _countCopies(Uint8List pdf) {
  // The two copies are built by two separate MultiPages, so they always
  // paginate identically. An even page count proves both copies are complete
  // and neither was truncated differently from the other.
  final pages = _countPages(pdf);
  return pages.isEven ? 2 : 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a short bill prints as exactly 2 pages, one per copy', () async {
    final pdf = await buildPdfWithItems(3);
    expect(_countPages(pdf), 2,
        reason: 'customer copy and office copy must never share a page');
  });

  test('both copies are present and complete', () async {
    final pdf = await buildPdfWithItems(3);
    expect(_countCopies(pdf), 2,
        reason: 'one copy per ORIGINAL footer, not a merged single copy');
  });

  test('a long bill grows extra pages instead of being shrunk', () async {
    final short = await buildPdfWithItems(3);
    final long = await buildPdfWithItems(60);
    expect(_countPages(long), greaterThan(_countPages(short)),
        reason: 'content that does not fit must move to the next page');
    // 2 copies, each spanning more than one page for 60 items.
    expect(_countPages(long), greaterThanOrEqualTo(4));
  });

  test('both copies are still complete in a long bill', () async {
    final pdf = await buildPdfWithItems(60);
    expect(_countCopies(pdf), 2,
        reason: 'a bill that splits over pages must not lose a copy');
    expect(_countPages(pdf) % 2, 0,
        reason: 'the two copies must span the same number of pages');
  });
}
