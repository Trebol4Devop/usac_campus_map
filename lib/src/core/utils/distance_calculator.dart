import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class DistanceCalculator {
  static const double earthRadiusMeters = 6371000.0;

  static double haversineDistance(LatLng p1, LatLng p2) {
    final lat1Rad = _toRadians(p1.latitude);
    final lat2Rad = _toRadians(p2.latitude);
    final deltaLatRad = _toRadians(p2.latitude - p1.latitude);
    final deltaLngRad = _toRadians(p2.longitude - p1.longitude);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double calculateBearing(LatLng start, LatLng end) {
    final startLat = _toRadians(start.latitude);
    final startLng = _toRadians(start.longitude);
    final endLat = _toRadians(end.latitude);
    final endLng = _toRadians(end.longitude);

    final dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    final initialBearing = math.atan2(y, x);
    return (_toDegrees(initialBearing) + 360.0) % 360.0;
  }

  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    final nvert = polygon.length;
    int j = nvert - 1;

    for (int i = 0; i < nvert; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

      final intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;
  static double _toDegrees(double radian) => radian * 180.0 / math.pi;
}
