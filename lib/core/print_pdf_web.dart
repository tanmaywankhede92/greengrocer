import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'pdf_viewer_overlay.dart';

Future<void> webPrintPdf(Uint8List pdfBytes, {required String filename}) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final pdfUrl = html.Url.createObjectUrlFromBlob(blob);

  await showPdfViewer(pdfUrl, filename);

  html.Url.revokeObjectUrl(pdfUrl);
}
