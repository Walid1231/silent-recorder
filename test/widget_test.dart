import 'package:flutter_test/flutter_test.dart';
import 'package:silent_recorder/main.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SilentRecorderApp());
    expect(find.text('Silent Recorder'), findsOneWidget);
  });
}
