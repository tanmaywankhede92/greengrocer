import 'dart:typed_data';

void openPrintWindow() {
  // No-op on non-web
}

Future<void> webPrintPdf(Uint8List pdfBytes, {required String filename}) async {
  throw UnsupportedError('Web print not available on this platform');
}
