import 'package:flutter/material.dart';

import '../../../domain/entities/assistant_chat.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.role,
    required this.text,
    this.chunks = const [],
    this.onChunkTap,
  });

  final String role;
  final String text;
  final List<AssistantChunk> chunks;
  final void Function(AssistantChunk chunk)? onChunkTap;

  bool get _isUser => role == 'user';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _isUser
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = _isUser ? scheme.onPrimaryContainer : scheme.onSurface;

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: _isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Material(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(text, style: TextStyle(fontSize: 18, color: fg)),
              ),
            ),
            if (chunks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final chunk in chunks)
                    ActionChip(
                      key: Key('cite_${chunk.id}'),
                      label: Text(
                        chunk.title.length > 24
                            ? '${chunk.title.substring(0, 24)}…'
                            : chunk.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onPressed: onChunkTap == null
                          ? null
                          : () => onChunkTap!(chunk),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
