import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/route_result.dart';
import '../../ui/home/home_screen.dart';

/// S-02 結果サマリ（§3.7 / §15.2）。
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.disasterType});

  final DisasterType disasterType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnknown = disasterType == DisasterType.unknown;
    final location =
        ref.watch(locationProvider).valueOrNull ??
        const GeoPoint(35.6812, 139.7671);

    return Scaffold(
      appBar: AppBar(
        title: Text(HomeScreen.labelOf(disasterType)),
        actions: [
          TextButton(
            onPressed: () => _showTypeSheet(context, ref),
            child: const Text('[変更]'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryBar(type: disasterType),
          const SizedBox(height: 16),
          if (!isUnknown) ...[
            _SecondaryInfo(type: disasterType),
            const SizedBox(height: 16),
            const Text(
              '避難先候補',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _DestinationSummary(type: disasterType),
          ] else
            const Text(
              '災害種別が未確定のため、避難先は断定表示しません（§3.6）',
              style: TextStyle(fontSize: 18),
            ),
          const SizedBox(height: 24),
          if (!isUnknown)
            SizedBox(
              height: 72,
              child: FilledButton(
                key: const Key('start_nav_button'),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.nav,
                    arguments: NavArgs(
                      origin: location,
                      route: RouteResult(
                        targetId: 'demo',
                        costSeconds: 600,
                        distanceM: 1200,
                        polyline: [
                          location,
                          GeoPoint(location.lat + 0.01, location.lng + 0.01),
                        ],
                        instructions: const [
                          TurnInstruction(
                            kind: TurnKind.goStraight,
                            distanceM: 300,
                            text: '300m 直進',
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('案内を開始する', style: TextStyle(fontSize: 20)),
              ),
            ),
        ],
      ),
    );
  }

  void _showTypeSheet(BuildContext context, WidgetRef ref) {
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
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.result, arguments: t);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.type});
  final DisasterType type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '種別: ${HomeScreen.labelOf(type)} / 緊急度: 要確認 / 移動: 通常',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _SecondaryInfo extends StatelessWidget {
  const _SecondaryInfo({required this.type});
  final DisasterType type;

  @override
  Widget build(BuildContext context) {
    if (type == DisasterType.tsunami) {
      return const Text(
        '標高: 12 m（最優先表示 §15.2）',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      );
    }
    if (type == DisasterType.flood || type == DisasterType.stormSurge) {
      return const Text('浸水想定: 区域外', style: TextStyle(fontSize: 22));
    }
    return const SizedBox.shrink();
  }
}

class _DestinationSummary extends StatelessWidget {
  const _DestinationSummary({required this.type});
  final DisasterType type;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('destination_summary'),
      child: ListTile(
        title: const Text('○○小学校'),
        subtitle: Text(
          type == DisasterType.tsunami ? '標高 15m / 距離 1.2km' : '距離 1.2km',
        ),
      ),
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
