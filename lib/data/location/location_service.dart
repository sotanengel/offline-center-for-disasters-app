import 'package:geolocator/geolocator.dart';

/// 位置情報取得の抽象（テストで差し替え可能）。
abstract interface class LocationService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition({
    LocationSettings locationSettings = const LocationSettings(),
  });
}

/// Geolocator への委譲実装。
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition({
    LocationSettings locationSettings = const LocationSettings(),
  }) => Geolocator.getCurrentPosition(locationSettings: locationSettings);
}
