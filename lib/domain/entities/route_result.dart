import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/geo/geo_point.dart';

part 'route_result.freezed.dart';

/// §9.3 ターンバイターン指示の種別。
enum TurnKind {
  depart,
  goStraight,
  slightRight,
  slightLeft,
  turnRight,
  turnLeft,
  uturn,
  arrive,
}

/// 1 ステップ分の案内指示（機械生成テンプレート。LLM 不使用）。
@freezed
abstract class TurnInstruction with _$TurnInstruction {
  const factory TurnInstruction({
    required TurnKind kind,

    /// 直進系指示での距離 [m]。
    @Default(0) double distanceM,

    /// §9.3: 曲がり角のランドマーク（あれば文言に使う）
    String? landmarkName,

    /// 表示・読み上げ用テキスト（例: "300m 直進", "〇〇神社を右折"）
    required String text,
  }) = _TurnInstruction;
}

/// §9.1 出力: 避難先への経路（§14.4 RouteEngine の戻り値）。
@freezed
abstract class RouteResult with _$RouteResult {
  const factory RouteResult({
    /// 避難所 ID（Shelter.id）
    required String targetId,

    /// §9.2 コスト式による到達コスト [秒]
    required double costSeconds,
    required double distanceM,

    /// 経路ポリライン（開始地点→避難所、向き済み）
    @Default(<GeoPoint>[]) List<GeoPoint> polyline,
    @Default(<TurnInstruction>[]) List<TurnInstruction> instructions,
  }) = _RouteResult;
}
