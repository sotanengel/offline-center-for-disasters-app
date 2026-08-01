import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter.dart';
import 'package:offline_center_for_disasters/domain/policies/tsunami_elevation_rule.dart';

/// §4.2 津波避難の高さ判定（決定論、MUST）
void main() {
  const rule = TsunamiElevationRule();

  Shelter shelter({
    double elevationM = 0,
    PlaceClass placeClass = PlaceClass.unknownOrBuilding,
    double? usableFloorHeightM,
  }) {
    return Shelter(
      id: 'S',
      name: 'S',
      lat: 35.0,
      lng: 139.0,
      elevationM: elevationM,
      okTsunami: true,
      placeClass: placeClass,
      usableFloorHeightM: usableFloorHeightM,
    );
  }

  test('required_elevation_m = 想定浸水深 + 5.0', () {
    const ctx = HazardContext(inTsunamiZone: true, tsunamiDepthM: 3.0);
    expect(rule.requiredElevationM(ctx), 8.0);
  });

  test('想定区域外（depth 0）でも 5.0m を要求', () {
    const ctx = HazardContext();
    expect(rule.requiredElevationM(ctx), 5.0);
  });

  test('標高が required 以上 → 有効', () {
    expect(rule.isValidCandidate(shelter(elevationM: 8.0), 8.0), isTrue);
    expect(rule.isValidCandidate(shelter(elevationM: 7.99), 8.0), isFalse);
  });

  test('津波避難ビルは usable_floor_height_m で判定', () {
    final bld = shelter(
      elevationM: 1.0,
      placeClass: PlaceClass.tsunamiBuilding,
      usableFloorHeightM: 10.0,
    );
    expect(rule.isValidCandidate(bld, 8.0), isTrue);
    expect(
      rule.isValidCandidate(
        shelter(
          elevationM: 1.0,
          placeClass: PlaceClass.tsunamiBuilding,
          usableFloorHeightM: 6.0,
        ),
        8.0,
      ),
      isFalse,
    );
  });

  test('津波避難ビルでなければ標高のみで判定', () {
    expect(
      rule.isValidCandidate(
        shelter(elevationM: 6.0, usableFloorHeightM: 30.0),
        8.0,
      ),
      isFalse,
    );
  });
}
