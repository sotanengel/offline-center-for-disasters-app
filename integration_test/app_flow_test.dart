import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S-01 ホームが表示される', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('どの災害から逃げますか？'), findsOneWidget);
    expect(find.text('津波'), findsWidgets);
    expect(find.text('わからない・とにかく逃げたい'), findsOneWidget);
  });

  testWidgets('津波タイル 1 タップ → S-02 → S-03（§20.5）', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tile_tsunami')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('destination_summary')), findsOneWidget);
    expect(find.text('案内を開始する'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start_nav_button')));
    await tester.pumpAndSettle();

    expect(find.text('経路案内'), findsOneWidget);
    expect(find.textContaining('残り'), findsOneWidget);
  });
}
