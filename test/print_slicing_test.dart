import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/core/print_pdf.dart';
import 'package:image/image.dart' as img;

Uint8List _pngOfHeight(int width, int height) {
  final canvas = img.Image(width: width, height: height);
  // A distinct colour band every 100px lets the test prove nothing was lost.
  for (var y = 0; y < height; y++) {
    final band = (y ~/ 100) % 2 == 0 ? 255 : 0;
    for (var x = 0; x < width; x++) {
      canvas.setPixelRgb(x, y, band, band, band);
    }
  }
  return Uint8List.fromList(img.encodePng(canvas));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a copy that already fits one sheet is left alone', () async {
    final png = _pngOfHeight(600, 700);
    final sheets = await sliceCapturedToA4Sheets(png);
    expect(sheets.length, 1);
  });

  test('a copy taller than A4 is split into several sheets', () async {
    // 600 wide -> an A4 sheet is round(600 * 297/210) = 849 tall.
    const sheetHeight = 849;
    final png = _pngOfHeight(600, 2000);
    final sheets = await sliceCapturedToA4Sheets(png);
    expect(sheets.length, 3, reason: '2000 / 849 needs three sheets');
    for (final sheet in sheets) {
      final decoded = img.decodePng(sheet)!;
      expect(decoded.width, 600);
    }
  });

  test('the slices keep every band of the original copy', () async {
    final png = _pngOfHeight(600, 2000);
    final sheets = await sliceCapturedToA4Sheets(png);

    // Concatenating the slices must reproduce the full original height, so no
    // content is silently dropped when the bill is cut into pages.
    var totalHeight = 0;
    for (final sheet in sheets) {
      totalHeight += img.decodePng(sheet)!.height;
    }
    expect(totalHeight, 2000);

    final first = img.decodePng(sheets.first)!;
    expect(first.getPixel(0, 0).r, 255, reason: 'starts at the top of the copy');
    final last = img.decodePng(sheets.last)!;
    expect(last.height, 2000 - 2 * 849, reason: 'last sheet holds the remainder');
  });
}
