import '../../core/result/result.dart';
import '../../domain/entities/assistant_chat.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import 'llm_errors.dart';

/// §14.4 / §7 LEAP 推論エンジンの抽象化。
abstract interface class LlmEngine {
  /// 利用可能か（モデル DL 済み・ティア適合等）。
  Future<bool> isAvailable();

  /// スロット抽出（AI-2）。§7.2: temperature 0.0, max 200, タイムアウト 5s。
  Future<Result<SituationSlots, LlmError>> extractSlots(String input);

  /// ガイドカード ID リランキング（AI-3）。§7.2: max 32 tokens。
  Future<Result<List<String>, LlmError>> rerankGuideIds({
    required List<String> candidateIds,
    required SituationSlots ctx,
  });

  /// 当てはめ文生成（AI-4）。§7.2: temperature 0.3, max 60。
  Future<Result<String, LlmError>> generatePhrase({
    required GuideCard card,
    required SituationSlots ctx,
  });

  /// AI-7a: アシスタント KB 検索計画。
  Future<Result<AssistantSearchRequest, LlmError>> planAssistantSearch({
    required String userMessage,
    required List<ChatTurn> history,
  });

  /// AI-7b: 検索結果に基づく回答生成。
  Future<Result<AssistantAnswer, LlmError>> generateAssistantAnswer({
    required String userMessage,
    required List<AssistantChunk> chunks,
  });

  /// §7.3: 60 秒非使用後のアンロード。
  Future<void> unload();
}

/// モデル選択（§7.1）。
enum LlmModelChoice { auto, lfm25_1200jp, lfm25_350m, lfm25_230m, off }

/// モデル DL 状態。
enum ModelDownloadState { notStarted, downloading, ready, failed }

/// DL 進捗通知。
typedef ModelDownloadProgress = ({double progress, int? bytesPerSecond});
