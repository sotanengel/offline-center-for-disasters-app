import 'dart:async';

import 'package:liquid_ai/liquid_ai.dart';

import '../../core/result/result.dart';
import '../../domain/entities/assistant_chat.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import 'assistant_json_parser.dart';
import 'device_tier_service.dart';
import 'llm_engine.dart';
import 'llm_errors.dart';
import 'model_downloader.dart';
import 'prompts/assistant_chat_prompt.dart';
import 'prompts/slot_extraction_prompt.dart';
import 'schemas/slot_schema.dart';
import 'slot_json_parser.dart';

/// LEAP SDK 実装（§7 / P5-P6）。
class LeapLlmEngine implements LlmEngine {
  LeapLlmEngine({
    required ModelDownloader downloader,
    required DeviceTierService tierService,
    required LlmModelChoice userChoice,
    SlotJsonParser? parser,
    AssistantJsonParser? assistantParser,
    Duration inferenceTimeout = const Duration(seconds: 5),
    Duration idleUnload = const Duration(seconds: 60),
  }) : _downloader = downloader,
       _tierService = tierService,
       _userChoice = userChoice,
       _parser = parser ?? const SlotJsonParser(),
       _assistantParser = assistantParser ?? const AssistantJsonParser(),
       _inferenceTimeout = inferenceTimeout,
       _idleUnload = idleUnload;

  final ModelDownloader _downloader;
  final DeviceTierService _tierService;
  final LlmModelChoice _userChoice;
  final SlotJsonParser _parser;
  final AssistantJsonParser _assistantParser;
  final Duration _inferenceTimeout;
  final Duration _idleUnload;

  Conversation? _conversation;
  Timer? _unloadTimer;
  LlmModelChoice? _effectiveChoice;

  @override
  Future<bool> isAvailable() async {
    if (_userChoice == LlmModelChoice.off) return false;
    _effectiveChoice ??= await _tierService.resolveEffectiveChoice(_userChoice);
    if (_effectiveChoice == LlmModelChoice.off) return false;
    try {
      return await _downloader.isModelDownloaded(_effectiveChoice!) ||
          _downloader.loadedRunner != null;
    } catch (_) {
      return false;
    }
  }

  Future<Result<Conversation, LlmError>> _ensureConversation({
    required String systemPrompt,
  }) async {
    _resetUnloadTimer();
    _effectiveChoice ??= await _tierService.resolveEffectiveChoice(_userChoice);
    if (_effectiveChoice == LlmModelChoice.off) {
      return const Err(LlmError.unavailable);
    }

    if (_conversation != null) return Ok(_conversation!);

    var choice = _effectiveChoice!;
    for (var attempt = 0; attempt < 2; attempt++) {
      final loadResult = await _downloader.downloadAndLoad(
        choice: choice,
        requireWifi: false,
      );
      if (loadResult is Ok<ModelRunner, LlmError>) {
        try {
          _conversation = await loadResult.value.createConversation(
            systemPrompt: systemPrompt,
          );
          return Ok(_conversation!);
        } catch (e) {
          if (attempt == 0 &&
              (e.toString().contains('memory') ||
                  e.toString().contains('Memory'))) {
            choice = _tierService.downgrade(choice);
            _effectiveChoice = choice;
            continue;
          }
          return const Err(LlmError.modelNotLoaded);
        }
      }
      if (loadResult case Err(error: LlmError.memoryInsufficient)) {
        if (attempt == 0) {
          choice = _tierService.downgrade(choice);
          _effectiveChoice = choice;
          continue;
        }
      }
      if (loadResult is Err<ModelRunner, LlmError>) {
        return Err(loadResult.error);
      }
    }
    return const Err(LlmError.modelNotLoaded);
  }

