import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/llm/llm_engine.dart';

/// S-05 設定画面（§21 出典・パック管理・LLM モデル選択）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(llmModelChoiceProvider);
    final regions = ref.watch(installedRegionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('LLM モデル'),
            subtitle: Text('自動 / 3サイズ / AIオフ'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final c in LlmModelChoice.values)
                  FilterChip(
                    label: Text(c.name),
                    selected: choice == c,
                    onSelected: (_) {
                      ref.read(llmModelChoiceProvider.notifier).state = c;
                    },
                  ),
              ],
            ),
          ),
          const Divider(),
          const ListTile(title: Text('導入済みデータパック')),
          regions.when(
            data: (list) => Column(
              children: [
                for (final r in list)
                  ListTile(title: Text(r), subtitle: const Text('ローカル')),
                if (list.isEmpty) const ListTile(title: Text('データ未取得')),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => ListTile(title: Text('読込失敗: $error')),
          ),
          const ListTile(
            title: Text('出典・ライセンス'),
            subtitle: Text('OpenStreetMap (ODbL), 国土地理院, 国土数値情報'),
          ),
        ],
      ),
    );
  }
}
