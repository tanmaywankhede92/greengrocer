import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;

const kStampAssetPath = 'assets/rathod_enterprises_stamp.jpg';

const kStampWidthPdf = 170.0;
const kStampWidthPreview = 214.0;

/// Width used when the stamp sits to the left of the totals block.
const kStampWidthBesideTotals = 150.0;

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

/// Warms the asset cache so a following `RepaintBoundary.toImage()` always
/// captures the stamp. Without this the snapshot can be taken while the JPEG
/// is still decoding, which silently prints the copies without the stamp.
Future<void> precacheStamp(BuildContext context) async {
  try {
    await precacheImage(const AssetImage(kStampAssetPath), context);
  } catch (_) {
    // Leave the errorBuilder fallback in place if the asset cannot be loaded.
  }
}

/// Lays the stamp out immediately to the left of the totals block so it lines
/// up with the Grand Total row. Falls back to the plain totals when the asset
/// could not be loaded.
pw.Widget buildStampBesideTotals(
  Uint8List? bytes,
  pw.Widget totals, {
  double width = kStampWidthBesideTotals,
  double gap = 18,
}) {
  final stamp = bytes == null
      ? pw.SizedBox()
      : pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            buildStampPdf(bytes, width: width),
            pw.SizedBox(width: gap),
          ],
        );

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      stamp,
      pw.Expanded(
        child: pw.Align(alignment: pw.Alignment.centerRight, child: totals),
      ),
    ],
  );
}

/// Flutter counterpart of [buildStampBesideTotals] used by the on-screen
/// preview and reprint copies.
Widget buildStampBesideTotalsPreview(
  Widget totals, {
  double width = kStampWidthBesideTotals,
  double gap = 18,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(width: width, child: buildStampPreview(width: width)),
      SizedBox(width: gap),
      Expanded(
        child: Align(alignment: Alignment.centerRight, child: totals),
      ),
    ],
  );
}
