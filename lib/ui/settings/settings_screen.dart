import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/llm/llm_engine.dart';
import '../../data/llm/model_registry.dart';

/// S-05 設定画面（§21 出典・パック管理・LLM モデル選択）。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _downloadProgress = 0;
  bool _downloading = false;
  String? _downloadMessage;

  @override
  Widget build(BuildContext context) {
    final choice = ref.watch(llmModelChoiceProvider);
    final regions = ref.watch(installedRegionsProvider);
    final simpleMode = ref.watch(llmSimpleModeProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        actions: [if (simpleMode) const Chip(label: Text('簡易モード'))],
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('LLM モデル'),
            subtitle: Text('自動 / 3サイズ / AIオフ（Wi-Fi 時のみ DL）'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final c in LlmModelChoice.values)
                  FilterChip(
                    label: Text(_choiceLabel(c)),
                    selected: choice == c,
                    onSelected: (_) {
                      ref.read(llmModelChoiceProvider.notifier).setChoice(c);
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_downloading)
                  LinearProgressIndicator(value: _downloadProgress),
                if (_downloadMessage != null)
                  Text(_downloadMessage!, style: const TextStyle(fontSize: 13)),
                FilledButton(
                  onPressed: _downloading || choice == LlmModelChoice.off
                      ? null
                      : _downloadModel,
                  child: const Text('モデルをダウンロード'),
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
            title: Text('モデル情報'),
            subtitle: Text(
              'LFM2.5-1.2B-Instruct / LFM2-350M（liquid_ai / LEAP SDK）',
            ),
          ),
          const ListTile(
            title: Text('出典・ライセンス'),
            subtitle: Text('OpenStreetMap (ODbL), 国土地理院, 国土数値情報, Liquid AI'),
          ),
        ],
      ),
    );
  }

  String _choiceLabel(LlmModelChoice c) => switch (c) {
    LlmModelChoice.auto => '自動',
    LlmModelChoice.lfm25_1200jp => '1.2B-JP',
    LlmModelChoice.lfm25_350m => '350M',
    LlmModelChoice.lfm25_230m => '230M',
    LlmModelChoice.off => 'AIオフ',
  };

  Future<void> _downloadModel() async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
      _downloadMessage = null;
    });

    final choice = ref.read(llmModelChoiceProvider);
    final tier = ref.read(deviceTierServiceProvider);
    final effective = await tier.resolveEffectiveChoice(choice);
    final slug = ModelRegistry.catalogSlug(effective);
    if (slug == null) {
      setState(() {
        _downloading = false;
        _downloadMessage = 'この端末ではモデルを利用できません';
      });
      return;
    }

    final downloader = ref.read(modelDownloaderProvider);
    if (!await downloader.isWifiConnected()) {
      setState(() {
        _downloading = false;
        _downloadMessage = 'Wi-Fi 接続時のみダウンロードできます';
      });
      return;
    }

    final result = await downloader.downloadAndLoad(
      choice: effective,
      onProgress: (p) {
        if (mounted) {
          setState(() => _downloadProgress = p.progress);
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _downloading = false;
      _downloadMessage = result.isOk
          ? 'モデル $slug の準備が完了しました'
          : 'ダウンロードに失敗しました（簡易モードで動作します）';
    });
  }
}
