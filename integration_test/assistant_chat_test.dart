import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/main.dart' as app;

Future<void> pumpAppUntilHomeReady(WidgetTester tester) async {
  app.main();
  await tester.pump();
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
    final homeReady =
        find.byKey(const Key('tile_tsunami')).evaluate().isNotEmpty &&
        find.text('どの災害から逃げますか？').evaluate().isNotEmpty;
    if (homeReady) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('フッターからアシスタントタブと資料閲覧に遷移できる', (tester) async {
    await pumpAppUntilHomeReady(tester);

    expect(find.text('ホーム'), findsOneWidget);

    await tester.tap(find.text('災害対応アシスタント').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assistant_input')), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_knowledge_browser')));
    await tester.pumpAndSettle();

    expect(find.text('資料一覧'), findsOneWidget);
    expect(find.text('応急手当・救命'), findsOneWidget);
  });
}
