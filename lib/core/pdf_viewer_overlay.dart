import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

/// Shows a full-screen overlay with the given PNG pages and prints them.
/// iOS Safari cannot print PDF-in-iframe content (blank/black output), but it
/// prints plain <img> elements reliably — this is the iOS-safe print path.
Future<void> showImagePrintView(List<Uint8List> pngBytes, String filename) async {
  final completer = Completer<void>();
  StreamSubscription? keySub;
  html.StyleElement? printStyle;

  html.document.getElementById('pdf-viewer-overlay')?.remove();

  final urls = <String>[];

  final overlay = html.DivElement()
    ..id = 'pdf-viewer-overlay'
    ..style.cssText =
        'position:fixed;top:0;left:0;width:100vw;height:100vh;z-index:99999;'
        'display:flex;flex-direction:column;background:#fff;';

  final toolbar = html.DivElement()
    ..id = 'pdf-viewer-toolbar'
    ..style.cssText =
        'display:flex;align-items:center;padding:6px 12px;'
        'background:#1565C0;color:#fff;box-shadow:0 2px 8px rgba(0,0,0,.25);'
        'gap:6px;flex-shrink:0;';

  final title = html.SpanElement()
    ..text = filename
    ..style.cssText =
        'flex:1;font-size:13px;font-weight:600;white-space:nowrap;'
        'overflow:hidden;text-overflow:ellipsis;margin-left:4px;';

  final printBtn = html.ButtonElement()
    ..text = 'Print'
    ..style.cssText =
        'padding:6px 14px;border:none;border-radius:4px;background:#fff;'
        'color:#1565C0;font-weight:600;cursor:pointer;font-size:13px;';

  final closeBtn = html.ButtonElement()
    ..text = 'Close'
    ..style.cssText =
        'padding:6px 14px;border:none;border-radius:4px;background:#D32F2F;'
        'color:#fff;font-weight:600;cursor:pointer;font-size:13px;';

  toolbar.children.addAll([title, printBtn, closeBtn]);

  final pages = html.DivElement()
    ..id = 'pdf-image-pages'
    ..style.cssText =
        'flex:1;overflow:auto;background:#f0f0f0;padding:12px;';

  for (final bytes in pngBytes) {
    final sliced = await _sliceToPages(bytes);
    for (final page in sliced) {
      final url = html.Url.createObjectUrlFromBlob(
        html.Blob([page], 'image/png'),
      );
      urls.add(url);
      final img = html.ImageElement()
        ..src = url
        ..style.cssText =
            'display:block;width:100%;max-width:800px;margin:0 auto 16px;'
            'background:#fff;box-shadow:0 2px 8px rgba(0,0,0,.25);';
      pages.append(img);
    }
  }

  overlay.children.addAll([toolbar, pages]);
  html.document.body!.append(overlay);

  void removePrintStyle() {
    if (printStyle != null) {
      printStyle!.remove();
      printStyle = null;
    }
  }

  void close() {
    keySub?.cancel();
    removePrintStyle();
    for (final u in urls) {
      html.Url.revokeObjectUrl(u);
    }
    overlay.remove();
    if (!completer.isCompleted) completer.complete();
  }

  printBtn.onClick.listen((_) {
    removePrintStyle();
    printStyle = html.StyleElement()
      ..id = 'pdf-print-style'
      ..innerHtml = '''
        @media print {
          body > *:not(#pdf-viewer-overlay) { display: none !important; }
          #pdf-viewer-toolbar { display: none !important; }
          #pdf-viewer-overlay {
            position: static !important;
            width: 100% !important;
            height: auto !important;
            z-index: auto !important;
            background: white !important;
            box-shadow: none !important;
          }
          #pdf-image-pages {
            padding: 0 !important;
            background: white !important;
          }
          #pdf-image-pages img {
            display: block !important;
            width: 100% !important;
            max-width: none !important;
            margin: 0 !important;
            box-shadow: none !important;
            page-break-after: always;
            break-after: page;
          }
          #pdf-image-pages img:last-child {
            page-break-after: auto;
            break-after: auto;
          }
        }
      ''';
    html.document.head!.append(printStyle!);

    html.window.print();

    Future.delayed(const Duration(seconds: 3), removePrintStyle);
  });

  closeBtn.onClick.listen((_) => close());

  keySub = html.document.onKeyDown.listen((event) {
    if (event.key == 'Escape' && !completer.isCompleted) close();
  });

  return completer.future;
}

/// A4 aspect ratio (height / width). Used to slice a tall captured bill image
/// into page-sized bands so printing produces the correct number of pages.
const double _a4Aspect = 1.4142;

