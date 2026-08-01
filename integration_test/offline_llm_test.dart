import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/data/llm/leap_stub_engine.dart';

/// オフライン LLM 縮退（スタブ）の smoke。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('LeapStubEngine は常に unavailable', () async {
    final engine = LeapStubEngine();
    expect(await engine.isAvailable(), isFalse);
    final r = await engine.extractSlots('津波');
    expect(r.isErr, isTrue);
  });
}
