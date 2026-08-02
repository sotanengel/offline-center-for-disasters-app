import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/route_result.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/usecases/destination_plan_progress.dart';
import '../../domain/usecases/destination_planner.dart';
import '../../ui/home/home_screen.dart';

/// S-02 結果サマリ（§3.7 / §15.2）。
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.slots});

  final SituationSlots slots;

  DisasterType get disasterType => slots.disasterType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simpleMode = ref.watch(llmSimpleModeProvider).valueOrNull ?? false;
    final planState = ref.watch(destinationPlanProvider(slots));

    return Scaffold(
      appBar: AppBar(
        title: Text(HomeScreen.labelOf(disasterType)),
        actions: [
          if (simpleMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('簡易モード')),
            ),
          TextButton(
            onPressed: () => _showTypeSheet(context),
            child: const Text('[変更]'),
          ),
        ],
      ),
      body: switch (planState) {
        DestinationPlanLoading(:final progress) => _PlanLoadingBody(
          progress: progress,
        ),
        DestinationPlanFailed(:final error) => Center(
          child: Text('避難先の取得に失敗しました: $error'),
        ),
        DestinationPlanReady(:final plan) => _ResultBody(
          slots: slots,
          plan: plan,
        ),
      },
    );
  }

  void _showTypeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            for (final t in DisasterType.values)
              if (t != DisasterType.unknown)
                ListTile(
                  title: Text(HomeScreen.labelOf(t)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.result,
                      arguments: slots.copyWith(
                        disasterType: t,
                        source: SlotSource.manual,
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _PlanLoadingBody extends StatelessWidget {
  const _PlanLoadingBody({required this.progress});

  final DestinationPlanProgress progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 16),
            Text(progress.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.slots, required this.plan});

  final SituationSlots slots;
  final DestinationPlan plan;

  bool get isUnknown => slots.disasterType == DisasterType.unknown;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryBar(slots: slots),
        if (slots.needsDisasterTypeConfirmation)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '災害種別を選ぶとより正確に案内できます',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (!isUnknown) ...[
          _SecondaryInfo(type: slots.disasterType, plan: plan),
          const SizedBox(height: 16),
          const Text(
            '避難先候補',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _DestinationSummary(plan: plan),
        ] else
          const Text(
            '災害種別が未確定のため、避難先は断定表示しません（§3.6）',
            style: TextStyle(fontSize: 18),
          ),
        const SizedBox(height: 24),
        if (!isUnknown && plan.hasShelter)
          SizedBox(
            height: 72,
            child: FilledButton(
              key: const Key('start_nav_button'),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.nav,
                  arguments: NavArgs(
                    origin: plan.origin,
                    route: plan.route,
                    fallbackBearing: plan.route == null,
                  ),
                );
              },
              child: const Text('案内を開始する', style: TextStyle(fontSize: 20)),
            ),
          ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.slots});
  final SituationSlots slots;

  @override
  Widget build(BuildContext context) {
    final typeLabel = HomeScreen.labelOf(slots.disasterType);
    final mobility = slots.userState.mobility.name;
    final urgency = slots.urgency.name;
    final aiInterpreted =
        slots.source == SlotSource.ai &&
        slots.disasterType != DisasterType.unknown &&
        slots.disasterTypeEvidence.isNotEmpty;

    final bg = slots.needsDisasterTypeConfirmation
        ? Theme.of(context).colorScheme.errorContainer
        : aiInterpreted
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    final summary = aiInterpreted
        ? '〈$typeLabel〉と解釈しました。違う場合はタップ / 緊急度: $urgency / 移動: $mobility'
        : '種別: $typeLabel / 緊急度: $urgency / 移動: $mobility';

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(summary, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _SecondaryInfo extends StatelessWidget {
  const _SecondaryInfo({required this.type, required this.plan});
  final DisasterType type;
  final DestinationPlan plan;

  @override
  Widget build(BuildContext context) {
    if (type == DisasterType.tsunami) {
      final elev = plan.shelter?.elevationM;
      if (elev != null) {
        return Text(
          '標高: ${elev.toStringAsFixed(0)} m（避難先 §15.2）',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        );
      }
    }
    if (type == DisasterType.flood || type == DisasterType.stormSurge) {
      final inZone =
          plan.shelterContext.inFloodZone ||
          plan.shelterContext.inStormSurgeZone;
      return Text(
        inZone ? '浸水想定: 区域内' : '浸水想定: 区域外',
        style: const TextStyle(fontSize: 22),
      );
    }
    return const SizedBox.shrink();
  }
}

class _DestinationSummary extends StatelessWidget {
  const _DestinationSummary({required this.plan});
  final DestinationPlan plan;

  @override
  Widget build(BuildContext context) {
    if (plan.packMissing) {
      return const Card(
        key: Key('destination_summary'),
        child: ListTile(
          title: Text('データパック未配置'),
          subtitle: Text(
            'オフラインデータパック（bundled）が未配置です。'
            'リリースビルド（tool/build/release_ios.sh）または'
            ' tool/build/prepare_bundled_packs.sh でデータを配置してください',
          ),
        ),
      );
    }
    if (plan.notFound) {
      return Card(
        key: const Key('destination_summary'),
        child: ListTile(
          title: const Text('近くに適合する避難所が見つかりません'),
          subtitle: Text(
            plan.expandedRadius ? '20km 圏内を探索しました（§4.4）' : '10km 圏内を探索しました',
          ),
        ),
      );
    }
    final shelter = plan.shelter!;
    final distance = plan.distanceM != null
        ? formatDistanceM(plan.distanceM!)
        : '—';
    final subtitle = switch (plan.shelter!.elevationM) {
      final e? when e > 0 => '標高 ${e.toStringAsFixed(0)}m / 距離 $distance',
      _ => '距離 $distance',
    };
    return Card(
      key: const Key('destination_summary'),
      child: ListTile(title: Text(shelter.name), subtitle: Text(subtitle)),
    );
  }
}

/// NavScreen への引数。
class NavArgs {
  const NavArgs({
    required this.origin,
    this.route,
    this.fallbackBearing = false,
  });
  final GeoPoint origin;
  final RouteResult? route;
  final bool fallbackBearing;
}
