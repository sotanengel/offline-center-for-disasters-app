import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/app/theme.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/domain/entities/disaster_candidate.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/entities/route_result.dart';
import 'package:offline_center_for_disasters/ui/home/disaster_tile.dart';
import 'package:offline_center_for_disasters/ui/home/home_screen.dart';
import 'package:offline_center_for_disasters/ui/nav/nav_screen.dart';
import 'package:offline_center_for_disasters/ui/result/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// §15.4 アクセシビリティ: タップ領域・Semantics・主要ボタン高さ。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(WidgetTester tester, {ThemeData? theme}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          disasterCandidatesProvider.overrideWith(
            (ref) async => [
              DisasterCandidate(
                type: DisasterType.tsunami,
                score: 80,
                context: const HazardContext(),
              ),
              DisasterCandidate(
                type: DisasterType.earthquake,
                score: 30,
                context: const HazardContext(),
              ),
            ],
          ),
          hazardContextProvider.overrideWith(
            (ref) async => const HazardContext(),
          ),
          shakeDetectedProvider.overrideWith((ref) => Stream.value(false)),
          recentSelectionProvider.overrideWith((ref) async => null),
          offlineSttAvailableProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          home: HomeScreen(onSelect: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('§15.4 タップ領域', () {
    testWidgets('災害タイル minHeight ≥88dp', (tester) async {
      await pumpHome(tester);
      final size = tester.getSize(find.byKey(const Key('tile_tsunami')));
      expect(size.height, greaterThanOrEqualTo(88));
    });

    testWidgets('案内開始ボタン高さ ≥72dp', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const ResultScreen(disasterType: DisasterType.flood),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.getSize(find.byKey(const Key('start_nav_button')));
      expect(button.height, greaterThanOrEqualTo(72));
    });
  });

  group('§15.4 Semantics', () {
    testWidgets('DisasterTile が Semantics でラップされる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisasterTile(emoji: '🌊', label: '津波', onTap: () {}),
          ),
        ),
      );
      expect(find.byType(Semantics), findsWidgets);
      expect(find.text('津波'), findsOneWidget);
    });
  });

  group('明暗テーマ smoke（S-01〜S-03）', () {
    testWidgets('HomeScreen が light/dark 両方で描画される', (tester) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        await pumpHome(tester, theme: theme);
        expect(find.text('どの災害から逃げますか？'), findsOneWidget);
      }
    });

    testWidgets('ResultScreen / NavScreen が dark で描画される', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const ResultScreen(disasterType: DisasterType.flood),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: NavScreen(
              origin: const GeoPoint(35.68, 139.76),
              route: RouteResult(
                targetId: 'x',
                costSeconds: 60,
                distanceM: 100,
                polyline: const [
                  GeoPoint(35.68, 139.76),
                  GeoPoint(35.69, 139.77),
                ],
                instructions: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(NavScreen), findsOneWidget);
      expect(find.textContaining('残り'), findsOneWidget);
    });
  });
}
