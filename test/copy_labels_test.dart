import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/models/business_settings.dart';
import 'package:greengrocer/widgets/bill_item_row.dart';
import 'package:greengrocer/widgets/bill_pdf.dart';

int indexOfBytes(List<int> data, List<int> pattern, int from) {
  outer:
  for (var i = from; i <= data.length - pattern.length; i++) {
    for (var j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// Content streams are Flate-compressed, so the drawing operators have to be
/// inflated before the printed text and the stamp position can be read.
///
/// The `stream` keyword must be followed by an end-of-line, and so must
/// `endstream`; without that check the scan happily matches the word inside
/// binary image data and loses track of the real page streams.
List<String> contentStreams(Uint8List pdf) {
  final out = <String>[];
  var index = 0;
  while (index < pdf.length) {
    final at = indexOfBytes(pdf, 'stream'.codeUnits, index);
    if (at < 0) break;

    var start = at + 6;
    if (start < pdf.length && pdf[start] == 0x0D) start++;
    if (start < pdf.length && pdf[start] == 0x0A) start++;
    final keywordOk = start > at + 6;
    if (!keywordOk) {
      index = at + 6;
      continue;
    }

    final end = indexOfBytes(pdf, 'endstream'.codeUnits, start);
    if (end < 0) break;
    // Only accept a terminator that starts its own line.
    final precededByEol = end > 0 && (pdf[end - 1] == 0x0A || pdf[end - 1] == 0x0D);

    try {
      out.add(String.fromCharCodes(
        ZLibCodec().decoder.convert(pdf.sublist(start, end)),
      ));
    } catch (_) {
      // Not a zlib stream (e.g. the embedded jpeg); ignore it.
    }
    index = precededByEol ? end + 9 : end + 1;
  }
  return out;
}

String drawnText(String content) {
  final buffer = StringBuffer();
  for (final m in RegExp(r'\(((?:\\.|[^()\\])*)\)').allMatches(content)) {
    buffer.write(m.group(1));
  }
  return buffer.toString();
}

Future<Uint8List> buildSampleBill() {
  return buildBillPdf(
    settings: const BusinessSettings(id: 's1', businessName: 'RATHOD ENTERPRISES'),
    billNumber: 'B-1',
    customerName: 'Test Customer',
    customerMobile: '9999999999',
    customerAddress: 'Nagpur',
    subtotal: 60,
    total: 60,
    deliveryCharge: 0,
    paidNow: 0,
    items: [
      for (var i = 0; i < 6; i++)
        LineItem(
          productName: 'Product $i',
          productNameHindi: '',
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

  test('the customer copy is labelled ORIGINAL and the office one DUPLICATE',
      () async {
    final pdf = await buildSampleBill();
    final pages = contentStreams(pdf).where((s) => s.contains(' Do')).toList();
    expect(pages.length, 2, reason: 'one content stream per copy page');

    // Each word is positioned separately, so the drawn text has no spaces.
    final first = drawnText(pages[0]);
    final second = drawnText(pages[1]);

    expect(first.contains('ORIGINAL'), isTrue);
    expect(first.contains('CustomerCopy'), isTrue);
    expect(second.contains('DUPLICATE'), isTrue);
    expect(second.contains('OfficeCopy'), isTrue);
    expect(second.contains('ORIGINAL'), isFalse,
        reason: 'the office copy is the duplicate, not a second original');
  });

  test('the stamp is placed beside the totals, not at the left page margin',
      () async {
    final pdf = await buildSampleBill();
    final pages = contentStreams(pdf).where((s) => s.contains(' Do')).toList();
    expect(pages.length, 2);

    for (final page in pages) {
      final draw = RegExp(r'/I\d+ Do').firstMatch(page)!.start;
      expect(draw, greaterThan(0), reason: 'a stamp must be drawn on the page');

      // The page content is placed with `1 0 0 1 20 y cm`; the stamp is then
      // offset inside the content. Take the last non-zero horizontal offset
      // before the draw: that is the stamp's distance from the content origin.
      final offsets = RegExp(r'1 0 0 1 ([\d.]+) [\d.\-]+ cm')
          .allMatches(page.substring(0, draw))
          .map((m) => double.parse(m.group(1)!))
          .where((x) => x > 0)
          .toList();
      expect(offsets, isNotEmpty);
      final offset = offsets.last;

      expect(offset, greaterThan(100),
          reason: 'the stamp must not sit at the far left page margin');
    }
  });
}
