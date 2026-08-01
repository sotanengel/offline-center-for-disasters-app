import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:offline_center_for_disasters/data/location/location_service.dart';

/// テスト用 LocationService。
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.serviceEnabled = true,
    this.permission = LocationPermission.denied,
    this.permissionAfterRequest = LocationPermission.whileInUse,
    this.position = const GeoPointPosition(35.687741, 139.850977),
  }) : _positionController = StreamController<GeoPointPosition>.broadcast();

  bool serviceEnabled;
  LocationPermission permission;
  LocationPermission permissionAfterRequest;
  GeoPointPosition position;
  int requestPermissionCalls = 0;
  int checkPermissionCalls = 0;
  final StreamController<GeoPointPosition> _positionController;

  void emitPosition(GeoPointPosition next) {
    position = next;
    _positionController.add(next);
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCalls++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls++;
    permission = permissionAfterRequest;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings locationSettings = const LocationSettings(),
  }) async {
    return _toPosition(position);
  }

  @override
  Stream<Position> getPositionStream({
    LocationSettings locationSettings = const LocationSettings(),
  }) {
    return _positionController.stream.map(_toPosition);
  }

  Position _toPosition(GeoPointPosition p) {
    return Position(
      latitude: p.lat,
      longitude: p.lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  void dispose() {
    _positionController.close();
  }
}

/// FakeLocationService 用の軽量座標。
class GeoPointPosition {
  const GeoPointPosition(this.lat, this.lng);
  final double lat;
  final double lng;
}
