@Tags(['real_llm'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/real_llm_assertions.dart';
import '../../helpers/real_llm_harness.dart';

/// LeapLlmEngine 実推論 smoke（iOS シミュレータ / 実機専用）。
///
/// ホスト VM では liquid_ai をロードできないため、通常の `flutter test` では skip する。
/// 実行: `tool/sim/test_llm.sh` または
/// `flutter test integration_test/lfm25_real_inference_test.dart -d <UDID>`
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
        skipReason = 'シミュレータでは Leap SDK のメモリチェック不可（実機で extractSlots を実行）';
        return;
      }
      skipReason =
          'LFM2-350M のロードに失敗: ${harness!.downloader.lastFailureDetail ?? 'unknown'}';
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

  test('LeapLlmEngine extractSlots smoke（津波・浸水・車椅子）', () async {
    if (skipReason != null || harness == null) {
      // ignore: avoid_print
      print('SKIP: ${skipReason ?? 'harness null'}');
      return;
    }
    await runLeapLlmEngineSmokeTests(harness!.engine);
  });
}
