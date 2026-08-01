import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/geo/geo_point.dart';
import '../../domain/entities/route_result.dart';

/// S-03 経路案内（§13 超軽量: タイル無しで道路グラフ Polyline 描画）。
class NavScreen extends StatefulWidget {
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
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  bool _ttsOn = true;

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final dest = route?.polyline.isNotEmpty == true
        ? route!.polyline.last
        : widget.origin;
    final bearing = _bearing(widget.origin, dest);
    final distanceM = route?.distanceM ?? _haversineM(widget.origin, dest);

    final instruction = widget.fallbackBearing || route == null
        ? '直線方位: ${bearing.toStringAsFixed(0)}°'
        : (route.instructions.isNotEmpty
              ? route.instructions.first.text
              : '直進');

    return Scaffold(
      appBar: AppBar(
        title: const Text('経路案内'),
        actions: [
          IconButton(
            icon: Icon(_ttsOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () => setState(() => _ttsOn = !_ttsOn),
          ),
        ],
      ),
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
              options: MapOptions(
                initialCenter: LatLng(widget.origin.lat, widget.origin.lng),
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
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
                      point: LatLng(widget.origin.lat, widget.origin.lng),
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
