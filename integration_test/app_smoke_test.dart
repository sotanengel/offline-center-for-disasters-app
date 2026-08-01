import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('アプリがシミュレータで起動しホームが表示される', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('オフライン災害対応センター'), findsOneWidget);
  });
}
