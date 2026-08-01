import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/app/routes.dart';
import 'package:offline_center_for_disasters/main.dart';
import 'package:offline_center_for_disasters/ui/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('初回起動（onboarding 未完了）は S-06 を表示する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeLocationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          locationServiceProvider.overrideWithValue(fake),
        ],
        child: const OfflineCenterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('初回セットアップ'), findsOneWidget);
    expect(find.text('どの災害から逃げますか？'), findsNothing);
  });

  testWidgets('オンボーディング完了済みならホームを表示する', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeLocationService(permission: LocationPermission.whileInUse);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          locationServiceProvider.overrideWithValue(fake),
        ],
        child: const OfflineCenterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('どの災害から逃げますか？'), findsOneWidget);
  });

  testWidgets('同意して続けると位置情報を要求しホームへ進む', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeLocationService(
      permission: LocationPermission.denied,
      permissionAfterRequest: LocationPermission.whileInUse,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          locationServiceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          initialRoute: AppRoutes.onboarding,
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.onboarding) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const OnboardingScreen(),
              );
            }
            if (settings.name == AppRoutes.home) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('どの災害から逃げますか？')),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('続ける'));
    await tester.pumpAndSettle();

    expect(fake.requestPermissionCalls, 1);
    expect(find.text('どの災害から逃げますか？'), findsOneWidget);
    expect(prefs.getBool('onboarding_complete'), isTrue);
  });
}
