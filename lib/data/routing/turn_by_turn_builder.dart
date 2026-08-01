import '../../core/geo/geo.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/route_result.dart';

/// 経路の 1 エッジ分の形状（走行向きに整列済み）。
class PathLeg {
  const PathLeg({required this.points, this.landmarkName});

  /// 走行向きの折れ線（2 点以上）。
  final List<GeoPoint> points;

  /// このレッグへ曲がるときのランドマーク（§9.3）
  final String? landmarkName;
}

/// §9.3: 連続エッジの方位差からターンバイターンを機械生成する（LLM 不使用、MUST）。
///
/// 分類: |Δθ| < 20° → 直進（統合）／ 20–60° → 斜め右左 ／
/// 60–135° → 右左折 ／ ≥135° → 引き返す
class TurnByTurnBuilder {
  List<TurnInstruction> build(List<PathLeg> legs) {
    if (legs.isEmpty) return const [];
    final instructions = <TurnInstruction>[
      const TurnInstruction(kind: TurnKind.depart, text: '出発'),
    ];

    var straightM = 0.0;
    for (var i = 0; i < legs.length; i++) {
      straightM += _legLengthM(legs[i]);
      if (i + 1 >= legs.length) break;

      final inBearing = _outBearing(legs[i]);
      final outBearing = _inBearing(legs[i + 1]);
      if (inBearing == null || outBearing == null) continue;
      final delta = normalizeTurnDeg(outBearing - inBearing);
      final abs = delta.abs();

      if (abs < 20) continue; // 直進に統合（§9.3）

      _flushStraight(instructions, straightM);
      straightM = 0;
      final landmark = legs[i + 1].landmarkName;
      if (abs >= 135) {
        instructions.add(
          const TurnInstruction(kind: TurnKind.uturn, text: '引き返す'),
        );
      } else if (abs >= 60) {
        final right = delta > 0;
        instructions.add(
          TurnInstruction(
            kind: right ? TurnKind.turnRight : TurnKind.turnLeft,
            landmarkName: landmark,
            text: landmark != null
                ? '$landmarkを${right ? '右折' : '左折'}'
                : (right ? '右折' : '左折'),
          ),
        );
      } else {
        final right = delta > 0;
        instructions.add(
          TurnInstruction(
            kind: right ? TurnKind.slightRight : TurnKind.slightLeft,
            landmarkName: landmark,
            text: right ? '斜め右' : '斜め左',
          ),
        );
      }
    }

    _flushStraight(instructions, straightM);
    instructions.add(const TurnInstruction(kind: TurnKind.arrive, text: '到着'));
    return instructions;
  }

  void _flushStraight(List<TurnInstruction> out, double distanceM) {
    if (distanceM < 1) return;
    final rounded = distanceM.round();
    out.add(
      TurnInstruction(
        kind: TurnKind.goStraight,
        distanceM: distanceM,
        text: '${rounded}m 直進',
      ),
    );
  }

  double _legLengthM(PathLeg leg) {
    var sum = 0.0;
    for (var i = 0; i + 1 < leg.points.length; i++) {
      sum += haversineM(leg.points[i], leg.points[i + 1]);
    }
    return sum;
  }

  /// レッグ終端の進行方位（最終セグメント）。
  double? _outBearing(PathLeg leg) {
    final p = leg.points;
    if (p.length < 2) return null;
    return bearingDeg(p[p.length - 2], p[p.length - 1]);
  }

  /// レッグ始端の進行方位（最初のセグメント）。
  double? _inBearing(PathLeg leg) {
    final p = leg.points;
    if (p.length < 2) return null;
    return bearingDeg(p[0], p[1]);
  }
}
