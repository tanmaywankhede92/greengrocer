import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/widgets/bill_stamp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stamp sits to the left of the totals block', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            child: buildStampBesideTotalsPreview(const Text('GRAND TOTAL  470')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'the errorBuilder fallback must not trigger');
    expect(find.byType(Image), findsOneWidget);

    final widget = tester.widget<Image>(find.byType(Image));
    expect((widget.image as AssetImage).assetName, kStampAssetPath);

    // The stamp must sit left of the totals text, not after it.
    final stampX = tester.getTopLeft(find.byType(Image)).dx;
    final totalsX = tester.getTopLeft(find.text('GRAND TOTAL  470')).dx;
    expect(stampX, lessThan(totalsX));
  });

  test('the stamp jpeg decodes into a real bitmap', () async {
    // Presence in the bundle is not enough: if the jpeg could not be decoded
    // the widget renders blank and the stamp silently disappears on the bill.
    final data = await rootBundle.load(kStampAssetPath);
    expect(data.lengthInBytes, greaterThan(0));

    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 952);
    expect(frame.image.height, 339);
  });
}
