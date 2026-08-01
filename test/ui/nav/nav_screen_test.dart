import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/routing/road_graph.dart';
import 'package:offline_center_for_disasters/domain/entities/route_result.dart';
import 'package:offline_center_for_disasters/ui/nav/nav_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_evacuation_pack.dart';
import '../../helpers/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const origin = GeoPoint(35.687741, 139.850977);
  const dest = GeoPoint(35.688741, 139.851977);
  final route = RouteResult(
    targetId: 'test-shelter',
    costSeconds: 600,
    distanceM: 1200,
    polyline: const [origin, dest],
    instructions: const [],
  );

  Future<void> pumpNav(
    WidgetTester tester, {
    RoadGraph? graph,
    FakeLocationService? location,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final pack = FakeEvacuationPack(
      graph: graph ?? sampleRoadGraphForNavTest(),
    );
    final fakeLocation = location ?? FakeLocationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dataPackProvider.overrideWith((ref) async => pack),
          locationServiceProvider.overrideWithValue(fakeLocation),
        ],
        child: MaterialApp(
          home: NavScreen(origin: origin, route: route),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('道路グラフと経路の 2 層 PolylineLayer を描画する', (tester) async {
    await pumpNav(tester);
    expect(find.byType(NavScreen), findsOneWidget);
    expect(find.byType(PolylineLayer), findsNWidgets(2));
    expect(find.textContaining('残り'), findsOneWidget);
  });

  testWidgets('パック不在時も経路 PolylineLayer のみ描画する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dataPackProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: NavScreen(origin: origin, route: route),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PolylineLayer), findsOneWidget);
  });

  testWidgets('位置更新で残距離表示が変わる', (tester) async {
    final fakeLocation = FakeLocationService(
      permission: LocationPermission.whileInUse,
    );
    await pumpNav(tester, location: fakeLocation);
    final before = find.textContaining('残り');
    expect(before, findsOneWidget);

    fakeLocation.emitPosition(GeoPointPosition(dest.lat, dest.lng));
    await tester.pumpAndSettle();

    expect(find.textContaining('残り 0.0 km'), findsOneWidget);
  });
}