  @override
  Future<Result<SituationSlots, LlmError>> extractSlots(String input) async {
    final convResult = await _ensureConversation(
      systemPrompt:
          '$slotExtractionSystemPrompt\n\n${SlotSchema.jsonInstruction}',
    );
    if (convResult is Err<Conversation, LlmError>) {
      return Err(convResult.error);
    }
    final conversation = (convResult as Ok<Conversation, LlmError>).value;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final raw = await conversation
            .generateText(
              '入力: $input',
              options: const GenerationOptions(
                temperature: 0.0,
                maxTokens: 200,
              ),
            )
            .timeout(_inferenceTimeout);
        final parsed = _parser.parse(raw);
        if (parsed is Ok<SituationSlots, LlmError>) return parsed;
      } on TimeoutException {
        return const Err(LlmError.timeout);
      } catch (_) {
        if (attempt == 1) return const Err(LlmError.parseFailed);
      }
    }
    return const Err(LlmError.parseFailed);
  }

  @override
  Future<Result<List<String>, LlmError>> rerankGuideIds({
    required List<String> candidateIds,
    required SituationSlots ctx,
  }) async {
    if (candidateIds.isEmpty) {
      return const Ok([]);
    }
    final limited = candidateIds.take(8).toList();
    final convResult = await _ensureConversation(
      systemPrompt: guideRerankSystemPrompt(limited),
    );
    if (convResult is Err<Conversation, LlmError>) {
      return Err(convResult.error);
    }
    final conversation = (convResult as Ok<Conversation, LlmError>).value;

    try {
      final raw = await conversation
          .generateText(
            '状況: ${ctx.disasterType.name}, tags=${ctx.guideTags.join(",")}',
            options: const GenerationOptions(temperature: 0.0, maxTokens: 32),
          )
          .timeout(_inferenceTimeout);
      final ids = parseRerankIds(raw, limited);
      if (ids.isEmpty) return const Err(LlmError.parseFailed);
      return Ok(ids);
    } on TimeoutException {
      return const Err(LlmError.timeout);
    } catch (_) {
      return const Err(LlmError.parseFailed);
    }
  }

  @override
  Future<Result<String, LlmError>> generatePhrase({
    required GuideCard card,
    required SituationSlots ctx,
  }) async {
    final convResult = await _ensureConversation(
      systemPrompt: phraseGenerationSystemPrompt,
    );
    if (convResult is Err<Conversation, LlmError>) {
      return Err(convResult.error);
    }
    final conversation = (convResult as Ok<Conversation, LlmError>).value;

    try {
      final raw = await conversation
          .generateText(
            'カード: ${card.title}\n状況: floor=${ctx.environment.floor}, '
            'mobility=${ctx.userState.mobility.name}',
            options: const GenerationOptions(temperature: 0.3, maxTokens: 60),
          )
          .timeout(const Duration(seconds: 3));
      return Ok(raw.trim());
    } on TimeoutException {
      return const Err(LlmError.timeout);
    } catch (_) {
      return const Err(LlmError.parseFailed);
    }
  }

  @override
  Future<Result<AssistantSearchRequest, LlmError>> planAssistantSearch({
    required String userMessage,
    required List<ChatTurn> history,
  }) async {
    final convResult = await _ensureConversation(
      systemPrompt: assistantSearchPlanPrompt,
    );
    if (convResult is Err<Conversation, LlmError>) {
      return Err(convResult.error);
    }
    final conversation = (convResult as Ok<Conversation, LlmError>).value;
    try {
      final raw = await conversation
          .generateText(
            '質問: $userMessage',
            options: const GenerationOptions(temperature: 0.0, maxTokens: 64),
          )
          .timeout(_inferenceTimeout);
      return _assistantParser.parseSearchPlan(raw);
    } on TimeoutException {
      return const Err(LlmError.timeout);
    } catch (_) {
      return const Err(LlmError.parseFailed);
    }
  }

  @override
  Future<Result<AssistantAnswer, LlmError>> generateAssistantAnswer({
    required String userMessage,
    required List<AssistantChunk> chunks,
  }) async {
    if (chunks.isEmpty) return const Err(LlmError.parseFailed);
    final ids = chunks.map((c) => c.id).toList();
    final context = chunks
        .map((c) => '[${c.id}] ${c.title}\n${c.content}')
        .join('\n\n');
    final convResult = await _ensureConversation(
      systemPrompt: assistantAnswerPrompt(ids),
    );
    if (convResult is Err<Conversation, LlmError>) {
      return Err(convResult.error);
    }
    final conversation = (convResult as Ok<Conversation, LlmError>).value;
    try {
      final raw = await conversation
          .generateText(
            '質問: $userMessage\n\n資料:\n$context',
            options: const GenerationOptions(temperature: 0.2, maxTokens: 300),
          )
          .timeout(const Duration(seconds: 8));
      return _assistantParser.parseAnswer(raw);
    } on TimeoutException {
      return const Err(LlmError.timeout);
    } catch (_) {
      return const Err(LlmError.parseFailed);
    }
  }

  void _resetUnloadTimer() {
    _unloadTimer?.cancel();
    _unloadTimer = Timer(_idleUnload, () {
      unawaited(unload());
    });
  }

  @override
  Future<void> unload() async {
    _unloadTimer?.cancel();
    _unloadTimer = null;
    await _conversation?.dispose();
    _conversation = null;
    await _downloader.unload();
  }
}
