import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'environment.dart';
import 'user_state.dart';

part 'situation_slots.freezed.dart';

/// 状況スロット（§14.4 / §8.1 準拠）
@freezed
abstract class SituationSlots with _$SituationSlots {
  const factory SituationSlots({
    @Default(Intent.unknown) Intent intent,
    @Default(DisasterType.unknown) DisasterType disasterType,

    /// 災害種別の根拠語句。空文字ならユーザー確認が必須（§3.7）
    @Default('') String disasterTypeEvidence,
    @Default(Urgency.unknown) Urgency urgency,
    @Default(UserState()) UserState userState,
    @Default(Environment()) Environment environment,
    @Default(<String>[]) List<String> guideTags,

    /// tile / ai / rule / manual
    @Default(SlotSource.tile) SlotSource source,
  }) = _SituationSlots;

  const SituationSlots._();

  bool get needsDisasterTypeConfirmation =>
      disasterType != DisasterType.unknown &&
      source == SlotSource.ai &&
      disasterTypeEvidence.isEmpty;
}
