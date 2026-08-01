import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/geo/geo_point.dart';
import '../core/result/result.dart';
import '../data/pack/pack_hazard_prior.dart';
import '../data/pack/pack_loader.dart';
import '../data/prefs/recent_selection_store.dart';
import '../data/routing/graph_route_engine.dart';
import '../data/sensors/shake_detector.dart';
import '../domain/entities/disaster_candidate.dart';
import '../domain/entities/enums.dart';
import '../domain/entities/hazard_context.dart';
import '../domain/entities/situation_slots.dart';
import '../domain/policies/destination_policy.dart';
import '../domain/policies/evacuation_mode_judge.dart';
import '../domain/policies/hazard_prior_scorer.dart';
import '../domain/services/hazard_prior.dart';
import '../data/llm/ai_situation_analyzer.dart';
import '../data/llm/composite_situation_analyzer.dart';
import '../data/llm/device_tier_service.dart';
import '../data/llm/guide_reranker.dart';
import '../data/llm/leap_llm_engine.dart';
import '../data/llm/leap_stub_engine.dart';
import '../data/llm/llm_engine.dart';
import '../data/llm/model_downloader.dart';
import '../data/guidance/kb_guidance_service.dart';
import '../data/pack/pack_source.dart';
import '../domain/services/guidance_service.dart';
import '../domain/services/route_engine.dart';
import '../data/rule/rule_situation_analyzer.dart';
import '../domain/services/situation_analyzer.dart';
import '../domain/usecases/destination_planner.dart';

/// シミュレータ / 統合テスト想定の現在地（江東区付近）。
/// パック未配置・GPS 未取得時のフォールバック原点にも使う。
const kDefaultOrigin = GeoPoint(35.687741, 139.850977);

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

// ---------------------------------------------------------------------------
// 現在地
// ---------------------------------------------------------------------------

/// 現在地取得のポリシー (§16.3: 既定精度は medium)。
///
/// 権限拒否・GPS 失敗時は null を返す (§3.8: アプリが使えなくならないこと)。
/// テストでは overrideWith で差し替える。
final locationProvider = FutureProvider<GeoPoint?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final perm = await Geolocator.checkPermission();
    // §3.8: 起動時にダイアログでブロックしない。未許可なら null で縮退する。
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    return GeoPoint(pos.latitude, pos.longitude);
  } catch (_) {
    // GPS 失敗・プラットフォーム未対応・テスト環境等では null にフォールバック
    return null;
  }
});

// ---------------------------------------------------------------------------
// データパック
// ---------------------------------------------------------------------------

/// 対象地域コード (region key)。初期は tokyo。
/// S-05 (#12) で永続化・切替を実装するまで固定値とする。
final currentRegionProvider = Provider<String>((ref) => 'tokyo');

/// 対象パックの絶対パス。application support/packs/[currentRegionProvider]/pack.sqlite。
final packPathProvider = FutureProvider<String>((ref) async {
  final region = ref.watch(currentRegionProvider);
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, 'packs', region, 'pack.sqlite');
});

/// 開いた [DataPack]。ファイル未取得 / 破損時は null を返して縮退する (§12)。
final dataPackProvider = FutureProvider<DataPack?>((ref) async {
  final String path;
  try {
    path = await ref.watch(packPathProvider.future);
  } catch (_) {
    return null; // path_provider が使えない (テスト等)
  }
  if (!File(path).existsSync()) return null;
  final res = await PackLoader.open(path);
  return res.fold(
    ok: (pack) {
      ref.onDispose(pack.close);
      return pack;
    },
    err: (_) => null,
  );
});

// ---------------------------------------------------------------------------
// ハザードコンテキスト / プライア
// ---------------------------------------------------------------------------

/// 現在地のハザードコンテキスト。パックか位置が無ければ既定値 (区域外)。
final hazardContextProvider = FutureProvider<HazardContext>((ref) async {
  final pack = await ref.watch(dataPackProvider.future);
  final loc = await ref.watch(locationProvider.future);
  if (pack == null || loc == null) return const HazardContext();
  return pack.hazardGrid.contextAt(loc);
});

