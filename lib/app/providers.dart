import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/result/result.dart';
import '../data/prefs/recent_selection_store.dart';
import '../data/sensors/shake_detector.dart';
import '../domain/entities/disaster_candidate.dart';
import '../domain/entities/enums.dart';
import '../domain/entities/hazard_context.dart';
import '../domain/policies/hazard_prior_scorer.dart';

/// main() で実インスタンスをオーバーライドする。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main() でオーバーライドすること'),
);

final recentSelectionStoreProvider = Provider<RecentSelectionStore>(
  (ref) => RecentSelectionStore(ref.watch(sharedPreferencesProvider)),
);

/// §3.4-c: 30 分以内の直近選択。
final recentSelectionProvider = FutureProvider<DisasterType?>(
  (ref) => ref.watch(recentSelectionStoreProvider).recent(),
);

/// 現在地のハザードコンテキスト。
/// データパック未導入時は既定値（区域外）。パック接続は PR-10/11 で配線する。
final hazardContextProvider = FutureProvider<HazardContext>(
  (ref) async => const HazardContext(),
);

final hazardPriorScorerProvider = Provider<HazardPriorScorer>(
  (ref) => HazardPriorScorer(),
);

/// §3.4-a: ハザードプライア（スコア降順・7 種別すべて）。
final disasterCandidatesProvider = FutureProvider<List<DisasterCandidate>>((
  ref,
) async {
  final ctx = await ref.watch(hazardContextProvider.future);
  return ref.read(hazardPriorScorerProvider).rank(ctx);
});

final shakeDetectorProvider = Provider<ShakeDetector>((ref) {
  final detector = ShakeDetector(
    accelStream: accelerometerEventStream().map(
      (e) => AccelSample(e.x, e.y, e.z, DateTime.now()),
    ),
  );
  ref.onDispose(detector.dispose);
  return detector..start();
});

/// §3.4-b: 揺れ検知の保持状態（新規検知イベントで更新）。
final shakeDetectedProvider = StreamProvider<bool>((ref) async* {
  final detector = ref.watch(shakeDetectorProvider);
  yield detector.isDetected;
  await for (final _ in detector.changes) {
    yield detector.isDetected;
  }
});

/// §3.2 L2: オフライン音声認識の可否。非対応ならマイクを非活性化する。
final offlineSttAvailableProvider = FutureProvider<bool>((ref) async {
  final result = await guard<bool, Object>(
    () => SpeechToText().initialize(),
    (e) => e,
  );
  return switch (result) {
    Ok(value: final available) => available,
    Err() => false,
  };
});

/// L2 自由文（確定は結果画面・PR-7/PR-9 で使用）。
final freeTextProvider = StateProvider<String>((ref) => '');
