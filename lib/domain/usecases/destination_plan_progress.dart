import 'destination_planner.dart';

/// S-02 避難先探索の段階的進捗（プログレスバー表示用）。
class DestinationPlanProgress {
  const DestinationPlanProgress({required this.fraction, required this.label});

  /// 0.0〜1.0。null 相当は UI 側で indeterminate 表示。
  final double fraction;
  final String label;

  static const preparing = DestinationPlanProgress(
    fraction: 0.05,
    label: '準備中...',
  );
  static const hazardContext = DestinationPlanProgress(
    fraction: 0.15,
    label: '周辺のハザードを確認中...',
  );
  static const shelterSearch = DestinationPlanProgress(
    fraction: 0.35,
    label: '避難所を探索中...',
  );
  static const graphLoad = DestinationPlanProgress(
    fraction: 0.65,
    label: '道路データを読み込み中...',
  );
  static const routeCalc = DestinationPlanProgress(
    fraction: 0.85,
    label: '経路を計算中...',
  );
  static const complete = DestinationPlanProgress(fraction: 1.0, label: '完了');
}

/// [destinationPlanProvider] の UI 向け状態。
sealed class DestinationPlanState {
  const DestinationPlanState();
}

final class DestinationPlanLoading extends DestinationPlanState {
  const DestinationPlanLoading(this.progress);
  final DestinationPlanProgress progress;
}

final class DestinationPlanReady extends DestinationPlanState {
  const DestinationPlanReady(this.plan);
  final DestinationPlan plan;
}

final class DestinationPlanFailed extends DestinationPlanState {
  const DestinationPlanFailed(this.error);
  final Object error;
}
