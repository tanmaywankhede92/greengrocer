import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

Future<void> showPdfViewer(String blobUrl, String filename) async {
  final completer = Completer<void>();
  StreamSubscription? keySub;

  html.document.getElementById('pdf-viewer-overlay')?.remove();

  final overlay = html.DivElement()
    ..id = 'pdf-viewer-overlay'
    ..style.cssText =
        'position:fixed;top:0;left:0;width:100vw;height:100vh;z-index:99999;'
        'display:flex;flex-direction:column;background:#fff;';

  final toolbar = html.DivElement()
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

  void close() {
    keySub?.cancel();
    overlay.remove();
    if (!completer.isCompleted) completer.complete();
  }

  printBtn.onClick.listen((_) {
    try {
      final iframeJs = js.context['document'].callMethod('getElementById', ['pdf-viewer-iframe']);
      final cw = iframeJs?.callMethod('contentWindow');
      cw?.callMethod('print');
    } catch (_) {
      html.window.print();
    }
  });

  closeBtn.onClick.listen((_) => close());

  keySub = html.document.onKeyDown.listen((event) {
    if (event.key == 'Escape' && !completer.isCompleted) close();
  });

  return completer.future;
}
