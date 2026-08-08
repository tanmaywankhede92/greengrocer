import 'dart:html' as html;
import 'dart:typed_data';

Future<void> webSharePdf(Uint8List pdfBytes, {required String filename, required String message}) async {
  final nav = html.window.navigator;
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final file = html.File([blob], '$filename.pdf', {'type': 'application/pdf'});
  final data = {'title': filename, 'text': message, 'files': [file]};

  try {
    await nav.share(data);
    return;
  } catch (_) {
    // File sharing unsupported or cancelled — fall through.
  }

  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = '$filename.pdf';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  final waUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
  html.window.open(waUrl, '_blank');
}