final hazardPriorScorerProvider = Provider<HazardPriorScorer>(
  (ref) => HazardPriorScorer(),
);

/// §14.4 HazardPrior 実装。パック未取得時はスコアラのみでスコア (既定コンテキスト)。
final hazardPriorProvider = FutureProvider<HazardPrior>((ref) async {
  final pack = await ref.watch(dataPackProvider.future);
  final scorer = ref.watch(hazardPriorScorerProvider);
  if (pack == null) return _FallbackHazardPrior(scorer);
  return PackHazardPrior(pack.hazardGrid, scorer);
});

/// §3.4-a: ハザードプライア (スコア降順・7 種別すべて)。
final disasterCandidatesProvider = FutureProvider<List<DisasterCandidate>>((
  ref,
) async {
  final ctx = await ref.watch(hazardContextProvider.future);
  return ref.read(hazardPriorScorerProvider).rank(ctx);
});

// ---------------------------------------------------------------------------
// 決定表 / 判定 / 経路
// ---------------------------------------------------------------------------

final destinationPolicyProvider = Provider<DestinationPolicy>(
  (ref) => const DestinationPolicy(),
);

final evacuationModeJudgeProvider = Provider<EvacuationModeJudge>(
  (ref) => const EvacuationModeJudgeImpl(),
);

/// ShelterFinder はパック依存。パックが無ければ null。
final shelterFinderProvider = FutureProvider((ref) async {
  final pack = await ref.watch(dataPackProvider.future);
  return pack?.shelterFinder;
});

/// RouteEngine はパック依存。パックが無ければ null。
final routeEngineProvider = FutureProvider<RouteEngine?>((ref) async {
  final pack = await ref.watch(dataPackProvider.future);
  if (pack == null) return null;
  // 現状は全件ロード (bbox 絞り込みは呼び出し側で GraphLoader.load(bounds:...) を使う)。
  final graph = await pack.graphLoader.load();
  return GraphRouteEngine(nodes: graph.nodes, edges: graph.edges);
});

/// S-02: 避難先候補 + 経路プレビュー（§9.1）。
final destinationPlanProvider =
    FutureProvider.family<DestinationPlan, SituationSlots>((ref, slots) async {
      final loc = await ref.watch(locationProvider.future) ?? kDefaultOrigin;
      final pack = await ref.watch(dataPackProvider.future);
      final engine = await ref.watch(routeEngineProvider.future);
      return const DestinationPlanner().plan(
        slots: slots,
        origin: loc,
        pack: pack,
        routeEngine: engine,
      );
    });

// ---------------------------------------------------------------------------
// センサ / STT / 一言入力
// ---------------------------------------------------------------------------

final shakeDetectorProvider = Provider<ShakeDetector>((ref) {
  final detector = ShakeDetector(
    accelStream: accelerometerEventStream().map(
      (e) => AccelSample(e.x, e.y, e.z, DateTime.now()),
    ),
  );
  ref.onDispose(detector.dispose);
  return detector..start();
});

/// §3.4-b: 揺れ検知の保持状態 (新規検知イベントで更新)。
final shakeDetectedProvider = StreamProvider<bool>((ref) async* {
  final detector = ref.watch(shakeDetectorProvider);
  yield detector.isDetected;
  await for (final _ in detector.changes) {
    yield detector.isDetected;
  }
});

/// §3.2 L2: オフライン音声認識の可否。非対応ならマイクを非活性化する。
///
/// 起動時に [SpeechToText.initialize] を呼ばない（TCC ダイアログで UI が固まるため）。
/// マイク操作実装時に lazy initialize + 権限要求を行う。
final offlineSttAvailableProvider = FutureProvider<bool>((ref) async => false);

/// L2 自由文 (確定は結果画面・PR-7/PR-9 で使用)。
final freeTextProvider = StateProvider<String>((ref) => '');

