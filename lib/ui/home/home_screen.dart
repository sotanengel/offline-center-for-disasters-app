import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/disaster_candidate.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/hazard_context.dart';
import 'disaster_tile.dart';

/// S-01 ホーム画面（§3.2: 災害種別タイル 8 種 + 一言入力）。
///
/// - §3.4-a: ハザードプライアでタイル並び替え・≥70 強調（低スコアも隠さない）
/// - §3.4-b: 揺れ検知バナー + 地震強調。津波想定域内なら津波を最上位に
/// - §3.5: 単一種別 ≥100 かつ他 ≤30 のとき種別明示ワンタップボタン
/// - 緊急導線「わからない・とにかく逃げたい」は §3.6 縮退動作へ接続
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onSelect});

  /// 災害種別の確定時コールバック（結果画面遷移は PR-7 で接続）。
  final void Function(DisasterType type)? onSelect;

  static const _tileMeta = <DisasterType, (String, String)>{
    DisasterType.tsunami: ('🌊', '津波'),
    DisasterType.flood: ('🌧', '大雨・洪水'),
    DisasterType.landslide: ('⛰', '土砂災害'),
    DisasterType.earthquake: ('🏚', '地震'),
    DisasterType.stormSurge: ('🌀', '高潮'),
    DisasterType.fire: ('🔥', '火災'),
    DisasterType.volcano: ('🌋', '噴火'),
    DisasterType.unknown: ('❓', 'わからない'),
  };

  static String labelOf(DisasterType type) => _tileMeta[type]?.$2 ?? '不明';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(disasterCandidatesProvider).value ?? const [];
    final ctx = ref.watch(hazardContextProvider).value ?? const HazardContext();
    final shakeDetected = ref.watch(shakeDetectedProvider).value ?? false;
    final recent = ref.watch(recentSelectionProvider).value;
    final sttAvailable = ref.watch(offlineSttAvailableProvider).value ?? false;

    final tiles = _orderedTiles(candidates, ctx, shakeDetected);
    final emphasized = _emphasizedTypes(candidates, ctx, shakeDetected);
    final oneTap = _oneTapType(candidates);

    void select(DisasterType type) {
      ref.read(recentSelectionStoreProvider).save(type);
      onSelect?.call(type);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('どの災害から逃げますか？')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (shakeDetected) _shakeBanner(ctx),
            if (oneTap != null)
              _oneTapButton(context, oneTap, () => select(oneTap)),
            _emergencyButton(context, () => select(DisasterType.unknown)),
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
            const SizedBox(height: 12),
            _freeTextInput(ref, sttAvailable),
          ],
        ),
      ),
    );
  }

  /// §3.4-a スコア降順。揺れ検知かつ津波想定域内なら津波を最上位に（§3.4-b MUST）。
  /// 「わからない」は常に末尾（§3.2 の配置）。
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
    return [...ordered, DisasterType.unknown];
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
      emphasized.add(DisasterType.earthquake); // §3.4-b: 地震タイルの自動強調
      if (ctx.inTsunamiZone) emphasized.add(DisasterType.tsunami);
    }
    return emphasized;
  }

  /// §3.5: 単一種別 ≥100 かつ他 ≤30 のときだけ種別明示ワンタップを返す。
  DisasterType? _oneTapType(List<DisasterCandidate> candidates) {
    if (candidates.isEmpty) return null;
    final top = candidates.first;
    if (top.score < 100) return null;
    final othersHigh = candidates.skip(1).any((c) => c.score > 30);
    return othersHigh ? null : top.type;
  }

  Widget _shakeBanner(HazardContext ctx) {
    return Card(
      key: const Key('shake_banner'),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '揺れを検知しました',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (ctx.inTsunamiZone)
              const Text(
                '津波の危険があります',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _oneTapButton(
    BuildContext context,
    DisasterType type,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        key: const Key('one_tap_evacuate'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(72),
          backgroundColor: Theme.of(context).colorScheme.error,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
        icon: Text(_tileMeta[type]!.$1, style: const TextStyle(fontSize: 28)),
        label: Text('${labelOf(type)}から避難する'),
      ),
    );
  }

  Widget _emergencyButton(BuildContext context, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        key: const Key('emergency_unknown'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
        child: const Text('わからない・とにかく逃げたい'),
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

  Widget _freeTextInput(WidgetRef ref, bool sttAvailable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('free_text_input'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '例：足をけがした／9 階にいる／母が車椅子',
          ),
          onChanged: (v) => ref.read(freeTextProvider.notifier).state = v,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              key: const Key('mic_button'),
              iconSize: 32,
              // §3.2 L2: オフライン認識非対応なら非活性化（MUST）
              onPressed: sttAvailable ? () {} : null,
              icon: const Icon(Icons.mic),
            ),
            if (!sttAvailable)
              const Expanded(
                child: Text(
                  'オフライン音声認識に未対応のため、音声入力は使えません',
                  style: TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
