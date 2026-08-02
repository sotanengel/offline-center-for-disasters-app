import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/geo/geo_point.dart';
import '../core/result/result.dart';
import '../data/location/location_service.dart';
import '../data/pack/bundled_pack_installer.dart';
import '../data/pack/evacuation_pack.dart';
import '../data/pack/multi_region_pack.dart';
import '../data/pack/pack_catalog.dart';
import '../data/pack/pack_hazard_prior.dart';
import '../data/pack/pack_loader.dart';
import '../data/pack/region_pack_info.dart';
import '../data/prefs/recent_selection_store.dart';
import '../data/routing/graph_route_engine.dart';
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
import '../data/rule/rule_situation_analyzer.dart';
import '../domain/services/situation_analyzer.dart';
import '../domain/usecases/destination_plan_progress.dart';
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

/// 位置情報サービス（テストで [FakeLocationService] 等に差し替え可能）。
final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

/// 現在地取得のポリシー (§16.3: 既定精度は medium)。
///
/// 未許可時は [LocationService.requestPermission] を呼ぶ（F-11）。
/// 拒否・GPS 失敗時は null を返す (§3.8: アプリが使えなくならないこと)。
/// テストでは overrideWith で差し替える。
final locationProvider = FutureProvider<GeoPoint?>((ref) async {
  try {
    final location = ref.watch(locationServiceProvider);
    if (!await location.isLocationServiceEnabled()) return null;
    var perm = await location.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await location.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await location.getCurrentPosition(
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

/// 案内中の現在地更新用ストリーム（権限なし・GPS 無効時は空）。
final positionStreamProvider = StreamProvider<GeoPoint?>((ref) async* {
  try {
    final location = ref.watch(locationServiceProvider);
    if (!await location.isLocationServiceEnabled()) return;
    var perm = await location.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await location.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }
    yield* location
        .getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 5,
          ),
        )
        .map((pos) => GeoPoint(pos.latitude, pos.longitude));
  } catch (_) {
    return;
  }
});

// ---------------------------------------------------------------------------
// データパック
// ---------------------------------------------------------------------------

/// Application Support/packs ディレクトリ。
final packsRootProvider = FutureProvider<Directory>((ref) async {
  final dir = await getApplicationSupportDirectory();
  return Directory(p.join(dir.path, 'packs'));
});

/// 導入済みパックの region/bbox カタログ。
final installedPackInfosProvider = FutureProvider<List<RegionPackInfo>>((
  ref,
) async {
  try {
    final root = await ref.watch(packsRootProvider.future);
    return PackCatalog.scan(root);
  } catch (_) {
    return const <RegionPackInfo>[]; // path_provider が使えない (テスト等)
  }
});

/// 同梱統合パック（bundled）を優先して開く。dev 用に単県のみ導入時は従来マージ。
Future<EvacuationPack?> _openEvacuationPack(Directory packsRoot) async {
  final bundledPath = BundledPackInstaller.packPathFor(packsRoot);
  if (File(bundledPath).existsSync()) {
    final res = await PackLoader.open(bundledPath);
    final pack = res.valueOrNull;
    if (pack != null) return pack;
  }

  final infos = await PackCatalog.scan(packsRoot);
  if (infos.isEmpty) return null;

  // dev: 単県パックのみ手動配置時
  final devPacks = infos.where(
    (i) => i.regionKey != BundledPackInstaller.bundledPackKey,
  );
  final opened = <DataPack>[];
  for (final info in devPacks) {
    final res = await PackLoader.open(info.path);
    final pack = res.valueOrNull;
    if (pack != null) opened.add(pack);
  }
  if (opened.isEmpty) return null;
  if (opened.length == 1) return opened.single;
  return MultiRegionPack(opened);
}

/// 導入済みの同梱統合パック（または dev 用マルチパック）。
/// 未配置 / 破損時は null で縮退する (§12)。
final dataPackProvider = FutureProvider<EvacuationPack?>((ref) async {
  try {
    final root = await ref.watch(packsRootProvider.future);
    final pack = await _openEvacuationPack(root);
    if (pack == null) return null;
    ref.onDispose(pack.close);
    return pack;
  } catch (_) {
    return null;
  }
});

/// 互換: 旧テストが単一パスを差し込む用。未使用時は dataPackProvider に委譲。
final packPathProvider = FutureProvider<String>((ref) async {
  final root = await ref.watch(packsRootProvider.future);
  return BundledPackInstaller.packPathFor(root);
});

// ---------------------------------------------------------------------------
// ハザードコンテキスト / プライア
// ---------------------------------------------------------------------------

/// 現在地のハザードコンテキスト。パックか位置が無ければ既定値 (区域外)。
final hazardContextProvider = FutureProvider<HazardContext>((ref) async {
  final pack = await ref.watch(dataPackProvider.future);
  final loc = await ref.watch(locationProvider.future);
  if (pack == null || loc == null) return const HazardContext();
  return pack.contextAt(loc);
});

final hazardPriorScorerProvider = Provider<HazardPriorScorer>(
  (ref) => HazardPriorScorer(),
);

/// §14.4 HazardPrior 実装。パック未取得時はスコアラのみでスコア (既定コンテキスト)。
final hazardPriorProvider = FutureProvider<HazardPrior>((ref) async {
  final pack = await ref.watch(dataPackProvider.future);
  final scorer = ref.watch(hazardPriorScorerProvider);
  if (pack == null) return _FallbackHazardPrior(scorer);
  return PackHazardPrior.fromPack(pack, scorer);
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

/// 避難用パック。無ければ null。
final shelterFinderProvider = FutureProvider<EvacuationPack?>((ref) async {
  return ref.watch(dataPackProvider.future);
});

// 経路グラフのロードは DestinationPlanner が避難先確定後に行う（§16.1）。
// 現在地から一律の半径で読むと実機では重すぎるため、専用の provider は置かない。

/// S-02: 避難先候補 + 経路プレビュー（§9.1）。
final destinationPlanProvider =
    NotifierProvider.family<
      DestinationPlanNotifier,
      DestinationPlanState,
      SituationSlots
    >(DestinationPlanNotifier.new);

class DestinationPlanNotifier
    extends FamilyNotifier<DestinationPlanState, SituationSlots> {
  @override
  DestinationPlanState build(SituationSlots slots) {
    unawaited(_load(slots));
    return const DestinationPlanLoading(DestinationPlanProgress.preparing);
  }

  Future<void> _load(SituationSlots slots) async {
    try {
      final loc = await ref.read(locationProvider.future) ?? kDefaultOrigin;
      final pack = await ref.read(dataPackProvider.future);
      final plan = await const DestinationPlanner().plan(
        slots: slots,
        origin: loc,
        pack: pack,
        onProgress: (progress) {
          if (state is! DestinationPlanReady) {
            state = DestinationPlanLoading(progress);
          }
        },
        routeEngineFactory: (bounds) async {
          if (pack == null) return null;
          final graph = await pack.loadGraph(bounds: bounds);
          return GraphRouteEngine(nodes: graph.nodes, edges: graph.edges);
        },
      );
      state = DestinationPlanReady(plan);
    } catch (e) {
      state = DestinationPlanFailed(e);
    }
  }
}

// ---------------------------------------------------------------------------
// センサ / STT / 一言入力
// ---------------------------------------------------------------------------

/// 揺れ検知 UI は無効化（F-BUG-01）。センサは起動しない。
final shakeDetectedProvider = StreamProvider<bool>(
  (ref) => Stream.value(false),
);

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

/// 導入済みパック一覧（ディスク列挙）。
final packSourceProvider = FutureProvider<PackSource>((ref) async {
  try {
    final root = await ref.watch(packsRootProvider.future);
    return FilesystemPackSource(root);
  } catch (_) {
    return LocalPackSource({});
  }
});

final installedRegionsProvider = FutureProvider<List<String>>((ref) async {
  final source = await ref.watch(packSourceProvider.future);
  final r = await source.listInstalledRegions();
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
