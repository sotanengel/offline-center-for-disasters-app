import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('アプリがシミュレータで起動しホーム（S-01）が表示される', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('どの災害から逃げますか？'), findsOneWidget);
    // 災害種別タイル 8 種のうち代表的なものが表示されること
    expect(find.text('津波'), findsWidgets);
    expect(find.text('わからない・とにかく逃げたい'), findsOneWidget);
  });
}
