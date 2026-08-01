import 'llm_engine.dart';

/// LEAP SDK スタブ（P5 で差し替え）。
class LeapStubEngine implements LlmEngine {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<String?> analyzeText(String input) async => null;
}
