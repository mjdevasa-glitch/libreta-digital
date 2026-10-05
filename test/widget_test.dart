import 'package:flutter_test/flutter_test.dart';
import 'package:libreta_digital/main.dart';

void main() {
  testWidgets('La libreta se inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const LibretaApp());

    expect(find.text('LIBRETA DIARIA'), findsOneWidget);
    expect(find.text('Ana García'), findsOneWidget);
  });
}