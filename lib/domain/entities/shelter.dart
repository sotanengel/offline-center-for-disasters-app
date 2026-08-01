import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'shelter.freezed.dart';

/// 避難所（§14.1 shelters テーブルに対応）
@freezed
abstract class Shelter with _$Shelter {
  const factory Shelter({
    required String id,
    required String name,
    required double lat,
    required double lng,
    double? elevationM,
    @Default(false) bool okFlood,
    @Default(false) bool okLandslide,
    @Default(false) bool okStormSurge,
    @Default(false) bool okEarthquake,
    @Default(false) bool okTsunami,
    @Default(false) bool okFire,
    @Default(false) bool okInlandFlood,
    @Default(false) bool okVolcano,
    @Default(false) bool isAllHazard,
    @Default(PlaceClass.unknownOrBuilding) PlaceClass placeClass,
    double? usableFloorHeightM,
    @Default(false) bool isShelter,
    @Default(false) bool barrierFree,
    int? capacity,
    String? note,
  }) = _Shelter;
}
