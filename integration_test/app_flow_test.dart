import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/main.dart' as app;

/// FutureProvider 解決までポンプする（シミュレータ実機用）。
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

/// S-02: 避難先サマリ表示まで待つ（468MB パック読み込みを含む）。
Future<void> pumpUntilDestinationSummary(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(const Key('destination_summary')).evaluate().isNotEmpty) {
      break;
    }
    if (find.text('データパック未配置').evaluate().isNotEmpty) {
      break;
    }
    if (find.textContaining('避難先の取得に失敗').evaluate().isNotEmpty) {
      break;
    }
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S-01 ホームが表示される', (tester) async {
    await pumpAppUntilHomeReady(tester);
    expect(find.text('どの災害から逃げますか？'), findsOneWidget);
    expect(find.byKey(const Key('tile_tsunami')), findsOneWidget);
    expect(find.text('わからない・とにかく逃げたい'), findsNothing);
  });

  testWidgets('津波タイル 1 タップ → S-02 → S-03（§20.5）', (tester) async {
    await pumpAppUntilHomeReady(tester);

    await tester.tap(find.byKey(const Key('tile_tsunami')));
    await pumpUntilDestinationSummary(tester);

    expect(find.byKey(const Key('destination_summary')), findsOneWidget);
    expect(find.text('案内を開始する'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start_nav_button')));
    await tester.pumpAndSettle();

    expect(find.text('経路案内'), findsOneWidget);
    expect(find.textContaining('残り'), findsOneWidget);
  });
}
