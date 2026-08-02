import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/assistant_chat.dart';

/// assets/kb/assistant/*.json を読み込む。
class AssistantKbLoader {
  static const chunksAssetPath = 'assets/kb/assistant/chunks.json';
  static const sourcesAssetPath = 'assets/kb/assistant/sources.json';

  static Future<AssistantKbBundle> load() async {
    final chunksRaw = await rootBundle.loadString(chunksAssetPath);
    final sourcesRaw = await rootBundle.loadString(sourcesAssetPath);
    return loadFromJson(
      chunksJson: jsonDecode(chunksRaw) as Map<String, dynamic>,
      sourcesJson: jsonDecode(sourcesRaw) as Map<String, dynamic>,
    );
  }

  static AssistantKbBundle loadFromJson({
    required Map<String, dynamic> chunksJson,
    required Map<String, dynamic> sourcesJson,
  }) {
    final categories = (sourcesJson['categories'] as List<dynamic>? ?? [])
        .map(
          (e) => AssistantCategory(
            id: (e as Map)['id'] as String,
            label: e['label'] as String,
          ),
        )
        .toList();
    final sources = (sourcesJson['sources'] as List<dynamic>? ?? [])
        .map((e) => _parseSource(e as Map<String, dynamic>))
        .toList();
    final chunks = (chunksJson['chunks'] as List<dynamic>? ?? [])
        .map((e) => _parseChunk(e as Map<String, dynamic>))
        .toList();
    return AssistantKbBundle(
      categories: categories,
      sources: sources,
      chunks: chunks,
    );
  }

  static AssistantSource _parseSource(Map<String, dynamic> m) {
    return AssistantSource(
      id: m['id'] as String,
      title: m['title'] as String,
      url: m['url'] as String,
      category: m['category'] as String,
      publisher: m['publisher'] as String? ?? '',
    );
  }

  static AssistantChunk _parseChunk(Map<String, dynamic> m) {
    return AssistantChunk(
      id: m['id'] as String,
      sourceId: m['sourceId'] as String,
      title: m['title'] as String,
      category: m['category'] as String,
      tags: (m['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      content: m['content'] as String,
      pageRef: m['pageRef'] as String?,
    );
  }
}

class AssistantKbBundle {
  const AssistantKbBundle({
    required this.categories,
    required this.sources,
    required this.chunks,
  });

  final List<AssistantCategory> categories;
  final List<AssistantSource> sources;
  final List<AssistantChunk> chunks;

  AssistantSource? sourceFor(String sourceId) {
    for (final s in sources) {
      if (s.id == sourceId) return s;
    }
    return null;
  }

  AssistantChunk? chunkById(String id) {
    for (final c in chunks) {
      if (c.id == id) return c;
    }
    return null;
  }
}
