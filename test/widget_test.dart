import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/app.dart';

void main() {
  testWidgets('App loads without error', (WidgetTester tester) async {
    await tester.pumpWidget(const GreengrocerApp());
    expect(find.byType(GreengrocerApp), findsOneWidget);
  });
}
