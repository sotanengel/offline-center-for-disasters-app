import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'llm_engine.dart';
import 'model_registry.dart';

/// §7.1 デバイスティア判定（RAM/CPU + ウォームアップ結果の永続化）。
class DeviceTierService {
  DeviceTierService(this._prefs, {DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final SharedPreferences _prefs;
  final DeviceInfoPlugin _deviceInfo;

  static const _tierKey = 'llm_device_tier';
  static const _warmupTokPerSecKey = 'llm_warmup_tok_per_sec';

  /// 永続化済みティア。未設定なら [detectRecommendedChoice] で推定。
  LlmModelChoice get persistedChoice {
    final raw = _prefs.getString(_tierKey);
    if (raw == null) return LlmModelChoice.auto;
    return LlmModelChoice.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => LlmModelChoice.auto,
    );
  }

  /// RAM [MB] と CPU コア数を取得する（プラットフォーム依存）。
  Future<({int ramMb, int cpuCores})> readDeviceSpecs() async {
    if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      final ram = ios.physicalRamSize;
      // iOS はコア数 API が無いため RAM から推定（§7.1 ウォームアップで補正）。
      final cores = ram >= 6144 ? 6 : 4;
      return (ramMb: ram, cpuCores: cores);
    }
    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      final ramMb = android.physicalRamSize;
      return (ramMb: ramMb, cpuCores: 4);
    }
    return (ramMb: 4096, cpuCores: 4);
  }

  /// §7.1: RAM/CPU から推奨モデルを返す。
  Future<LlmModelChoice> detectRecommendedChoice() async {
    final specs = await readDeviceSpecs();
    return ModelRegistry.recommend(
      ramMb: specs.ramMb,
      cpuCores: specs.cpuCores,
    );
  }

  /// ユーザー設定 + 自動判定から実効モデルを決定。
  Future<LlmModelChoice> resolveEffectiveChoice(
    LlmModelChoice userChoice,
  ) async {
    if (userChoice == LlmModelChoice.off) return LlmModelChoice.off;
    if (userChoice != LlmModelChoice.auto) return userChoice;
    final persisted = persistedChoice;
    if (persisted != LlmModelChoice.auto) return persisted;
    return detectRecommendedChoice();
  }

  Future<void> persistChoice(LlmModelChoice choice) async {
    await _prefs.setString(_tierKey, choice.name);
  }

  Future<void> persistWarmupTokensPerSec(double value) async {
    await _prefs.setDouble(_warmupTokPerSecKey, value);
  }

  double? get warmupTokensPerSec => _prefs.getDouble(_warmupTokPerSecKey);

  /// §7.1: decode ≥ 15 tok/s でティア A を維持。未計測なら RAM ベース。
  Future<LlmModelChoice> tierAfterWarmup({
    required double tokensPerSec,
    required int ramMb,
    required int cpuCores,
  }) async {
    await persistWarmupTokensPerSec(tokensPerSec);
    var choice = ModelRegistry.recommend(ramMb: ramMb, cpuCores: cpuCores);
    if (choice == LlmModelChoice.lfm25_1200jp && tokensPerSec < 15) {
      choice = LlmModelChoice.lfm25_350m;
    }
    await persistChoice(choice);
    return choice;
  }

  /// メモリ不足時 1 段階降格（§7.3）。
  LlmModelChoice downgrade(LlmModelChoice current) => switch (current) {
    LlmModelChoice.lfm25_1200jp => LlmModelChoice.lfm25_350m,
    LlmModelChoice.lfm25_350m => LlmModelChoice.lfm25_230m,
    _ => LlmModelChoice.off,
  };
}
