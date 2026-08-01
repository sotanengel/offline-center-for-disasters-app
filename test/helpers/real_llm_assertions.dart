import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/llm/leap_llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';

/// LeapLlmEngine 実推論 smoke（プロンプト例と整合）。
Future<void> runLeapLlmEngineSmokeTests(LeapLlmEngine engine) async {
  expect(await engine.isAvailable(), isTrue);

  final tsunami = await engine.extractSlots('津波が来る');
  expect(tsunami, isA<Ok<SituationSlots, LlmError>>());
  final tsunamiSlots = (tsunami as Ok<SituationSlots, LlmError>).value;
  expect(tsunamiSlots.disasterType, DisasterType.tsunami);
  expect(tsunamiSlots.disasterTypeEvidence, contains('津波'));

  final flood = await engine.extractSlots('マンションの9階にいて外が水浸し');
  expect(flood, isA<Ok<SituationSlots, LlmError>>());
  final floodSlots = (flood as Ok<SituationSlots, LlmError>).value;
  expect(floodSlots.disasterType, DisasterType.flood);
  expect(floodSlots.intent, Intent.guide);

  final wheelchair = await engine.extractSlots('母が車椅子なので一緒に避難したい');
  expect(wheelchair, isA<Ok<SituationSlots, LlmError>>());
  final wheelchairSlots = (wheelchair as Ok<SituationSlots, LlmError>).value;
  expect(wheelchairSlots.userState.mobility, Mobility.wheelchair);
}
