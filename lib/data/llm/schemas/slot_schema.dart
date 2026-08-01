/// §8.1 スロット抽出 JSON Schema（検証・プロンプト参照用）。
class SlotSchema {
  static const allowedGuideTags = [
    'tsunami_evacuation',
    'vertical_evacuation',
    'flood_walking',
    'landslide_sign',
    'trapped_elevator',
    'trapped_debris',
    'fire_smoke',
    'injury_bleeding',
    'injury_fracture',
    'aftershock',
    'blackout',
    'water_supply',
    'toilet',
    'infant_care',
    'pet_care',
    'cold_protection',
    'wheelchair_evacuation',
    'night_evacuation',
    'underground_evacuation',
  ];

  static const allowedIntents = ['route', 'guide', 'both', 'unknown'];

  static const allowedDisasterTypes = [
    'earthquake',
    'tsunami',
    'flood',
    'landslide',
    'storm_surge',
    'fire',
    'volcano',
    'unknown',
  ];

  static const allowedUrgency = ['immediate', 'soon', 'prepare', 'unknown'];

  static const allowedMobility = [
    'normal',
    'slow',
    'assisted',
    'wheelchair',
    'stretcher',
    'unknown',
  ];

  static const allowedPlace = [
    'indoor',
    'outdoor',
    'vehicle',
    'underground',
    'unknown',
  ];

  static const allowedBuildingType = ['rc', 'steel', 'wood', 'unknown'];

  static const allowedWaterLevel = [
    'none',
    'ankle',
    'knee',
    'waist',
    'above_waist',
    'unknown',
  ];

  /// LLM への JSON 出力指示（§8.1 準拠）。
  static String get jsonInstruction =>
      '''
{
  "type": "object",
  "required": ["intent", "urgency"],
  "properties": {
    "intent": {"enum": $allowedIntents},
    "disaster_type": {"enum": $allowedDisasterTypes},
    "disaster_type_evidence": {"type": "string"},
    "urgency": {"enum": $allowedUrgency},
    "user_state": {
      "type": "object",
      "properties": {
        "injured": {"type": "boolean"},
        "mobility": {"enum": $allowedMobility},
        "group_size": {"type": "integer", "minimum": 1, "maximum": 20},
        "has_infant": {"type": "boolean"},
        "has_pet": {"type": "boolean"}
      }
    },
    "environment": {
      "type": "object",
      "properties": {
        "place": {"enum": $allowedPlace},
        "floor": {"type": "integer", "minimum": -5, "maximum": 60},
        "building_type": {"enum": $allowedBuildingType},
        "trapped": {"type": "boolean"},
        "water_level": {"enum": $allowedWaterLevel},
        "can_move": {"type": "boolean"}
      }
    },
    "guide_tags": {
      "type": "array",
      "items": {"type": "string"},
      "maxItems": 5
    }
  }
}
''';
}
