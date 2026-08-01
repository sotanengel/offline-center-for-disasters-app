import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/rule/keyword_dictionary.dart';
import 'package:offline_center_for_disasters/data/rule/rule_situation_analyzer.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/domain/services/situation_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RuleSituationAnalyzer analyzer;

  setUpAll(() async {
    final dict = await KeywordDictionary.load();
    analyzer = RuleSituationAnalyzer(dict);
  });

  test('空入力は Err(empty)', () async {
    final r = await analyzer.analyze('   ');
    expect(r, isA<Err<SituationSlots, SituationAnalyzerError>>());
    expect((r as Err).error, SituationAnalyzerError.empty);
  });

  test('津波同義語を disasterTypeEvidence に保持', () async {
    final r = await analyzer.analyze('つなみが来る 避難したい');
    final slots = (r as Ok).value;
    expect(slots.disasterType, DisasterType.tsunami);
    expect(slots.disasterTypeEvidence, 'つなみ');
    expect(slots.source, SlotSource.rule);
    expect(slots.intent, Intent.route);
  });

  test('車椅子キーワードで mobility=wheelchair', () async {
    final r = await analyzer.analyze('車椅子で避難');
    final slots = (r as Ok).value;
    expect(slots.userState.mobility, Mobility.wheelchair);
  });
}
