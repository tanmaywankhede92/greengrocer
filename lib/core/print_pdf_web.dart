import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

bool get _isIOS {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
}

Future<void> webPrintPdf(Uint8List pdfBytes, {required String filename}) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final pdfUrl = html.Url.createObjectUrlFromBlob(blob);

  if (_isIOS) {
    html.window.location.href = pdfUrl;
  } else {
    final anchor = html.AnchorElement(href: pdfUrl)
      ..target = '_blank'
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
  }

  Timer(const Duration(seconds: 60), () {
    html.Url.revokeObjectUrl(pdfUrl);
  });
}
