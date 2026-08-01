import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/core/geo/route_progress.dart';
import 'package:offline_center_for_disasters/domain/entities/route_result.dart';

void main() {
  const a = GeoPoint(35.0, 139.0);
  const b = GeoPoint(35.001, 139.0);
  const c = GeoPoint(35.002, 139.0);
  final polyline = [a, b, c];

  test('remainingDistanceM: 始点では経路全長に近い', () {
    final remaining = remainingDistanceM(a, polyline);
    final total =
        remainingDistanceM(a, polyline) + traveledDistanceM(a, polyline);
    expect(total, greaterThan(0));
    expect(remaining, closeTo(total, 1));
  });

  test('remainingDistanceM: 終点付近では 0 に近づく', () {
    final remaining = remainingDistanceM(c, polyline);
    expect(remaining, lessThan(1));
  });

  test('activeInstruction: 走行距離に応じて指示が進む', () {
    const instructions = [
      TurnInstruction(kind: TurnKind.depart, text: '出発'),
      TurnInstruction(
        kind: TurnKind.goStraight,
        distanceM: 100,
        text: '100m 直進',
      ),
      TurnInstruction(kind: TurnKind.turnRight, distanceM: 0, text: '右折'),
      TurnInstruction(kind: TurnKind.arrive, text: '到着'),
    ];
    expect(activeInstruction(instructions, 0)?.text, '出発');
    expect(activeInstruction(instructions, 50)?.text, '100m 直進');
    expect(activeInstruction(instructions, 150)?.text, '到着');
  });
}
