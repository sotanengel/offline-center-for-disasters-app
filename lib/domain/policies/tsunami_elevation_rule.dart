import '../entities/enums.dart';
import '../entities/hazard_context.dart';
import '../entities/shelter.dart';

/// §4.2 津波避難の高さ判定（決定論、MUST）
///
/// required_elevation_m = 想定浸水深(現在地の想定区域値) + 5.0（安全マージン）
/// 候補が有効 = (標高 >= required) OR (津波避難ビル AND 利用階高さ >= required)
class TsunamiElevationRule {
  const TsunamiElevationRule();

  static const double safetyMarginM = 5.0;

  double requiredElevationM(HazardContext ctx) {
    return ctx.tsunamiDepthM + safetyMarginM;
  }

  bool isValidCandidate(Shelter shelter, double requiredElevationM) {
    final elevationOk =
        (shelter.elevationM ?? double.negativeInfinity) >= requiredElevationM;
    final towerOk =
        shelter.placeClass == PlaceClass.tsunamiBuilding &&
        (shelter.usableFloorHeightM ?? 0) >= requiredElevationM;
    return elevationOk || towerOk;
  }
}
