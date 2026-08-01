import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/enums.dart';

/// assets/dict/keywords.json の読み込み結果。
class KeywordDictionary {
  const KeywordDictionary({
    required this.disasterTypes,
    required this.intents,
    required this.mobility,
    required this.urgency,
  });

  final Map<DisasterType, List<String>> disasterTypes;
  final Map<Intent, List<String>> intents;
  final Map<Mobility, List<String>> mobility;
  final Map<Urgency, List<String>> urgency;

  static const assetPath = 'assets/dict/keywords.json';

  static Future<KeywordDictionary> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return KeywordDictionary._fromJson(json);
  }

  factory KeywordDictionary._fromJson(Map<String, dynamic> json) {
    DisasterType parseType(String key) => DisasterType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => DisasterType.unknown,
    );
    Intent parseIntent(String key) => Intent.values.firstWhere(
      (e) => e.name == key,
      orElse: () => Intent.unknown,
    );
    Mobility parseMobility(String key) => Mobility.values.firstWhere(
      (e) => e.name == key,
      orElse: () => Mobility.unknown,
    );
    Urgency parseUrgency(String key) => Urgency.values.firstWhere(
      (e) => e.name == key,
      orElse: () => Urgency.unknown,
    );

    List<String> words(dynamic v) =>
        (v as List<dynamic>).map((e) => e.toString()).toList();

    final types = <DisasterType, List<String>>{};
    for (final e in (json['disasterTypes'] as Map<String, dynamic>).entries) {
      final t = parseType(e.key);
      if (t != DisasterType.unknown) types[t] = words(e.value);
    }
    final intents = <Intent, List<String>>{};
    for (final e in (json['intents'] as Map<String, dynamic>).entries) {
      final i = parseIntent(e.key);
      if (i != Intent.unknown) intents[i] = words(e.value);
    }
    final mobility = <Mobility, List<String>>{};
    for (final e in (json['mobility'] as Map<String, dynamic>).entries) {
      final m = parseMobility(e.key);
      if (m != Mobility.unknown) mobility[m] = words(e.value);
    }
    final urgency = <Urgency, List<String>>{};
    for (final e in (json['urgency'] as Map<String, dynamic>).entries) {
      final u = parseUrgency(e.key);
      if (u != Urgency.unknown) urgency[u] = words(e.value);
    }
    return KeywordDictionary(
      disasterTypes: types,
      intents: intents,
      mobility: mobility,
      urgency: urgency,
    );
  }
}
