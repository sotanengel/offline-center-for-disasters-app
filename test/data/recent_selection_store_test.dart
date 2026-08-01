import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/prefs/recent_selection_store.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// §3.4-c 直近選択の引き継ぎ（30 分以内なら「継続中」として再開可能）
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('保存した種別を 30 分以内なら取得できる', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 8, 1, 12, 0);
    final store = RecentSelectionStore(prefs, clock: () => now);

    await store.save(DisasterType.tsunami);

    now = DateTime(2026, 8, 1, 12, 29);
    expect(await store.recent(), DisasterType.tsunami);
  });

  test('30 分を過ぎた選択は返さない', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 8, 1, 12, 0);
    final store = RecentSelectionStore(prefs, clock: () => now);

    await store.save(DisasterType.tsunami);

    now = DateTime(2026, 8, 1, 12, 31);
    expect(await store.recent(), isNull);
  });

  test('未保存なら null', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = RecentSelectionStore(prefs);
    expect(await store.recent(), isNull);
  });

  test('クリアで引き継ぎを消せる', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = RecentSelectionStore(prefs);
    await store.save(DisasterType.earthquake);
    await store.clear();
    expect(await store.recent(), isNull);
  });
}
