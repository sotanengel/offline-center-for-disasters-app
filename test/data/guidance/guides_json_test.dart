import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guides.json は80件以上で source 必須', () {
    final raw = File('assets/kb/guides.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final guides = json['guides'] as List<dynamic>;
    expect(guides.length, greaterThanOrEqualTo(80));
    for (final g in guides) {
      final m = g as Map<String, dynamic>;
      expect(m['id'], isNotEmpty);
      expect(m['title'], isNotEmpty);
      expect(m['source'], isNotEmpty);
      expect((m['steps'] as List).length, lessThanOrEqualTo(5));
    }
    final ids = guides.map((g) => (g as Map)['id']).toSet();
    expect(ids.length, guides.length, reason: 'id は一意');
    final principles = ids
        .where((id) => id.toString().startsWith('gp_'))
        .length;
    expect(principles, greaterThanOrEqualTo(4));
  });
}
