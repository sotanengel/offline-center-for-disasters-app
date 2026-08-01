import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/enums.dart';

/// §3.4-c 直近選択の引き継ぎ（30 分以内なら「継続中」として再開可能）。
class RecentSelectionStore {
  RecentSelectionStore(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _keyType = 'recent_disaster_type';
  static const _keyAt = 'recent_disaster_type_at';
  static const _validFor = Duration(minutes: 30);

  Future<void> save(DisasterType type) async {
    await _prefs.setString(_keyType, type.name);
    await _prefs.setString(_keyAt, _clock().toIso8601String());
  }

  /// 30 分以内の選択があれば返す。なければ null。
  Future<DisasterType?> recent() async {
    final typeName = _prefs.getString(_keyType);
    final atStr = _prefs.getString(_keyAt);
    if (typeName == null || atStr == null) return null;
    final at = DateTime.tryParse(atStr);
    if (at == null) return null;
    if (_clock().difference(at) > _validFor) return null;
    for (final type in DisasterType.values) {
      if (type.name == typeName) return type;
    }
    return null;
  }

  Future<void> clear() async {
    await _prefs.remove(_keyType);
    await _prefs.remove(_keyAt);
  }
}
