import 'package:flutter/material.dart';

import '../../data/assistant/assistant_kb_loader.dart';
import '../../domain/entities/assistant_chat.dart';
import 'knowledge_detail_screen.dart';

/// 資料一覧（カテゴリ別）。
class KnowledgeBrowserScreen extends StatelessWidget {
  const KnowledgeBrowserScreen({super.key, required this.bundle});

  final AssistantKbBundle bundle;

  static String categoryLabel(String id) {
    for (final c in bundleFallbackCategories) {
      if (c.id == id) return c.label;
    }
    return id;
  }

  static const bundleFallbackCategories = [
    AssistantCategory(id: 'first_aid', label: '応急手当・救命'),
    AssistantCategory(id: 'shelter_health', label: '避難所生活での健康管理'),
    AssistantCategory(id: 'utilities', label: '停電・断水への即応'),
    AssistantCategory(id: 'post_disaster_action', label: '発災後の行動'),
    AssistantCategory(id: 'disaster_tips', label: '災害知識・Tips'),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = bundle.categories.isNotEmpty
        ? bundle.categories
        : bundleFallbackCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('資料一覧')),
      body: ListView(
        children: [
          for (final category in categories)
            ExpansionTile(
              title: Text(category.label, style: const TextStyle(fontSize: 18)),
              children: [
                for (final chunk
                    in bundle.chunks
                        .where((c) => c.category == category.id)
                        .take(50))
                  ListTile(
                    key: Key('kb_${chunk.id}'),
                    title: Text(chunk.title),
                    subtitle: Text(
                      bundle.sourceFor(chunk.sourceId)?.title ?? chunk.sourceId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => KnowledgeDetailScreen(
                            chunk: chunk,
                            source: bundle.sourceFor(chunk.sourceId),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