/// Slices a tall PNG into A4-page-height bands. If the image is no taller than
/// one A4 page it is returned unchanged (single page). Returns PNG bytes, one
/// per printed page.
Future<List<Uint8List>> _sliceToPages(Uint8List pngBytes) async {
  final blobUrl = html.Url.createObjectUrlFromBlob(html.Blob([pngBytes], 'image/png'));
  final img = html.ImageElement()..src = blobUrl;
  try {
    await img.onLoad.first;
  } catch (_) {
    html.Url.revokeObjectUrl(blobUrl);
    return [pngBytes];
  }

  final w = img.naturalWidth;
  final h = img.naturalHeight;
  html.Url.revokeObjectUrl(blobUrl);
  if (w <= 0 || h <= 0) return [pngBytes];

  final pageHeight = (w * _a4Aspect).round();
  if (h <= pageHeight) return [pngBytes];

  final pages = <Uint8List>[];
  for (var y = 0; y < h; y += pageHeight) {
    final sliceH = math.min(pageHeight, h - y);
    final canvas = html.CanvasElement(width: w, height: sliceH);
    final ctx = canvas.context2D;
    ctx.setTransform(1, 0, 0, 1, 0, -y);
    ctx.drawImage(img, 0, 0);
    pages.add(_canvasToPngBytes(canvas));
  }
  return pages;
}

Uint8List _canvasToPngBytes(html.CanvasElement canvas) {
  final dataUrl = canvas.toDataUrl('image/png');
  final comma = dataUrl.indexOf(',');
  if (comma < 0) return Uint8List(0);
  final base64 = dataUrl.substring(comma + 1);
  final decoded = html.window.atob(base64);
  final bytes = Uint8List(decoded.length);
  for (var i = 0; i < decoded.length; i++) {
    bytes[i] = decoded.codeUnitAt(i);
  }
  return bytes;
}

Future<void> showPdfViewer(Uint8List pdfBytes, String filename) async {
  final completer = Completer<void>();
  StreamSubscription? keySub;
  html.StyleElement? printStyle;

  html.document.getElementById('pdf-viewer-overlay')?.remove();

  final blobUrl = html.Url.createObjectUrlFromBlob(
    html.Blob([pdfBytes], 'application/pdf'),
  );

  final overlay = html.DivElement()
    ..id = 'pdf-viewer-overlay'
    ..style.cssText =
        'position:fixed;top:0;left:0;width:100vw;height:100vh;z-index:99999;'
        'display:flex;flex-direction:column;background:#fff;';

  final toolbar = html.DivElement()
    ..id = 'pdf-viewer-toolbar'
    ..style.cssText =
        'display:flex;align-items:center;padding:6px 12px;'
        'background:#1565C0;color:#fff;box-shadow:0 2px 8px rgba(0,0,0,.25);'
        'gap:6px;flex-shrink:0;';

  final title = html.SpanElement()
    ..text = filename
    ..style.cssText =
        'flex:1;font-size:13px;font-weight:600;white-space:nowrap;'
        'overflow:hidden;text-overflow:ellipsis;margin-left:4px;';

  final printBtn = html.ButtonElement()
    ..text = 'Print'
    ..style.cssText =
        'padding:6px 14px;border:none;border-radius:4px;background:#fff;'
        'color:#1565C0;font-weight:600;cursor:pointer;font-size:13px;';

  final closeBtn = html.ButtonElement()
    ..text = 'Close'
    ..style.cssText =
        'padding:6px 14px;border:none;border-radius:4px;background:#D32F2F;'
        'color:#fff;font-weight:600;cursor:pointer;font-size:13px;';

  toolbar.children.addAll([title, printBtn, closeBtn]);

  final loading = html.DivElement()
    ..text = 'Loading PDF...'
    ..style.cssText =
        'display:flex;align-items:center;justify-content:center;'
        'flex:1;font-size:16px;color:#888;';

  final iframe = html.IFrameElement()
    ..id = 'pdf-viewer-iframe'
    ..src = blobUrl
    ..style.cssText =
        'border:none;width:100%;flex:1;display:none;';

  iframe.onLoad.listen((_) {
    loading.style.display = 'none';
    iframe.style.display = 'block';
  });

  overlay.children.addAll([toolbar, loading, iframe]);
  html.document.body!.append(overlay);

  void removePrintStyle() {
    if (printStyle != null) {
      printStyle!.remove();
      printStyle = null;
    }
  }

  void close() {
    keySub?.cancel();
    removePrintStyle();
    html.Url.revokeObjectUrl(blobUrl);
    overlay.remove();
    if (!completer.isCompleted) completer.complete();
  }

  printBtn.onClick.listen((_) {
    removePrintStyle();
    printStyle = html.StyleElement()
      ..id = 'pdf-print-style'
      ..innerHtml = '''
        @media print {
          body > *:not(#pdf-viewer-overlay) { display: none !important; }
          #pdf-viewer-toolbar { display: none !important; }
          #pdf-viewer-overlay {
            position: static !important;
            width: 100% !important;
            height: auto !important;
            z-index: auto !important;
            background: white !important;
            box-shadow: none !important;
          }
          #pdf-viewer-iframe {
            width: 100% !important;
            height: 100vh !important;
            border: none !important;
            display: block !important;
          }
        }
      ''';
    html.document.head!.append(printStyle!);

    html.window.print();

    Future.delayed(const Duration(seconds: 3), removePrintStyle);
  });

  closeBtn.onClick.listen((_) => close());

  keySub = html.document.onKeyDown.listen((event) {
    if (event.key == 'Escape' && !completer.isCompleted) close();
  });

  return completer.future;
}
