import 'package:flutter_test/flutter_test.dart';
import 'package:e_bayyinah/main.dart';

void main() {
  testWidgets('SIMS E-Bayyinah Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const EBayyinahApp());
    expect(find.byType(EBayyinahApp), findsOneWidget);
  });
}
