import '../../core/geo/geo_point.dart';

/// §14.2 edges.way_type（0:footway 1:residential 2:primary 3:steps 4:underpass 5:crossing）
enum WayType {
  footway(0),
  residential(1),
  primary(2),
  steps(3),
  underpass(4),
  crossing(5);

  const WayType(this.code);
  final int code;

  static WayType fromCode(int? code) => WayType.values.firstWhere(
    (t) => t.code == code,
    orElse: () => WayType.residential,
  );
}

/// §14.2 edges.width_class（0:unknown 1:<1.5m 2:1.5-4m 3:>4m）
enum WidthClass {
  unknown(0),
  narrow(1),
  medium(2),
  wide(3);

  const WidthClass(this.code);
  final int code;

  static WidthClass fromCode(int? code) => WidthClass.values.firstWhere(
    (c) => c.code == code,
    orElse: () => WidthClass.unknown,
  );
}

/// §14.2 edges テーブルの 1 行。徒歩のため双方向（oneway はパック側で無視済み）。
class GraphEdge {
  const GraphEdge({
    required this.id,
    required this.fromNode,
    required this.toNode,
    required this.lengthM,
    this.geometry,
    this.wayType = WayType.residential,
    this.widthClass = WidthClass.unknown,
    this.hasSteps = 0,
    this.isLit = 0,
    this.hzFloodDepth = 0,
    this.hzTsunamiDepth = 0,
    this.hzLandslide = 0,
    this.hzStormSurge = 0,
    this.hzVolcano = 0,
    this.nearRiver = 0,
    this.denseWood = 0,
    this.landmarkName,
  });

  final int id;
  final int fromNode;
  final int toNode;
  final double lengthM;

  /// 復号済みの中間形状（from→to 向き）。null なら端点間の直線として扱う。
  final List<GeoPoint>? geometry;
  final WayType wayType;
  final WidthClass widthClass;
  final int hasSteps;
  final int isLit;

  /// 事前計算済みハザード属性（§9.2 MUST: 実行時ポリゴン演算禁止）
  final int hzFloodDepth;
  final int hzTsunamiDepth;
  final int hzLandslide;
  final int hzStormSurge;
  final int hzVolcano;
  final int nearRiver;
  final int denseWood;

  /// §9.3: 曲がり角文言用の最寄りランドマーク（半径 30m 以内、パック側で選定済み）
  final String? landmarkName;

  bool get isSteps => wayType == WayType.steps || hasSteps != 0;

  /// [nodeId] 側から進入したときの反対側ノード。
  int otherEnd(int nodeId) => nodeId == fromNode ? toNode : fromNode;

  /// [nodeId] 側から走行した向きに形状を返す。
  List<GeoPoint>? geometryFrom(int nodeId) {
    final g = geometry;
    if (g == null) return null;
    return nodeId == fromNode ? g : g.reversed.toList();
  }
}
