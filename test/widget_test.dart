import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengrocer/app.dart';

void main() {
  testWidgets('App loads without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GreengrocerApp()));
    expect(find.byType(GreengrocerApp), findsOneWidget);
  });
}
