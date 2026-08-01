import 'dart:convert';

import '../../core/result/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/environment.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/entities/user_state.dart';
import 'llm_errors.dart';
import 'schemas/slot_schema.dart';

/// §8.1 LLM 出力 JSON → [SituationSlots] 変換。
class SlotJsonParser {
  const SlotJsonParser();

  Result<SituationSlots, LlmError> parse(String rawJson) {
    try {
      final cleaned = _extractJsonObject(rawJson);
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return Ok(_fromMap(map));
    } catch (_) {
      return const Err(LlmError.parseFailed);
    }
  }

  String _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) throw FormatException('no json');
    return raw.substring(start, end + 1);
  }

  SituationSlots _fromMap(Map<String, dynamic> map) {
    final intent = _enum(
      Intent.values,
      map['intent'] as String?,
      Intent.unknown,
    );
    final disasterType = _disasterType(map['disaster_type'] as String?);
    final evidence = (map['disaster_type_evidence'] as String?) ?? '';
    final urgency = _enum(
      Urgency.values,
      map['urgency'] as String?,
      Urgency.unknown,
    );

    UserState userState = const UserState();
    final userRaw = map['user_state'];
    if (userRaw is Map<String, dynamic>) {
      userState = UserState(
        injured: userRaw['injured'] as bool? ?? false,
        mobility: _enum(
          Mobility.values,
          userRaw['mobility'] as String?,
          Mobility.normal,
        ),
        groupSize: (userRaw['group_size'] as num?)?.toInt() ?? 1,
        hasInfant: userRaw['has_infant'] as bool? ?? false,
        hasPet: userRaw['has_pet'] as bool? ?? false,
      );
    }

    Environment environment = const Environment();
    final envRaw = map['environment'];
    if (envRaw is Map<String, dynamic>) {
      environment = Environment(
        place: _enum(
          PlaceType.values,
          envRaw['place'] as String?,
          PlaceType.unknown,
        ),
        floor: (envRaw['floor'] as num?)?.toInt(),
        buildingType: _enum(
          BuildingType.values,
          envRaw['building_type'] as String?,
          BuildingType.unknown,
        ),
        trapped: envRaw['trapped'] as bool? ?? false,
        waterLevel: _waterLevel(envRaw['water_level'] as String?),
        canMove: envRaw['can_move'] as bool? ?? true,
      );
    }

    final tagsRaw = map['guide_tags'];
    final guideTags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t is String && SlotSchema.allowedGuideTags.contains(t)) {
          guideTags.add(t);
        }
      }
    }

    return SituationSlots(
      intent: intent,
      disasterType: disasterType,
      disasterTypeEvidence: evidence,
      urgency: urgency,
      userState: userState,
      environment: environment,
      guideTags: guideTags,
      source: SlotSource.ai,
    );
  }

  T _enum<T extends Enum>(List<T> values, String? raw, T fallback) {
    if (raw == null) return fallback;
    final normalized = raw.replaceAll('-', '_');
    for (final v in values) {
      if (v.name == normalized || v.name == raw) return v;
    }
    if (raw == 'storm_surge') {
      return values.firstWhere(
        (v) => v.name == 'stormSurge',
        orElse: () => fallback,
      );
    }
    return fallback;
  }

  DisasterType _disasterType(String? raw) {
    if (raw == null) return DisasterType.unknown;
    return switch (raw) {
      'earthquake' => DisasterType.earthquake,
      'tsunami' => DisasterType.tsunami,
      'flood' => DisasterType.flood,
      'landslide' => DisasterType.landslide,
      'storm_surge' => DisasterType.stormSurge,
      'fire' => DisasterType.fire,
      'volcano' => DisasterType.volcano,
      _ => DisasterType.unknown,
    };
  }

  WaterLevel _waterLevel(String? raw) {
    if (raw == null) return WaterLevel.unknown;
    return switch (raw) {
      'none' => WaterLevel.none,
      'ankle' => WaterLevel.ankle,
      'knee' => WaterLevel.knee,
      'waist' => WaterLevel.waist,
      'above_waist' => WaterLevel.aboveWaist,
      _ => WaterLevel.unknown,
    };
  }
}

/// AI-3 リランキング結果 JSON パース。
List<String> parseRerankIds(String raw, List<String> allowed) {
  try {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return [];
    final map =
        jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
    final ids = map['ids'];
    if (ids is! List) return [];
    final allowedSet = allowed.toSet();
    return [
      for (final id in ids)
        if (id is String && allowedSet.contains(id)) id,
    ].take(3).toList();
  } catch (_) {
    return [];
  }
}
