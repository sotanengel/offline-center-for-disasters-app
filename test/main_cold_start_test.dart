import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/prefs/recent_selection_store.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// コールド起動時に直近選択がクリアされること（F-BUG-01）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('main 相当: 起動時 clear 後は直近選択が null', () async {
    final savedAt = DateTime(2026, 8, 2, 9, 0);
    SharedPreferences.setMockInitialValues({
      'recent_disaster_type': 'tsunami',
      'recent_disaster_type_at': savedAt.toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    final store = RecentSelectionStore(
      prefs,
      clock: () => savedAt.add(const Duration(minutes: 10)),
    );

    expect(await store.recent(), DisasterType.tsunami);

    await store.clear();

    expect(await store.recent(), isNull);
    expect(prefs.getString('recent_disaster_type'), isNull);
    expect(prefs.getString('recent_disaster_type_at'), isNull);
  });
}
