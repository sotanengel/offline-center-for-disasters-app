import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'hazard_context.dart';

part 'disaster_candidate.freezed.dart';

/// §14.4 HazardPrior の出力: 災害種別の事前確率スコアと根拠コンテキスト。
@freezed
abstract class DisasterCandidate with _$DisasterCandidate {
  const factory DisasterCandidate({
    required DisasterType type,

    /// §3.4-a のスコア式による事前確率スコア。
    required int score,

    /// スコア算出に使ったハザードコンテキスト。
    required HazardContext context,
  }) = _DisasterCandidate;
}
