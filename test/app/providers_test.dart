import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/pack_loader.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';

/// §12 データパック / GPS 未取得時の縮退挙動を providers レイヤで固定する。
void main() {
  test('dataPackProvider: パックファイル不在時は null を返し例外を投げない', () async {
    final container = ProviderContainer(
      overrides: [
        packPathProvider.overrideWith(
          (ref) async => '/nonexistent/path/to/pack.sqlite',
        ),
      ],
    );
    addTearDown(container.dispose);
    final pack = await container.read(dataPackProvider.future);
    expect(pack, isNull);
  });

  test('hazardContextProvider: パック未取得時は既定コンテキストで縮退', () async {
    final container = ProviderContainer(
      overrides: [
        dataPackProvider.overrideWith((ref) async => null),
        locationProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    final ctx = await container.read(hazardContextProvider.future);
    expect(ctx, const HazardContext());
  });

  test('locationProvider: overrideWith で任意の値を差し込める (権限拒否 = null)', () async {
    final container = ProviderContainer(
      overrides: [locationProvider.overrideWith((ref) async => null)],
    );
    addTearDown(container.dispose);
    final loc = await container.read(locationProvider.future);
    expect(loc, isNull);
  });

  test('offlineSttAvailableProvider: 起動時は false（権限ダイアログを出さない）', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(offlineSttAvailableProvider.future), isFalse);
  });

  test('hazardPriorProvider: パック未取得でもフォールバック実装が返る', () async {
    final container = ProviderContainer(
      overrides: [dataPackProvider.overrideWith((ref) async => null)],
    );
    addTearDown(container.dispose);
    final prior = await container.read(hazardPriorProvider.future);
    final ranks = await prior.rank(const GeoPoint(35.0, 139.0));
    expect(ranks, isNotEmpty);
  });

  test('shelterFinderProvider / routeEngineProvider: パック未取得時は null', () async {
    final container = ProviderContainer(
      overrides: [dataPackProvider.overrideWith((ref) async => null)],
    );
    addTearDown(container.dispose);
    expect(await container.read(shelterFinderProvider.future), isNull);
    expect(await container.read(routeEngineProvider.future), isNull);
  });

  test('DataPack 型がインポート可能 (コンパイル時保証)', () {
    expect(DataPack, isNotNull);
  });
}
