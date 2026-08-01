import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/geo/geo_bounds.dart';
import '../../core/geo/geo_point.dart';
import '../../core/geo/route_progress.dart';
import '../../data/routing/road_graph.dart';
import '../../domain/entities/route_result.dart';
import '../../domain/usecases/destination_planner.dart';
import 'road_graph_polylines.dart';

/// 地図背景色（§13 超軽量モード: タイルの代わり）。
const kNavMapBackgroundColor = Color(0xFFE8E4DC);

/// S-03 経路案内（§13 超軽量: タイル無しで道路グラフ Polyline 描画）。
class NavScreen extends ConsumerStatefulWidget {
  const NavScreen({
    super.key,
    required this.route,
    required this.origin,
    this.fallbackBearing = false,
  });

  final RouteResult? route;
  final GeoPoint origin;
  final bool fallbackBearing;

  @override
  ConsumerState<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends ConsumerState<NavScreen> {
  final _mapController = MapController();
  RoadGraph? _roadGraph;
  var _cameraFitted = false;
  GeoPoint? _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.origin;
    _loadRoadGraph();
  }

  Future<void> _loadRoadGraph() async {
    final pack = await ref.read(dataPackProvider.future);
    if (!mounted || pack == null) return;

    final bounds = _graphBounds();
    try {
      final graph = await pack.loadGraph(bounds: bounds);
      if (!mounted) return;
      setState(() => _roadGraph = graph);
      _fitCameraToRoute();
    } catch (_) {
      // グラフ読込失敗時は経路 polyline のみ表示（現状互換）。
    }
  }

  GeoBounds _graphBounds() {
    final route = widget.route;
    if (route != null && route.polyline.isNotEmpty) {
      final dest = route.polyline.last;
      return routeGraphBoundsFor(widget.origin, dest);
    }
    return GeoBounds.aroundPoint(widget.origin, radiusKm: 2);
  }

  void _fitCameraToRoute() {
    if (_cameraFitted) return;
    final points = _cameraPoints();
    if (points.length < 2) return;

    final bounds = LatLngBounds.fromPoints([
      for (final p in points) LatLng(p.lat, p.lng),
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: EdgeInsets.zero),
    );
    _cameraFitted = true;
  }

  List<GeoPoint> _cameraPoints() {
    final route = widget.route;
    if (route != null && route.polyline.length >= 2) {
      return route.polyline;
    }
    return [_currentPosition ?? widget.origin];
  }

  GeoPoint get _displayPosition => _currentPosition ?? widget.origin;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<GeoPoint?>>(positionStreamProvider, (_, next) {
      next.whenData((point) {
        if (point == null || !mounted) return;
        setState(() => _currentPosition = point);
      });
    });

    final route = widget.route;
    final position = _displayPosition;
    final dest = route?.polyline.isNotEmpty == true
        ? route!.polyline.last
        : widget.origin;
    final bearing = _bearing(position, dest);
    final distanceM = _remainingDistanceM(route, position, dest);
    final instruction = _instructionText(route, position, bearing);

    final roadPolylines = _roadGraph == null
        ? const <Polyline>[]
        : roadGraphToPolylines(_roadGraph!);

    return Scaffold(
      appBar: AppBar(title: const Text('経路案内')),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    size: 96,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '残り ${(distanceM / 1000).toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(position.lat, position.lng),
                initialZoom: 14,
                backgroundColor: kNavMapBackgroundColor,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onMapReady: _fitCameraToRoute,
              ),
              children: [
                if (roadPolylines.isNotEmpty)
                  PolylineLayer(polylines: roadPolylines),
                if (route != null && route.polyline.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          for (final p in route.polyline) LatLng(p.lat, p.lng),
                        ],
                        strokeWidth: 4,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(position.lat, position.lng),
                      width: 24,
                      height: 24,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                      ),
                    ),
                    if (route != null && route.polyline.isNotEmpty)
                      Marker(
                        point: LatLng(
                          route.polyline.last.lat,
                          route.polyline.last.lng,
                        ),
                        width: 24,
                        height: 24,
                        child: const Icon(Icons.place, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _remainingDistanceM(
    RouteResult? route,
    GeoPoint position,
    GeoPoint dest,
  ) {
    if (route != null && route.polyline.length >= 2) {
      return remainingDistanceM(position, route.polyline);
    }
    return _haversineM(position, dest);
  }

  String _instructionText(
    RouteResult? route,
    GeoPoint position,
    double bearing,
  ) {
    if (widget.fallbackBearing || route == null) {
      return '直線方位: ${bearing.toStringAsFixed(0)}°';
    }
    if (route.instructions.isNotEmpty && route.polyline.length >= 2) {
      final traveled = traveledDistanceM(position, route.polyline);
      final active = activeInstruction(route.instructions, traveled);
      if (active != null) return active.text;
    }
    return route.instructions.isNotEmpty ? route.instructions.first.text : '直進';
  }

  double _bearing(GeoPoint from, GeoPoint to) {
    final lat1 = from.lat * math.pi / 180;
    final lat2 = to.lat * math.pi / 180;
    final dLng = (to.lng - from.lng) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _haversineM(GeoPoint a, GeoPoint b) {
    const r = 6371000.0;
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }
}
