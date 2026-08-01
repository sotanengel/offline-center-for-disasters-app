import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'environment.freezed.dart';

/// 環境（§8.1 environment）
@freezed
abstract class Environment with _$Environment {
  const factory Environment({
    @Default(PlaceType.unknown) PlaceType place,
    int? floor,
    @Default(BuildingType.unknown) BuildingType buildingType,
    @Default(false) bool trapped,
    @Default(WaterLevel.unknown) WaterLevel waterLevel,
    @Default(true) bool canMove,
  }) = _Environment;
}
