import 'dart:html' as html;
import 'dart:typed_data';

void openPrintWindow() {
  // No-op: window opens after PDF is built
}

Future<void> webPrintPdf(Uint8List pdfBytes, {required String filename}) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final pdfUrl = html.Url.createObjectUrlFromBlob(blob);

  final htmlContent = _pdfPrintHtml(pdfUrl, filename);
  final htmlBlob = html.Blob([htmlContent], 'text/html');
  final htmlUrl = html.Url.createObjectUrlFromBlob(htmlBlob);

  html.window.open(htmlUrl, '_blank');

  Future.delayed(const Duration(seconds: 10), () {
    html.Url.revokeObjectUrl(pdfUrl);
    html.Url.revokeObjectUrl(htmlUrl);
  });
}

String _pdfPrintHtml(String pdfUrl, String title) {
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title</title>
  <style>
    body { margin: 0; padding: 0; background: #f5f5f5; overflow: hidden; }
    embed { width: 100%; height: 100vh; display: block; }
  </style>
</head>
<body>
  <embed src="$pdfUrl" type="application/pdf" width="100%" height="100%">
  <script>
    var embed = document.querySelector('embed');
    if (embed) {
      embed.onload = function() { window.print(); };
    }
  </script>
</body>
</html>
''';
}
