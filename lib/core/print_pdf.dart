import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import 'print_pdf_stub.dart'
    if (dart.library.js) 'print_pdf_web.dart' as web;

Future<void> printPdf(Uint8List pdfBytes, {String? filename}) async {
  if (kIsWeb) {
    return web.webPrintPdf(pdfBytes, filename: filename ?? 'document');
  }
  await Printing.layoutPdf(onLayout: (_) => pdfBytes);
}
