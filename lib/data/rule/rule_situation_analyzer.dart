import 'package:flutter/foundation.dart' show FlutterError;

import '../../core/result/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/entities/user_state.dart';
import '../../domain/services/situation_analyzer.dart';
import 'keyword_dictionary.dart';

/// §8.3 キーワード辞書ベースの [SituationAnalyzer] 実装（PR-9 / F-02）。
class RuleSituationAnalyzer implements SituationAnalyzer {
  RuleSituationAnalyzer(this._dict);

  final KeywordDictionary _dict;

  static Future<RuleSituationAnalyzer> create() async {
    final dict = await KeywordDictionary.load();
    return RuleSituationAnalyzer(dict);
  }

  @override
  Future<Result<SituationSlots, SituationAnalyzerError>> analyze(
    String rawInput,
  ) async {
    final text = rawInput.trim();
    if (text.isEmpty) {
      return const Err(SituationAnalyzerError.empty);
    }
    final normalized = text.toLowerCase();

    final disaster = _matchDisaster(normalized, text);
    final intent = _matchIntent(normalized);
    final mobility = _matchMobility(normalized);
    final urgency = _matchUrgency(normalized);

    final tags = <String>[];
    if (disaster.evidence.isNotEmpty) tags.add(disaster.evidence);

    return Ok(
      SituationSlots(
        intent: intent,
        disasterType: disaster.type,
        disasterTypeEvidence: disaster.evidence,
        urgency: urgency,
        userState: UserState(mobility: mobility),
        guideTags: tags,
        source: SlotSource.rule,
      ),
    );
  }

  ({DisasterType type, String evidence}) _matchDisaster(
    String normalized,
    String original,
  ) {
    DisasterType? bestType;
    String bestEvidence = '';
    var bestLen = 0;
    for (final entry in _dict.disasterTypes.entries) {
      for (final word in entry.value) {
        final w = word.toLowerCase();
        if (normalized.contains(w) && word.length > bestLen) {
          bestLen = word.length;
          bestType = entry.key;
          bestEvidence = _extractEvidence(original, word);
        }
      }
    }
    return (type: bestType ?? DisasterType.unknown, evidence: bestEvidence);
  }

  String _extractEvidence(String original, String keyword) {
    final lower = original.toLowerCase();
    final idx = lower.indexOf(keyword.toLowerCase());
    if (idx < 0) return keyword;
    return original.substring(idx, idx + keyword.length);
  }

  Intent _matchIntent(String normalized) {
    Intent? best;
    var bestLen = 0;
    for (final entry in _dict.intents.entries) {
      for (final word in entry.value) {
        final w = word.toLowerCase();
        if (normalized.contains(w) && word.length > bestLen) {
          bestLen = word.length;
          best = entry.key;
        }
      }
    }
    return best ?? Intent.unknown;
  }

  Mobility _matchMobility(String normalized) {
    Mobility? best;
    var bestLen = 0;
    for (final entry in _dict.mobility.entries) {
      for (final word in entry.value) {
        final w = word.toLowerCase();
        if (normalized.contains(w) && word.length > bestLen) {
          bestLen = word.length;
          best = entry.key;
        }
      }
    }
    return best ?? Mobility.normal;
  }

  Urgency _matchUrgency(String normalized) {
    Urgency? best;
    var bestLen = 0;
    for (final entry in _dict.urgency.entries) {
      for (final word in entry.value) {
        final w = word.toLowerCase();
        if (normalized.contains(w) && word.length > bestLen) {
          bestLen = word.length;
          best = entry.key;
        }
      }
    }
    return best ?? Urgency.unknown;
  }
}

/// 辞書読込失敗時に [SituationAnalyzerError.dictionaryMissing] を返すラッパ。
class RuleSituationAnalyzerLoader implements SituationAnalyzer {
  RuleSituationAnalyzer? _inner;

  @override
  Future<Result<SituationSlots, SituationAnalyzerError>> analyze(
    String rawInput,
  ) async {
    try {
      _inner ??= await RuleSituationAnalyzer.create();
      return _inner!.analyze(rawInput);
    } on FlutterError {
      return const Err(SituationAnalyzerError.dictionaryMissing);
    } catch (_) {
      return const Err(SituationAnalyzerError.unavailable);
    }
  }
}
