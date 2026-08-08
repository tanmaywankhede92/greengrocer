import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

/// A4 aspect ratio (height / width). Used to slice a tall captured bill image
/// into page-sized bands so printing produces the correct number of pages.
const double _a4Aspect = 1.4142;

/// Prints the given PNG pages on the web by injecting them into a hidden
/// print-only container and calling [html.window.print] directly — no
/// intermediate preview screen. iOS Safari cannot print PDFs inside iframes,
/// but prints plain <img> elements reliably, so each page is rendered as an
/// image sliced to an exact A4 ratio.
Future<void> showImagePrintView(List<Uint8List> pngBytes, String filename) async {
  html.document.getElementById('pdf-print-root')?.remove();
  html.document.getElementById('pdf-print-style')?.remove();

  final pages = <Uint8List>[];
  for (final bytes in pngBytes) {
    pages.addAll(await _sliceToPages(bytes));
  }
  if (pages.isEmpty) return;

  final urls = <String>[];
  final container = html.DivElement()..id = 'pdf-print-root';
  for (final page in pages) {
    final url = html.Url.createObjectUrlFromBlob(
      html.Blob([page], 'image/png'),
    );
    urls.add(url);
    container.append(html.ImageElement()..src = url);
  }
  html.document.body!.append(container);

  final style = html.StyleElement()
    ..id = 'pdf-print-style'
    ..innerHtml = '''
      #pdf-print-root {
        position: absolute;
        left: -100000px;
        top: 0;
      }
      @media print {
        @page { size: A4; margin: 0; }
        body > *:not(#pdf-print-root) { display: none !important; }
        #pdf-print-root {
          position: static !important;
          left: 0 !important;
          display: block !important;
        }
        #pdf-print-root img {
          display: block !important;
          width: 100% !important;
          max-width: none !important;
          height: auto !important;
          margin: 0 !important;
          page-break-after: always;
          break-after: page;
        }
        #pdf-print-root img:last-child {
          page-break-after: auto;
          break-after: auto;
        }
      }
    ''';
  html.document.head!.append(style);

  // Wait for every page image to be loaded so the print dialog renders the
  // full content (blob URLs decode asynchronously).
  for (final el in container.querySelectorAll('img')) {
    final img = el as html.ImageElement;
    await _waitForImage(img);
  }
  await Future<void>.delayed(const Duration(milliseconds: 100));

  void cleanup() {
    style.remove();
    container.remove();
    for (final u in urls) {
      html.Url.revokeObjectUrl(u);
    }
  }

  html.window.print();
  // Fallback cleanup if afterprint never fires (some browsers / embedded webviews).
  Future<void>.delayed(const Duration(seconds: 60), cleanup);
}

Future<void> _waitForImage(html.ImageElement img) async {
  final completer = Completer<void>();
  img.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  img.onError.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  Timer(const Duration(seconds: 10), () {
    if (!completer.isCompleted) completer.complete();
  });
  await completer.future;
}

/// Slices a tall PNG into A4-page-height bands. Every band is drawn at an
/// exact A4 ratio (width x width*1.4142) so each band maps to exactly one
/// printed page. The number of pages is derived from the captured image
/// aspect, which scales exactly with the capture pixel ratio.
Future<List<Uint8List>> _sliceToPages(Uint8List pngBytes) async {
  final blobUrl = html.Url.createObjectUrlFromBlob(
    html.Blob([pngBytes], 'image/png'),
  );
  final img = html.ImageElement()..src = blobUrl;
  await _waitForImage(img);
  final w = img.naturalWidth;
  final h = img.naturalHeight;
  html.Url.revokeObjectUrl(blobUrl);
  if (w <= 0 || h <= 0) return [pngBytes];

  final pageHeight = (w * _a4Aspect).round();
  final nPages = math.max(1, (h / pageHeight).ceil());
  if (nPages <= 1) return [pngBytes];

  final pages = <Uint8List>[];
  for (var i = 0; i < nPages; i++) {
    final y = i * pageHeight;
    final canvas = html.CanvasElement(width: w, height: pageHeight);
    final ctx = canvas.context2D;
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, w, pageHeight);
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
