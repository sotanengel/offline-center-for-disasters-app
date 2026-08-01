import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/rule/keyword_dictionary.dart';
import 'package:offline_center_for_disasters/data/rule/rule_situation_analyzer.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/domain/services/situation_analyzer.dart';

/// ゴールデンセット 100 件（§20.3）: intent ≥75% / disaster_type ≥80%
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RuleSituationAnalyzer analyzer;
  late List<Map<String, dynamic>> cases;

  setUpAll(() async {
    final dict = await KeywordDictionary.load();
    analyzer = RuleSituationAnalyzer(dict);
    final raw = await File('test/golden_slots/cases.json').readAsString();
    cases = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    expect(cases.length, greaterThanOrEqualTo(100));
  });

  test('ゴールデン100件: intent≥75% disaster_type≥80%', () async {
    var intentOk = 0;
    var typeOk = 0;
    var n = 0;
    for (final c in cases) {
      final input = c['input'] as String;
      final expType = DisasterType.values.byName(c['disasterType'] as String);
      final expIntent = Intent.values.byName(c['intent'] as String);
      final r = await analyzer.analyze(input);
      if (r is! Ok) continue;
      n++;
      final slots = (r as Ok<SituationSlots, SituationAnalyzerError>).value;
      if (expIntent == Intent.unknown || slots.intent == expIntent) {
        intentOk++;
      }
      if (expType == DisasterType.unknown || slots.disasterType == expType) {
        typeOk++;
      }
    }
    final intentRate = intentOk / n;
    final typeRate = typeOk / n;
    expect(
      intentRate,
      greaterThanOrEqualTo(0.75),
      reason: 'intent=$intentRate',
    );
    expect(typeRate, greaterThanOrEqualTo(0.80), reason: 'type=$typeRate');
  });
}
