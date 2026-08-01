import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/data/llm/llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/model_registry.dart';

void main() {
  test('ティア判定: RAM 4GB+ → 1.2B-JP', () {
    expect(
      ModelRegistry.recommend(ramMb: 4096, cpuCores: 6),
      LlmModelChoice.lfm25_1200jp,
    );
  });

  test('ティア判定: RAM 不足 → off', () {
    expect(
      ModelRegistry.recommend(ramMb: 1024, cpuCores: 2),
      LlmModelChoice.off,
    );
  });
}
