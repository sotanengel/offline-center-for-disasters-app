import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:offline_center_for_disasters/data/llm/device_tier_service.dart';
import 'package:offline_center_for_disasters/data/llm/llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/model_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late DeviceTierService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = DeviceTierService(prefs);
  });

  test('ティア判定: RAM 4GB+6core → 1.2B', () {
    expect(
      ModelRegistry.recommend(ramMb: 4096, cpuCores: 6),
      LlmModelChoice.lfm25_1200jp,
    );
  });

  test('メモリ不足降格', () {
    expect(
      service.downgrade(LlmModelChoice.lfm25_1200jp),
      LlmModelChoice.lfm25_350m,
    );
    expect(
      service.downgrade(LlmModelChoice.lfm25_350m),
      LlmModelChoice.lfm25_230m,
    );
    expect(service.downgrade(LlmModelChoice.lfm25_230m), LlmModelChoice.off);
  });

  test('ウォームアップ遅い場合はティア降格', () async {
    final choice = await service.tierAfterWarmup(
      tokensPerSec: 10,
      ramMb: 8192,
      cpuCores: 8,
    );
    expect(choice, LlmModelChoice.lfm25_350m);
    expect(prefs.getString('llm_device_tier'), 'lfm25_350m');
  });

  test('off 設定はそのまま', () async {
    final choice = await service.resolveEffectiveChoice(LlmModelChoice.off);
    expect(choice, LlmModelChoice.off);
  });
}
