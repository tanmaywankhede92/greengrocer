import 'dart:typed_data';

Future<void> webPrintPdf(Uint8List pdfBytes, {required String filename}) async {
  throw UnsupportedError('Web print not available on this platform');
}

Future<void> webPrintImages(List<Uint8List> pngBytes, {required String filename}) async {
  throw UnsupportedError('Web print not available on this platform');
}
