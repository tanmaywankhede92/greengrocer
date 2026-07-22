import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

html.WindowBase? _pendingTab;

void openPrintWindow() {
  _pendingTab = html.window.open('about:blank', '_blank');
}

Future<void> webPrintPdf(Uint8List pdfBytes, {required String filename}) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final pdfUrl = html.Url.createObjectUrlFromBlob(blob);

  if (_pendingTab != null) {
    try {
      _pendingTab!.location.href = pdfUrl;
    } catch (_) {
      html.window.open(pdfUrl, '_blank');
    }
    _pendingTab = null;
  } else {
    html.window.open(pdfUrl, '_blank');
  }

  Timer(const Duration(seconds: 60), () {
    html.Url.revokeObjectUrl(pdfUrl);
  });
}
