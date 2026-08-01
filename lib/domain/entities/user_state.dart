import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'user_state.freezed.dart';

/// 利用者状態（§8.1 user_state）
@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    @Default(false) bool injured,
    @Default(Mobility.normal) Mobility mobility,
    @Default(1) int groupSize,
    @Default(false) bool hasInfant,
    @Default(false) bool hasPet,
  }) = _UserState;
}
