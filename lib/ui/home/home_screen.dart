import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/disaster_candidate.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/hazard_context.dart';
import '../../domain/entities/situation_slots.dart';
import 'disaster_tile.dart';

/// S-01 ホーム画面（§3.2: 災害種別タイル 7 種）。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onSelect});

  /// 状況確定時コールバック（P5: [SituationSlots] を渡す）。
  final void Function(SituationSlots slots)? onSelect;

  static const _tileMeta = <DisasterType, (String, String)>{
    DisasterType.tsunami: ('🌊', '津波'),
    DisasterType.flood: ('🌧', '大雨・洪水'),
    DisasterType.landslide: ('⛰', '土砂災害'),
    DisasterType.earthquake: ('🏚', '地震'),
    DisasterType.stormSurge: ('🌀', '高潮'),
    DisasterType.fire: ('🔥', '火災'),
    DisasterType.volcano: ('🌋', '噴火'),
  };

  static String labelOf(DisasterType type) => _tileMeta[type]?.$2 ?? '不明';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(disasterCandidatesProvider).value ?? const [];
    final ctx = ref.watch(hazardContextProvider).value ?? const HazardContext();
    final shakeDetected = ref.watch(shakeDetectedProvider).value ?? false;
    final recent = ref.watch(recentSelectionProvider).value;

    final tiles = _orderedTiles(candidates, ctx, shakeDetected);
    final emphasized = _emphasizedTypes(candidates, ctx, shakeDetected);
    final oneTap = _oneTapType(candidates);

    Future<void> select(DisasterType type) async {
      ref.read(recentSelectionStoreProvider).save(type);
      final slots = SituationSlots(disasterType: type, source: SlotSource.tile);
      onSelect?.call(slots);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('どの災害から逃げますか？')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (oneTap != null)
              _oneTapButton(context, oneTap, () => select(oneTap)),
            if (recent != null) _recentChip(recent, () => select(recent)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                for (final type in tiles)
                  DisasterTile(
                    key: Key('tile_${type.name}'),
                    emoji: _tileMeta[type]!.$1,
                    label: _tileMeta[type]!.$2,
                    emphasized: emphasized.contains(type),
                    onTap: () => select(type),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DisasterType> _orderedTiles(
    List<DisasterCandidate> candidates,
    HazardContext ctx,
    bool shakeDetected,
  ) {
    final ordered = candidates.map((c) => c.type).toList();
    if (shakeDetected &&
        ctx.inTsunamiZone &&
        ordered.contains(DisasterType.tsunami)) {
      ordered
        ..remove(DisasterType.tsunami)
        ..insert(0, DisasterType.tsunami);
    }
    return ordered;
  }

  Set<DisasterType> _emphasizedTypes(
    List<DisasterCandidate> candidates,
    HazardContext ctx,
    bool shakeDetected,
  ) {
    final emphasized = {
      for (final c in candidates)
        if (c.score >= 70) c.type,
    };
    if (shakeDetected) {
      emphasized.add(DisasterType.earthquake);
      if (ctx.inTsunamiZone) emphasized.add(DisasterType.tsunami);
    }
    return emphasized;
  }

  DisasterType? _oneTapType(List<DisasterCandidate> candidates) {
    if (candidates.isEmpty) return null;
    final top = candidates.first;
    if (top.score < 100) return null;
    final othersLow = candidates.skip(1).every((c) => c.score <= 30);
    return othersLow ? top.type : null;
  }

  Widget _oneTapButton(
    BuildContext context,
    DisasterType type,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          onPressed: onTap,
          child: Text('${labelOf(type)}から避難する'),
        ),
      ),
    );
  }

  Widget _recentChip(DisasterType recent, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        key: const Key('recent_selection'),
        avatar: Text(_tileMeta[recent]!.$1),
        label: Text('継続中: ${labelOf(recent)}'),
        onPressed: onTap,
      ),
    );
  }
}
