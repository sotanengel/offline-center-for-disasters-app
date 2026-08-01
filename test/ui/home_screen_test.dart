import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/domain/entities/disaster_candidate.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/ui/home/disaster_tile.dart';
import 'package:offline_center_for_disasters/ui/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S-01 ホーム画面（§3.2 / §3.4 / §3.5 / §20.2）
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DisasterCandidate cand(
    DisasterType type,
    int score, [
    HazardContext ctx = const HazardContext(),
  ]) => DisasterCandidate(type: type, score: score, context: ctx);

  /// 既定: 無データ地点相当（earthquake 30, fire 20, 他 0）
  List<DisasterCandidate> defaultCandidates([
    HazardContext ctx = const HazardContext(),
  ]) => [
    cand(DisasterType.earthquake, 30, ctx),
    cand(DisasterType.fire, 20, ctx),
    cand(DisasterType.tsunami, 0, ctx),
    cand(DisasterType.flood, 0, ctx),
    cand(DisasterType.landslide, 0, ctx),
    cand(DisasterType.stormSurge, 0, ctx),
    cand(DisasterType.volcano, 0, ctx),
  ];

  Future<void> pumpHome(
    WidgetTester tester, {
    List<DisasterCandidate>? candidates,
    HazardContext ctx = const HazardContext(),
    bool shake = false,
    DisasterType? recent,
    bool sttAvailable = false,
    void Function(SituationSlots)? onSelect,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          disasterCandidatesProvider.overrideWith(
            (ref) async => candidates ?? defaultCandidates(ctx),
          ),
          hazardContextProvider.overrideWith((ref) async => ctx),
          shakeDetectedProvider.overrideWith((ref) => Stream.value(shake)),
          recentSelectionProvider.overrideWith((ref) async => recent),
          offlineSttAvailableProvider.overrideWith((ref) async => sttAvailable),
        ],
        child: MaterialApp(home: HomeScreen(onSelect: onSelect)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 2 列グリッドの論理順（行→列）での先後を比較する。
  bool tilePrecedes(WidgetTester tester, DisasterType a, DisasterType b) {
    final pa = tester.getTopLeft(find.byKey(Key('tile_${a.name}')));
    final pb = tester.getTopLeft(find.byKey(Key('tile_${b.name}')));
    if ((pa.dy - pb.dy).abs() > 1) return pa.dy < pb.dy;
    return pa.dx < pb.dx;
  }

  bool tileEmphasized(WidgetTester tester, DisasterType type) => tester
      .widget<DisasterTile>(find.byKey(Key('tile_${type.name}')))
      .emphasized;

  group('タイル構成（§3.2）', () {
    testWidgets('8 種すべて表示される（わからないを含む、MUST）', (tester) async {
      await pumpHome(tester);
      for (final label in [
        '津波',
        '大雨・洪水',
        '土砂災害',
        '地震',
        '高潮',
        '火災',
        '噴火',
        'わからない',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('スコアが低い種別も非表示にしない（MUST NOT）', (tester) async {
      await pumpHome(tester);
      // スコア 0 の噴火タイルも表示されている
      expect(find.byKey(const Key('tile_volcano')), findsOneWidget);
    });
  });

  group('ハザードプライア（§3.4-a / §20.2）', () {
    testWidgets('想定区域内の種別が最上位に並ぶ', (tester) async {
      const ctx = HazardContext(inTsunamiZone: true, distCoastM: 500);
      await pumpHome(
        tester,
        ctx: ctx,
        candidates: [
          cand(DisasterType.tsunami, 135, ctx),
          ...defaultCandidates(
            ctx,
          ).where((c) => c.type != DisasterType.tsunami),
        ],
      );
      expect(
        tilePrecedes(tester, DisasterType.tsunami, DisasterType.earthquake),
        isTrue,
      );
    });

    testWidgets('スコア ≥ 70 のタイルのみ強調される', (tester) async {
      const ctx = HazardContext(inFloodZone: true, distRiverM: 500);
      await pumpHome(
        tester,
        ctx: ctx,
        candidates: [
          cand(DisasterType.flood, 122, ctx),
          ...defaultCandidates(ctx).where((c) => c.type != DisasterType.flood),
        ],
      );
      expect(tileEmphasized(tester, DisasterType.flood), isTrue);
      expect(tileEmphasized(tester, DisasterType.earthquake), isFalse);
      expect(tileEmphasized(tester, DisasterType.fire), isFalse);
    });
  });

  group('揺れ検知（§3.4-b / §20.2）', () {
    testWidgets('バナー表示 + 地震タイル強調（自動遷移はしない）', (tester) async {
      await pumpHome(tester, shake: true);
      expect(find.text('揺れを検知しました'), findsOneWidget);
      expect(tileEmphasized(tester, DisasterType.earthquake), isTrue);
      // 自動画面遷移しない（MUST NOT）: ホームが表示されたまま
      expect(find.text('どの災害から逃げますか？'), findsOneWidget);
    });

    testWidgets('津波想定域内なら津波が最上位 + 危険表示', (tester) async {
      const ctx = HazardContext(inTsunamiZone: true, distCoastM: 800);
      await pumpHome(tester, ctx: ctx, shake: true);
      expect(find.text('津波の危険があります'), findsOneWidget);
      // スコア 0 でも揺れ検知により津波が最上位
      expect(
        tilePrecedes(tester, DisasterType.tsunami, DisasterType.earthquake),
        isTrue,
      );
      expect(tileEmphasized(tester, DisasterType.tsunami), isTrue);
    });

    testWidgets('揺れなしならバナーなし', (tester) async {
      await pumpHome(tester, shake: false);
      expect(find.byKey(const Key('shake_banner')), findsNothing);
    });
  });

  group('§3.5 種別明示ワンタップボタン', () {
    testWidgets('単一種別 ≥100 かつ他 ≤30 のとき表示される', (tester) async {
      const ctx = HazardContext(inTsunamiZone: true, distCoastM: 500);
      await pumpHome(
        tester,
        ctx: ctx,
        candidates: [
          cand(DisasterType.tsunami, 135, ctx),
          cand(DisasterType.earthquake, 30, ctx),
          cand(DisasterType.fire, 20, ctx),
          cand(DisasterType.flood, 0, ctx),
          cand(DisasterType.landslide, 0, ctx),
          cand(DisasterType.stormSurge, 0, ctx),
          cand(DisasterType.volcano, 0, ctx),
        ],
      );
      expect(find.text('津波から避難する'), findsOneWidget);
    });

    testWidgets('他に高スコアがある場合は表示しない', (tester) async {
      const ctx = HazardContext(inTsunamiZone: true, inFloodZone: true);
      await pumpHome(
        tester,
        ctx: ctx,
        candidates: [
          cand(DisasterType.tsunami, 135, ctx),
          cand(DisasterType.flood, 100, ctx),
          ...defaultCandidates(ctx).where(
            (c) =>
                c.type != DisasterType.tsunami && c.type != DisasterType.flood,
          ),
        ],
      );
      expect(find.byKey(const Key('one_tap_evacuate')), findsNothing);
    });

    testWidgets('緊急導線「わからない・とにかく逃げたい」は常に表示', (tester) async {
      await pumpHome(tester);
      expect(find.text('わからない・とにかく逃げたい'), findsOneWidget);
    });
  });

  group('選択の確定（L1: 1 タップで即座に）', () {
    testWidgets('タイル 1 タップでコールバック発火 + 直近選択に保存', (tester) async {
      final selected = <SituationSlots>[];
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            disasterCandidatesProvider.overrideWith(
              (ref) async => defaultCandidates(),
            ),
            hazardContextProvider.overrideWith(
              (ref) async => const HazardContext(),
            ),
            shakeDetectedProvider.overrideWith((ref) => Stream.value(false)),
            recentSelectionProvider.overrideWith((ref) async => null),
            offlineSttAvailableProvider.overrideWith((ref) async => false),
          ],
          child: MaterialApp(home: HomeScreen(onSelect: selected.add)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tile_tsunami')));
      await tester.pump();
      expect(selected.map((s) => s.disasterType), [DisasterType.tsunami]);
      expect(prefs.getString('recent_disaster_type'), 'tsunami');
    });

    testWidgets('緊急導線タップは unknown として確定する', (tester) async {
      final selected = <SituationSlots>[];
      await pumpHome(tester, onSelect: selected.add);
      await tester.tap(find.byKey(const Key('emergency_unknown')));
      await tester.pump();
      expect(selected.map((s) => s.disasterType), [DisasterType.unknown]);
    });

    testWidgets('直近選択は「継続中」として表示される（§3.4-c）', (tester) async {
      await pumpHome(tester, recent: DisasterType.flood);
      expect(find.text('継続中: 大雨・洪水'), findsOneWidget);
    });
  });

  group('音声入力（§3.2 L2）', () {
    testWidgets('オフライン STT 非対応ならマイク非活性 + 理由表示', (tester) async {
      await pumpHome(tester, sttAvailable: false);
      await tester.scrollUntilVisible(
        find.byKey(const Key('mic_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final mic = tester.widget<IconButton>(
        find.byKey(const Key('mic_button')),
      );
      expect(mic.onPressed, isNull);
      expect(find.textContaining('オフライン音声認識に未対応'), findsOneWidget);
    });

    testWidgets('対応端末ではマイクが活性', (tester) async {
      await pumpHome(tester, sttAvailable: true);
      await tester.scrollUntilVisible(
        find.byKey(const Key('mic_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final mic = tester.widget<IconButton>(
        find.byKey(const Key('mic_button')),
      );
      expect(mic.onPressed, isNotNull);
    });
  });

  group('§20.2 リグレッション（常設）', () {
    testWidgets('災害種別未確定の状態で、特定の避難先が断定表示されない', (tester) async {
      await pumpHome(tester);
      // 避難先の断定表示（施設名・案内カード）が存在しないこと
      expect(find.byKey(const Key('destination_summary')), findsNothing);
      expect(find.textContaining('避難所'), findsNothing);
    });
  });
}
