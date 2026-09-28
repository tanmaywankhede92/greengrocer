import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

/// Height/width ratio of an A4 sheet.
const double _a4HeightRatio = 297 / 210;

/// Splits a captured copy into A4-proportioned sheets. A bill taller than one
/// sheet is printed across several pages instead of being shrunk to fit a
/// single page, matching how the generated PDF paginates.
List<Uint8List> sliceCapturedToA4Sheets(Uint8List png) {
  final decoded = img.decodePng(png);
  if (decoded == null) return [png];

  final sliceHeight = (decoded.width * _a4HeightRatio).round();
  if (decoded.height <= sliceHeight) return [png];

  final sheets = <Uint8List>[];
  for (var top = 0; top < decoded.height; top += sliceHeight) {
    final height = math.min(sliceHeight, decoded.height - top);
    final slice = img.copyCrop(
      decoded,
      x: 0,
      y: top,
      width: decoded.width,
      height: height,
    );
    sheets.add(img.encodePng(slice));
  }
  return sheets;
}

Future<void> printPdf(Uint8List pdfBytes, {String? filename}) async {
  await Printing.layoutPdf(
    onLayout: (_) => pdfBytes,
    name: filename ?? 'document',
  );
}

/// Prints the bill PDF directly and instantly via the platform's native print engine.
Future<void> printBillWidgets({
  List<GlobalKey>? boundaryKeys,
  required Future<Uint8List> Function() buildPdf,
  void Function(String message)? onStage,
  String? filename,
}) async {
  final pdf = await buildPdf();
  await Printing.layoutPdf(
    onLayout: (_) => pdf,
    name: filename ?? 'document',
  );
}
