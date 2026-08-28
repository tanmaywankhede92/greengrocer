import 'dart:typed_data';

import 'download_bytes_stub.dart'
    if (dart.library.js) 'download_bytes_web.dart' as web;

/// Downloads [bytes] as a file. On web it creates a blob URL and clicks a
/// hidden anchor; on other platforms it is a no-op so the shared dialog code
/// stays compilable everywhere.
void downloadBytes(Uint8List bytes, String filename) {
  web.downloadBytes(bytes, filename);
}