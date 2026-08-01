import 'dart:io';

import 'package:offline_center_for_disasters/data/llm/device_tier_service.dart';
import 'package:offline_center_for_disasters/data/llm/leap_llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/data/llm/model_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LFM2.5 実推論テスト用ハーネス（シミュレータ / 実機）。
///
/// モデルは [testModel]（350M）を固定し、初回 DL 時は [requireWifiForDownload] を
/// false にしてテスト setup のみネットワークを許可する。
///
/// 注意: iOS シミュレータでは `os_proc_available_memory()` が 0 を返すため
/// Leap SDK のロードが [InsufficientMemoryError] になる。実推論 smoke は実機で実行すること。
class RealLlmHarness {
  RealLlmHarness._({
    required this.engine,
    required this.downloader,
    required this.tierService,
  });

  final LeapLlmEngine engine;
  final ModelDownloader downloader;
  final DeviceTierService tierService;

  /// シミュレータ（iPhone SE 4GB）向け固定モデル。
  static const testModel = LlmModelChoice.lfm25_350m;

  static const inferenceTimeout = Duration(seconds: 30);

  static bool get supportedPlatform => Platform.isIOS;

  /// 直近の DL/ロード失敗理由。
  LlmError? lastError;

  /// 直近の DL/ロード失敗詳細。
  String? lastFailureDetail;

  /// シミュレータ上でメモリチェックが失敗したか（os_proc_available_memory=0）。
  bool get isSimulatorMemoryBlocked =>
      lastFailureDetail?.contains('InsufficientMemoryError') == true &&
      lastFailureDetail?.contains('available: 0') == true;

  /// プラットフォーム非対応時は null。
  static Future<RealLlmHarness?> tryCreate({
    bool useMockPrefs = true,
    Map<String, Object> prefs = const {'onboarding_complete': true},
  }) async {
    if (!supportedPlatform) return null;
    if (useMockPrefs) {
      SharedPreferences.setMockInitialValues(prefs);
    }
    final shared = await SharedPreferences.getInstance();
    final downloader = ModelDownloader();
    final tierService = DeviceTierService(shared);
    final engine = LeapLlmEngine(
      downloader: downloader,
      tierService: tierService,
      userChoice: testModel,
      inferenceTimeout: inferenceTimeout,
    );
    return RealLlmHarness._(
      engine: engine,
      downloader: downloader,
      tierService: tierService,
    );
  }

  /// モデルのみ DL（ロードなし）。
  Future<bool> ensureModelDownloaded({
    bool requireWifiForDownload = false,
  }) async {
    return downloader.downloadOnly(
      choice: testModel,
      requireWifi: requireWifiForDownload,
    );
  }

  /// モデル DL + ロード。成功時 true。失敗時は [lastError] / [lastFailureDetail] を設定。
  Future<bool> ensureModelReady({bool requireWifiForDownload = false}) async {
    final load = await downloader.downloadAndLoad(
      choice: testModel,
      requireWifi: requireWifiForDownload,
    );
    return load.fold(
      ok: (_) => true,
      err: (e) {
        lastError = e;
        lastFailureDetail = downloader.lastFailureDetail;
        return false;
      },
    );
  }

  Future<void> dispose() async {
    await engine.unload();
    await downloader.unload();
  }
}