/// LLM モデル選択の永続化（PR-10 / F-11 / P5）。
final llmModelChoiceProvider =
    NotifierProvider<LlmModelChoiceNotifier, LlmModelChoice>(
      LlmModelChoiceNotifier.new,
    );

class LlmModelChoiceNotifier extends Notifier<LlmModelChoice> {
  static const _key = 'llm_model_choice';

  @override
  LlmModelChoice build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return LlmModelChoice.auto;
    return LlmModelChoice.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => LlmModelChoice.auto,
    );
  }

  Future<void> setChoice(LlmModelChoice choice) async {
    await ref.read(sharedPreferencesProvider).setString(_key, choice.name);
    state = choice;
  }
}

final deviceTierServiceProvider = Provider<DeviceTierService>(
  (ref) => DeviceTierService(ref.watch(sharedPreferencesProvider)),
);

final modelDownloaderProvider = Provider<ModelDownloader>((ref) {
  final downloader = ModelDownloader();
  ref.onDispose(() => downloader.unload());
  return downloader;
});

/// §7 LEAP エンジン（不可時はスタブ）。
final llmEngineProvider = Provider<LlmEngine>((ref) {
  final choice = ref.watch(llmModelChoiceProvider);
  if (choice == LlmModelChoice.off) {
    return LeapStubEngine();
  }
  return LeapLlmEngine(
    downloader: ref.watch(modelDownloaderProvider),
    tierService: ref.watch(deviceTierServiceProvider),
    userChoice: choice,
  );
});

final guideRerankerProvider = Provider<GuideReranker>(
  (ref) => GuideReranker(ref.watch(llmEngineProvider)),
);

final phraseGeneratorProvider = Provider<PhraseGenerator>(
  (ref) => PhraseGenerator(ref.watch(llmEngineProvider)),
);

/// 簡易モード（LLM 不可）表示用。
final llmSimpleModeProvider = FutureProvider<bool>((ref) async {
  final engine = ref.watch(llmEngineProvider);
  return !(await engine.isAvailable());
});

/// §8.3 + P5: LLM → Rule 合成 SituationAnalyzer。
final situationAnalyzerProvider = Provider<SituationAnalyzer>((ref) {
  final llm = ref.watch(llmEngineProvider);
  return CompositeSituationAnalyzer(
    llm: AiSituationAnalyzer(llm),
    rule: RuleSituationAnalyzerLoader(),
  );
});

/// §11.1 KB ガイド検索 + AI-3 リランキング（P6）。
final guidanceServiceProvider = Provider<GuidanceService>((ref) {
  return KbGuidanceServiceLoader(reranker: ref.watch(guideRerankerProvider));
});

/// 初回セットアップ完了フラグ。
final onboardingCompleteProvider =
    AsyncNotifierProvider<OnboardingCompleteNotifier, bool>(
      OnboardingCompleteNotifier.new,
    );

class OnboardingCompleteNotifier extends AsyncNotifier<bool> {
  static const _key = 'onboarding_complete';

  @override
  Future<bool> build() async {
    return ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;
  }

  Future<void> setComplete(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
    state = AsyncData(value);
  }
}

/// 導入済みパック一覧（初版: ローカル列挙）。
final packSourceProvider = Provider<PackSource>(
  (ref) => LocalPackSource({'tokyo'}),
);

final installedRegionsProvider = FutureProvider<List<String>>((ref) async {
  final r = await ref.watch(packSourceProvider).listInstalledRegions();
  return switch (r) {
    Ok(value: final v) => v,
    Err() => const [],
  };
});

// ---------------------------------------------------------------------------
// 内部ヘルパ
// ---------------------------------------------------------------------------

class _FallbackHazardPrior implements HazardPrior {
  const _FallbackHazardPrior(this._scorer);
  final HazardPriorScorer _scorer;

  @override
  Future<List<DisasterCandidate>> rank(GeoPoint origin) async =>
      _scorer.rank(const HazardContext());
}
