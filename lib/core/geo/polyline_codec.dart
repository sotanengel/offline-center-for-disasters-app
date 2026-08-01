import 'geo_point.dart';

/// Google Polyline Encoding（§14.2 edges.geometry BLOB と同じ形式）。
/// tools/packgen/polyline.py と相互運用できること。
String encodePolyline(List<GeoPoint> points) {
  final out = StringBuffer();
  var prevLat = 0;
  var prevLng = 0;
  for (final p in points) {
    final lat = (p.lat * 1e5).round();
    final lng = (p.lng * 1e5).round();
    _encodeValue(lat - prevLat, out);
    _encodeValue(lng - prevLng, out);
    prevLat = lat;
    prevLng = lng;
  }
  return out.toString();
}

List<GeoPoint> decodePolyline(String encoded) {
  final points = <GeoPoint>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  while (index < encoded.length) {
    final dLat = _decodeValue(encoded, index);
    lat += dLat.value;
    index = dLat.nextIndex;
    final dLng = _decodeValue(encoded, index);
    lng += dLng.value;
    index = dLng.nextIndex;
    points.add(GeoPoint(lat / 1e5, lng / 1e5));
  }
  return points;
}

void _encodeValue(int value, StringBuffer out) {
  var v = value < 0 ? ~(value << 1) : value << 1;
  while (v >= 0x20) {
    out.writeCharCode((0x20 | (v & 0x1f)) + 63);
    v >>= 5;
  }
  out.writeCharCode(v + 63);
}

({int value, int nextIndex}) _decodeValue(String encoded, int start) {
  var result = 0;
  var shift = 0;
  var index = start;
  int byte;
  do {
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20);
  final value = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  return (value: value, nextIndex: index);
}
