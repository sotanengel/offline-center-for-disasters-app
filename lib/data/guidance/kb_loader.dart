import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/guide_card.dart';

/// assets/kb/guides.json を読み込む。
class KbLoader {
  static const assetPath = 'assets/kb/guides.json';

  static Future<List<GuideCard>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = json['guides'] as List<dynamic>? ?? [];
    return list.map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  static GuideCard _parse(Map<String, dynamic> m) {
    DisasterType parseType(String s) => DisasterType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => DisasterType.unknown,
    );
    final types = (m['disasterTypes'] as List<dynamic>? ?? [])
        .map((e) => parseType(e.toString()))
        .where((t) => t != DisasterType.unknown)
        .toList();
    return GuideCard(
      id: m['id'] as String,
      title: m['title'] as String,
      disasterTypes: types,
      tags: (m['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      priority: (m['priority'] as num?)?.toInt() ?? 0,
      conditions: (m['conditions'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      steps: (m['steps'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .take(5)
          .toList(),
      warning: m['warning'] as String?,
      source: m['source'] as String? ?? '',
      sourceUpdated: m['sourceUpdated'] as String?,
    );
  }

  /// §3.6 一般原則 4 カード（KB 破損時の縮退用）。
  static List<GuideCard> generalPrinciples() => [
    const GuideCard(
      id: 'gp_higher_ground',
      title: 'より高い場所へ',
      disasterTypes: [
        DisasterType.tsunami,
        DisasterType.flood,
        DisasterType.stormSurge,
      ],
      tags: ['general', 'principle'],
      priority: 1,
      steps: ['浸水や津波の恐れがあるときは高い場所へ', '低地を避ける', '公式情報を確認'],
      source: '内閣府 国民保護・防災 https://www.bousai.go.jp/',
    ),
    const GuideCard(
      id: 'gp_sturdy_building',
      title: '頑丈な建物の高い階へ',
      disasterTypes: [DisasterType.tsunami, DisasterType.flood],
      tags: ['general', 'principle'],
      priority: 2,
      steps: ['頑丈な建物の3階以上を目指す', 'エレベーターは使わない', '窓から離れる'],
      source: '内閣府 国民保護・防災 https://www.bousai.go.jp/',
    ),
    const GuideCard(
      id: 'gp_away_hazard',
      title: '崖・川・海から離れる',
      disasterTypes: [
        DisasterType.landslide,
        DisasterType.flood,
        DisasterType.tsunami,
      ],
      tags: ['general', 'principle'],
      priority: 3,
      steps: ['崖・河川・海岸から離れる', '土砂の危険区域を避ける'],
      source: '消防庁 避難のポイント https://www.fdma.go.jp/',
    ),
    const GuideCard(
      id: 'gp_falling_objects',
      title: '屋外の落下物から離れる',
      disasterTypes: [DisasterType.earthquake, DisasterType.volcano],
      tags: ['general', 'principle'],
      priority: 4,
      steps: ['看板・ガラス等の落下物から離れる', '頭を守る'],
      source: '気象庁 防災情報 https://www.jma.go.jp/',
    ),
  ];
}
