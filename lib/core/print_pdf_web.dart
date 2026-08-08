import 'dart:typed_data';

import 'pdf_viewer_overlay.dart';

Future<void> webPrintPdf(Uint8List pdfBytes, {required String filename}) async {
  await showPdfViewer(pdfBytes, filename);
}

Future<void> webPrintImages(List<Uint8List> pngBytes, {required String filename}) async {
  await showImagePrintView(pngBytes, filename);
}
