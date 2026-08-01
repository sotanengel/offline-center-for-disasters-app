import 'llm_engine.dart';

/// §7.1 デバイスティアと LFM2.5 3 サイズのメタ情報。
class ModelRegistryEntry {
  const ModelRegistryEntry({
    required this.id,
    required this.name,
    required this.tier,
    required this.approxSizeMb,
    required this.requiredRamMb,
    required this.features,
  });

  final String id;
  final String name;
  final String tier;
  final int approxSizeMb;
  final int requiredRamMb;
  final List<String> features;
}

class ModelRegistry {
  static const entries = [
    ModelRegistryEntry(
      id: 'lfm25-1200-jp',
      name: 'LFM2.5-1.2B-JP',
      tier: 'A',
      approxSizeMb: 850,
      requiredRamMb: 4096,
      features: ['AI-1', 'AI-2', 'AI-3', 'AI-4'],
    ),
    ModelRegistryEntry(
      id: 'lfm25-350m',
      name: 'LFM2.5-350M',
      tier: 'B',
      approxSizeMb: 250,
      requiredRamMb: 2048,
      features: ['AI-1', 'AI-2'],
    ),
    ModelRegistryEntry(
      id: 'lfm25-230m',
      name: 'LFM2.5-230M',
      tier: 'C',
      approxSizeMb: 150,
      requiredRamMb: 1536,
      features: ['AI-1'],
    ),
  ];

  /// RAM [MB] と CPU コア数から推奨モデル（§7.1 純粋関数）。
  static LlmModelChoice recommend({required int ramMb, required int cpuCores}) {
    if (ramMb >= 4096 && cpuCores >= 6) return LlmModelChoice.lfm25_1200jp;
    if (ramMb >= 2048) return LlmModelChoice.lfm25_350m;
    if (ramMb >= 1536) return LlmModelChoice.lfm25_230m;
    return LlmModelChoice.off;
  }
}
