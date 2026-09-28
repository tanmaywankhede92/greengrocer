import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;

const kStampAssetPath = 'assets/rathod_enterprises_stamp.jpg';

const kStampWidthPdf = 170.0;
const kStampWidthPreview = 214.0;

Future<Uint8List?> loadStampBytes() async {
  try {
    final data = await rootBundle.load(kStampAssetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {
    return null;
  }
}

pw.Widget buildStampPdf(Uint8List? bytes, {double width = kStampWidthPdf}) {
  if (bytes == null) {
    return pw.SizedBox();
  }
  return pw.Align(
    alignment: pw.Alignment.centerLeft,
    child: pw.Image(pw.MemoryImage(bytes), width: width),
  );
}

Widget buildStampPreview({double width = kStampWidthPreview}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Image.asset(
      kStampAssetPath,
      width: width,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  );
}
