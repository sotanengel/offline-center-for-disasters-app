import 'package:flutter/material.dart';

import '../../domain/entities/guide_card.dart';

/// S-04 ガイド詳細（1 カード 1 画面、§11.2 / §15.2）。
class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.card});

  final GuideCard card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(card.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              card.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
            if (card.warning != null) ...[
              const SizedBox(height: 12),
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    card.warning!,
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (var i = 0; i < card.steps.length && i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: const TextStyle(fontSize: 20, height: 1.4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.steps[i],
                        style: const TextStyle(fontSize: 20, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text('出典', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(card.source, style: const TextStyle(fontSize: 16)),
            if (card.sourceUpdated != null)
              Text(
                '更新: ${card.sourceUpdated}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
