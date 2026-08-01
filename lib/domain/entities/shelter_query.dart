import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'hazard_context.dart';
import 'shelter.dart';

part 'shelter_query.freezed.dart';

/// §4.1 決定表から生成される探索条件。
/// [matches] は避難所属性 + 避難所所在地のハザードコンテキストで判定する純粋関数。
@freezed
abstract class ShelterQuery with _$ShelterQuery {
  const factory ShelterQuery({
    required DisasterType disasterType,

    /// 津波: 想定浸水深 + 5m（§4.2 required_elevation_m）
    @Default(0) double minElevationM,

    /// 初期探索半径 [km]（§4.4 / Q10: 0 件なら 20km に拡大）
    @Default(10.0) double radiusKm,
  }) = _ShelterQuery;

  const ShelterQuery._();

  /// §4.1 決定表の「必須フラグ + 追加の必須条件」を適用する。
  ///
  /// [atShelter] は避難所所在地のハザードコンテキスト（グリッド 1 行）。
  /// データが無い地点は区域外（既定値）として扱う。
  bool matches(Shelter shelter, HazardContext atShelter) {
    switch (disasterType) {
      case DisasterType.tsunami:
        if (!shelter.okTsunami) return false;
        final elevOk =
            (shelter.elevationM ?? double.negativeInfinity) >= minElevationM;
        final towerOk =
            shelter.placeClass == PlaceClass.tsunamiBuilding &&
            (shelter.usableFloorHeightM ?? 0) >= minElevationM;
        return elevOk || towerOk;
      case DisasterType.flood:
        if (!shelter.okFlood) return false;
        if (!atShelter.inFloodZone) return true;
        // 想定浸水深に対し十分な階数（§4.3 の 1 層 3m 概算に倣い +3m）
        final floorHeight = shelter.usableFloorHeightM;
        return floorHeight != null &&
            floorHeight >= atShelter.floodDepthM + 3.0;
      case DisasterType.landslide:
        // 警戒区域外（特別警戒区域は絶対除外）
        return shelter.okLandslide && atShelter.landslideClass == 0;
      case DisasterType.stormSurge:
        if (!shelter.okStormSurge) return false;
        if (!atShelter.inStormSurgeZone) return true;
        final floorHeight = shelter.usableFloorHeightM;
        return floorHeight != null &&
            floorHeight >= atShelter.stormSurgeM + 3.0;
      case DisasterType.earthquake:
        // 広い空地のみ。建物内へは誘導しない（MUST）
        return shelter.okEarthquake &&
            shelter.placeClass == PlaceClass.openSpace;
      case DisasterType.fire:
        // 広域避難場所（大規模空地）
        return shelter.okFire && shelter.placeClass == PlaceClass.openSpace;
      case DisasterType.volcano:
        return shelter.okVolcano;
      case DisasterType.unknown:
        // §3.6: オールハザード避難場所のみ
        return shelter.isAllHazard;
    }
  }
}
