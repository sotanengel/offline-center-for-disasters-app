@Tags(['real_llm'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';

import '../helpers/real_llm_harness.dart';

/// ゴールデンセットから代表 10 件を LFM2.5 実推論で評価（smoke 精度）。
/// ホスト VM では実行しない（integration_test 経由で評価）。
void main() {
  if (!RealLlmHarness.supportedPlatform) {
    return;
  }
  RealLlmHarness? harness;
  String? skipReason;
  var modelDownloaded = false;

  setUpAll(() async {
    harness = await RealLlmHarness.tryCreate();
    if (harness == null) {
      skipReason = 'RealLlmHarness を作成できません';
      return;
    }

    modelDownloaded = await harness!.ensureModelDownloaded();
    if (!modelDownloaded) {
      skipReason =
          'LFM2-350M の DL に失敗: ${harness!.downloader.lastFailureDetail ?? 'unknown'}';
      return;
    }

    final ready = await harness!.ensureModelReady();
    if (!ready) {
      if (harness!.isSimulatorMemoryBlocked) {
        skipReason = 'シミュレータでは Leap SDK のメモリチェック不可（実機で golden LLM を実行）';
        return;
      }
      skipReason = 'LFM2-350M のロードに失敗';
      harness = null;
    }
  });

  tearDownAll(() async {
    await harness?.dispose();
  });

  test('LFM2-350M モデルをダウンロードできる', () {
    if (skipReason != null && !modelDownloaded) {
      fail(skipReason!);
    }
    expect(modelDownloaded, isTrue);
  });

  test('ゴールデン代表10件: disaster_type ≥ 60%', () async {
    if (skipReason != null || harness == null) {
      // ignore: avoid_print
      print('SKIP: ${skipReason ?? 'harness null'}');
      return;
    }

    final raw = await File('test/golden_slots/cases.json').readAsString();
    final cases = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final subset = cases.take(10).toList();

    var typeOk = 0;
    var n = 0;
    for (final c in subset) {
      final input = c['input'] as String;
      final expType = DisasterType.values.byName(c['disasterType'] as String);
      final r = await harness!.engine.extractSlots(input);
      if (r is! Ok<SituationSlots, LlmError>) continue;
      n++;
      if (r.value.disasterType == expType) {
        typeOk++;
      }
    }
    expect(n, greaterThan(0));
    expect(typeOk / n, greaterThanOrEqualTo(0.6));
  });
}
