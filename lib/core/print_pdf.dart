import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';

import 'print_pdf_stub.dart'
    if (dart.library.js) 'print_pdf_web.dart' as web;

Future<void> printPdf(Uint8List pdfBytes, {String? filename}) async {
  if (kIsWeb) {
    return web.webPrintPdf(pdfBytes, filename: filename ?? 'document');
  }
  await Printing.layoutPdf(onLayout: (_) => pdfBytes);
}

/// Prints bill pages by capturing the given [RepaintBoundary] widgets to PNG
/// images. On web this is the reliable path (iOS Safari cannot print PDFs
/// inside iframes), printing plain <img> elements instead. On native platforms
/// it falls back to [pdfBytes] via the `printing` package.
///
/// If no boundary can be captured on web (e.g. not yet laid out), [pdfBytes]
/// is used as a fallback through the PDF viewer.
Future<void> printBillWidgets({
  required List<GlobalKey> boundaryKeys,
  Uint8List? pdfBytes,
  String? filename,
}) async {
  if (kIsWeb) {
    final images = <Uint8List>[];
    for (final key in boundaryKeys) {
      final captured = await _captureBoundary(key);
      if (captured != null) images.add(captured);
    }
    if (images.isNotEmpty) {
      return web.webPrintImages(images, filename: filename ?? 'document');
    }
    if (pdfBytes != null) {
      return web.webPrintPdf(pdfBytes, filename: filename ?? 'document');
    }
    return;
  }

  if (pdfBytes != null) {
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }
}

Future<Uint8List?> _captureBoundary(GlobalKey key) async {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  // Ensure the boundary is visible/painted so toImage() returns content
  // instead of a blank/empty layer (e.g. when scrolled below the fold).
  try {
    await Scrollable.ensureVisible(ctx);
    await WidgetsBinding.instance.endOfFrame;
  } catch (_) {
    // not inside a scrollable; painting already assumed
  }
  if (!ctx.mounted) return null;
  final renderObject = ctx.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) return null;
  try {
    final image = await renderObject.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
