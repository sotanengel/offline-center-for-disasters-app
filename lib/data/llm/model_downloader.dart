import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:liquid_ai/liquid_ai.dart';

import '../../core/result/result.dart';
import 'llm_engine.dart';
import 'llm_errors.dart';
import 'model_registry.dart';

/// §7.1 / §14.5 モデル DL とロード管理。
class ModelDownloader {
  ModelDownloader({LiquidAi? liquidAi, Connectivity? connectivity})
    : _liquidAi = liquidAi ?? LiquidAi(),
      _connectivity = connectivity ?? Connectivity();

  final LiquidAi _liquidAi;
  final Connectivity _connectivity;

  ModelDownloadState state = ModelDownloadState.notStarted;
  ModelRunner? _runner;
  String? _loadedSlug;

  /// 直近の DL/ロード失敗理由（テスト診断用）。
  String? lastFailureDetail;

  static const _quantization = 'Q4_K_M';

  /// Wi-Fi 接続時のみ DL を許可（§14.5）。
  Future<bool> isWifiConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  Future<bool> isModelDownloaded(LlmModelChoice choice) async {
    final slug = ModelRegistry.catalogSlug(choice);
    if (slug == null) return false;
    try {
      return await _liquidAi.isModelDownloaded(slug, _quantization);
    } catch (_) {
      return false;
    }
  }

  Future<Result<ModelRunner, LlmError>> downloadAndLoad({
    required LlmModelChoice choice,
    void Function(ModelDownloadProgress progress)? onProgress,
    bool requireWifi = true,
  }) async {
    if (choice == LlmModelChoice.off) {
      return const Err(LlmError.unavailable);
    }
    if (requireWifi && !await isWifiConnected()) {
      return const Err(LlmError.unavailable);
    }

    final slug = ModelRegistry.catalogSlug(choice);
    if (slug == null) return const Err(LlmError.unavailable);

    if (_runner != null && _loadedSlug == slug) {
      state = ModelDownloadState.ready;
      return Ok(_runner!);
    }

    state = ModelDownloadState.downloading;
    try {
      if (!await _liquidAi.isModelDownloaded(slug, _quantization)) {
        var downloaded = false;
        await for (final event in _liquidAi.downloadModel(
          slug,
          _quantization,
        )) {
          switch (event) {
            case DownloadCompleteEvent():
              downloaded = true;
            case DownloadErrorEvent(:final error):
              lastFailureDetail = error;
              state = ModelDownloadState.failed;
              return const Err(LlmError.modelNotLoaded);
            case DownloadProgressEvent(:final progress):
              onProgress?.call((
                progress: progress.progress,
                bytesPerSecond: progress.speed,
              ));
            default:
              break;
          }
        }
        if (!downloaded) {
          lastFailureDetail ??= 'download stream ended without complete';
          state = ModelDownloadState.failed;
          return const Err(LlmError.modelNotLoaded);
        }
      }

      await for (final event in _liquidAi.loadModel(slug, _quantization)) {
        switch (event) {
          case LoadProgressEvent(:final progress):
            onProgress?.call((
              progress: progress.progress,
              bytesPerSecond: progress.speed,
            ));
          case LoadCompleteEvent(:final runner):
            _runner = runner;
            _loadedSlug = slug;
            state = ModelDownloadState.ready;
            return Ok(runner);
          case LoadErrorEvent(:final error):
            lastFailureDetail = error;
            state = ModelDownloadState.failed;
            return const Err(LlmError.modelNotLoaded);
          default:
            break;
        }
      }
      lastFailureDetail ??= 'load stream ended without complete';
      state = ModelDownloadState.failed;
      return const Err(LlmError.modelNotLoaded);
    } catch (e) {
      lastFailureDetail = e.toString();
      state = ModelDownloadState.failed;
      if (e.toString().contains('memory') || e.toString().contains('Memory')) {
        return const Err(LlmError.memoryInsufficient);
      }
      return const Err(LlmError.modelNotLoaded);
    }
  }

  ModelRunner? get loadedRunner => _runner;

  /// モデルファイルのみ DL（ロードなし）。§14.5 Wi-Fi ポリシーは [requireWifi] で制御。
  Future<bool> downloadOnly({
    required LlmModelChoice choice,
    void Function(ModelDownloadProgress progress)? onProgress,
    bool requireWifi = true,
  }) async {
    if (choice == LlmModelChoice.off) return false;
    if (requireWifi && !await isWifiConnected()) return false;
    final slug = ModelRegistry.catalogSlug(choice);
    if (slug == null) return false;
    if (await isModelDownloaded(choice)) return true;

    state = ModelDownloadState.downloading;
    try {
      var completed = false;
      await for (final event in _liquidAi.downloadModel(slug, _quantization)) {
        switch (event) {
          case DownloadCompleteEvent():
            completed = true;
          case DownloadErrorEvent(:final error):
            lastFailureDetail = error;
            state = ModelDownloadState.failed;
            return false;
          case DownloadProgressEvent(:final progress):
            onProgress?.call((
              progress: progress.progress,
              bytesPerSecond: progress.speed,
            ));
          default:
            break;
        }
      }
      state = completed
          ? ModelDownloadState.notStarted
          : ModelDownloadState.failed;
      return completed;
    } catch (e) {
      lastFailureDetail = e.toString();
      state = ModelDownloadState.failed;
      return false;
    }
  }

  Future<void> unload() async {
    await _runner?.dispose();
    _runner = null;
    _loadedSlug = null;
    if (state == ModelDownloadState.ready) {
      state = ModelDownloadState.notStarted;
    }
  }
}
