import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/app/routes.dart';
import 'package:offline_center_for_disasters/domain/entities/disaster_candidate.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/destination_plan_overrides.dart';

/// §15.1 ホーム → 結果の 1 タップ導線 + §20.2 リグレッション。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<DisasterCandidate> defaultCandidates() => [
    DisasterCandidate(
      type: DisasterType.earthquake,
      score: 30,
      context: const HazardContext(),
    ),
    DisasterCandidate(
      type: DisasterType.fire,
      score: 20,
      context: const HazardContext(),
    ),
    for (final t in [
      DisasterType.tsunami,
      DisasterType.flood,
      DisasterType.landslide,
      DisasterType.stormSurge,
      DisasterType.volcano,
    ])
      DisasterCandidate(type: t, score: 0, context: const HazardContext()),
  ];

  Future<void> pumpApp(WidgetTester tester) async {
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
          destinationPlanProviderOverride(),
        ],
        child: MaterialApp(
          initialRoute: AppRoutes.home,
          onGenerateRoute: onGenerateAppRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ホームから結果画面へは 1 タップで到達する (§15.1)', (tester) async {
    await pumpApp(tester);
    expect(find.text('結果サマリ (S-02)'), findsNothing);

    // 「地震」タイルを 1 タップ
    await tester.tap(find.byKey(const Key('tile_earthquake')));
    await tester.pumpAndSettle();

    // 1 タップ後に結果画面が出ていること
    expect(find.text('案内を開始する'), findsOneWidget);
  });

  testWidgets('§20.2 リグレッション: ホームには destination_summary が存在しない', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('destination_summary')), findsNothing);
  });

  test('AppRoutes 定数は全画面分揃っている', () {
    expect(AppRoutes.home, '/');
    expect(AppRoutes.result, '/result');
    expect(AppRoutes.nav, '/nav');
    expect(AppRoutes.guide, '/guide');
    expect(AppRoutes.settings, '/settings');
    expect(AppRoutes.onboarding, '/onboarding');
  });
}
