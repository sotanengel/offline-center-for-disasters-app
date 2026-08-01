import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offline_center_for_disasters/app/providers.dart';

import '../helpers/fake_location_service.dart';

/// F-11: 位置情報は check だけでなく request すること。
void main() {
  test('locationProvider: denied のとき requestPermission を呼び許可後に座標を返す', () async {
    final fake = FakeLocationService(
      permission: LocationPermission.denied,
      permissionAfterRequest: LocationPermission.whileInUse,
      position: const GeoPointPosition(35.5, 139.5),
    );
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final loc = await container.read(locationProvider.future);

    expect(fake.requestPermissionCalls, 1);
    expect(loc, isNotNull);
    expect(loc!.lat, 35.5);
    expect(loc.lng, 139.5);
  });

  test('locationProvider: deniedForever では request せず null', () async {
    final fake = FakeLocationService(
      permission: LocationPermission.deniedForever,
    );
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final loc = await container.read(locationProvider.future);

    expect(fake.requestPermissionCalls, 0);
    expect(loc, isNull);
  });

  test('locationProvider: 既に whileInUse なら request せず座標を返す', () async {
    final fake = FakeLocationService(
      permission: LocationPermission.whileInUse,
      position: const GeoPointPosition(35.6, 139.6),
    );
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final loc = await container.read(locationProvider.future);

    expect(fake.requestPermissionCalls, 0);
    expect(loc?.lat, 35.6);
  });
}
