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

pw.Widget buildStampPdf(Uint8List? bytes, {double width = kStampWidthPdf, pw.Alignment alignment = pw.Alignment.center}) {
  if (bytes == null) {
    return pw.SizedBox();
  }
  return pw.Align(
    alignment: alignment,
    child: pw.Image(pw.MemoryImage(bytes), width: width),
  );
}

Widget buildStampPreview({double width = kStampWidthPreview, Alignment alignment = Alignment.center}) {
  return Align(
    alignment: alignment,
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

/// Lays the stamp out immediately to the left of the totals block.
///
/// The pair is right-aligned as one unit, so the stamp sits close to the Grand
/// Total column instead of floating at the far page margin, which reads as
/// balanced on a printed bill. Falls back to the plain totals when the asset
/// could not be loaded.
pw.Widget buildStampBesideTotals(
  Uint8List? bytes,
  pw.Widget totals, {
  double width = kStampWidthBesideTotals,
  double gap = 24,
}) {
  if (bytes == null) {
    return pw.Align(alignment: pw.Alignment.centerRight, child: totals);
  }

  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.SizedBox(width: width, child: buildStampPdf(bytes, width: width, alignment: pw.Alignment.centerLeft)),
      pw.SizedBox(width: gap),
      totals,
    ],
  );
}

/// Flutter counterpart of [buildStampBesideTotals] used by the on-screen
/// preview and reprint copies.
Widget buildStampBesideTotalsPreview(
  Widget totals, {
  double width = kStampWidthBesideTotals,
  double gap = 24,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(width: width, child: buildStampPreview(width: width, alignment: Alignment.centerLeft)),
      SizedBox(width: gap),
      totals,
    ],
  );
}
