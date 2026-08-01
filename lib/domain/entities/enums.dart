/// ドメイン列挙型（要件定義書 §8.1 / §14 準拠）
library;

/// 災害種別（§3.2 / §8.1）
enum DisasterType {
  earthquake,
  tsunami,
  flood,
  landslide,
  stormSurge,
  fire,
  volcano,
  unknown,
}

/// 意図（§8.1）
enum Intent { route, guide, both, unknown }

/// 緊急度（§8.1）
enum Urgency { immediate, soon, prepare, unknown }

/// 移動能力（§8.1 / §9.2）
enum Mobility { normal, slow, assisted, wheelchair, stretcher, unknown }

/// 場所（§8.1）
enum PlaceType { indoor, outdoor, vehicle, underground, unknown }

/// 建物構造（§8.1）
enum BuildingType { rc, steel, wood, unknown }

/// 水位（§8.1）
enum WaterLevel { none, ankle, knee, waist, aboveWaist, unknown }

/// 避難所の場所クラス（§14.1 place_class）
/// 0: 不明/建物 1: 広域空地 2: 津波避難ビル・タワー
enum PlaceClass {
  unknownOrBuilding(0),
  openSpace(1),
  tsunamiBuilding(2);

  const PlaceClass(this.code);
  final int code;
}

/// スロットの入力由来（§14.4）
enum SlotSource { tile, ai, rule, manual }

/// 避難モード判定結果（§4.3）
enum EvacuationMode {
  /// 水平避難（経路案内）
  horizontal,

  /// 垂直避難を推奨（ガイドカード主表示。経路案内を主表示にしてはならない）
  verticalRecommended,

  /// 階数不明のため選択肢として併記（断定しない）
  verticalOptional,

  /// 浸水想定域外: その場に留まる or 状況により水平避難
  stayOrHorizontal,
}

/// 経路コスト上のハザード属性の種類（§9.2）
enum HazardEdgeKind {
  none,
  flood,
  tsunami,
  landslide,
  stormSurge,
  volcano,
  any,
}
