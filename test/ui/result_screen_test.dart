import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/data/llm/leap_stub_engine.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/ui/result/result_screen.dart';

import '../helpers/destination_plan_overrides.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpResult(WidgetTester tester, SituationSlots slots) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          llmEngineProvider.overrideWithValue(LeapStubEngine()),
          destinationPlanProviderOverride(shelterName: '千代田区立神田小学校'),
        ],
        child: MaterialApp(home: ResultScreen(slots: slots)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('探索中は LinearProgressIndicator と段階ラベルを表示する', (tester) async {
    const slots = SituationSlots(
      disasterType: DisasterType.earthquake,
      source: SlotSource.tile,
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          llmEngineProvider.overrideWithValue(LeapStubEngine()),
          destinationPlanLoadingOverride(),
        ],
        child: MaterialApp(home: ResultScreen(slots: slots)),
      ),
    );
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('避難所を探索中...'), findsOneWidget);
  });

  testWidgets('パック探索結果の避難所名を表示する', (tester) async {
    const slots = SituationSlots(
      disasterType: DisasterType.earthquake,
      source: SlotSource.tile,
    );
    await pumpResult(tester, slots);
    expect(find.text('千代田区立神田小学校'), findsOneWidget);
    expect(find.textContaining('1.2km'), findsOneWidget);
    expect(find.text('○○小学校'), findsNothing);
  });

  testWidgets('AI 解釈で evidence 空のとき確認バーが強調される', (tester) async {
    const slots = SituationSlots(
      disasterType: DisasterType.tsunami,
      disasterTypeEvidence: '',
      source: SlotSource.ai,
    );
    await pumpResult(tester, slots);
    expect(find.textContaining('災害種別を選ぶとより正確'), findsOneWidget);
  });

  testWidgets('AI evidence ありで解釈メッセージを表示', (tester) async {
    const slots = SituationSlots(
      disasterType: DisasterType.tsunami,
      disasterTypeEvidence: '津波',
      source: SlotSource.ai,
    );
    await pumpResult(tester, slots);
    expect(find.textContaining('と解釈しました'), findsOneWidget);
  });
}
