import 'package:flutter/material.dart';

import '../../domain/entities/assistant_chat.dart';

/// 資料チャンク詳細。
class KnowledgeDetailScreen extends StatelessWidget {
  const KnowledgeDetailScreen({super.key, required this.chunk, this.source});

  final AssistantChunk chunk;
  final AssistantSource? source;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chunk.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              chunk.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 16),
            Text(
              chunk.content,
              style: const TextStyle(fontSize: 20, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text('出典', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (source != null) ...[
              Text(source!.title, style: const TextStyle(fontSize: 16)),
              Text(source!.publisher, style: const TextStyle(fontSize: 16)),
              SelectableText(source!.url, style: const TextStyle(fontSize: 14)),
            ] else
              Text(chunk.sourceId, style: const TextStyle(fontSize: 16)),
            if (chunk.pageRef != null) ...[
              const SizedBox(height: 8),
              Text(
                '参照: ${chunk.pageRef}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
