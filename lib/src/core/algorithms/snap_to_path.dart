import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../../models/campus_edge.dart';

class PathSegment {
  final LatLng start;
  final LatLng end;
  final CampusEdge? edge;

  const PathSegment({
    required this.start,
    required this.end,
    this.edge,
  });
}

class SnapResult {
  final LatLng point;
  final double distanceMeters;
  final PathSegment? segment;
  final bool isSnapped;

  const SnapResult({
    required this.point,
    required this.distanceMeters,
    this.segment,
    required this.isSnapped,
  });
}

class SnapToPath {
  static const double defaultMaxRadiusMeters = 10.0;
  static const double latToMeters = 111320.0;

  static SnapResult snapPoint(
    LatLng point,
    List<PathSegment> segments, {
    double maxRadiusMeters = defaultMaxRadiusMeters,
  }) {
    if (segments.isEmpty) {
      return SnapResult(
        point: point,
        distanceMeters: 0.0,
        isSnapped: false,
      );
    }

    final latRad = point.latitude * math.pi / 180.0;
    final lngToMeters = latToMeters * math.cos(latRad);

    double minDistance = double.infinity;
    LatLng bestPoint = point;
    PathSegment? bestSegment;

    for (final seg in segments) {
      final ax = (seg.start.longitude - point.longitude) * lngToMeters;
      final ay = (seg.start.latitude - point.latitude) * latToMeters;
      final bx = (seg.end.longitude - point.longitude) * lngToMeters;
      final by = (seg.end.latitude - point.latitude) * latToMeters;

      final vx = bx - ax;
      final vy = by - ay;
      final vLenSq = vx * vx + vy * vy;

      double t;
      if (vLenSq < 1e-9) {
        t = 0.0;
      } else {
        t = ((-ax) * vx + (-ay) * vy) / vLenSq;
        if (t < 0.0) t = 0.0;
        if (t > 1.0) t = 1.0;
      }

      final qx = ax + t * vx;
      final qy = ay + t * vy;
      final dist = math.sqrt(qx * qx + qy * qy);

      if (dist < minDistance) {
        minDistance = dist;
        bestSegment = seg;
        final snappedLng = point.longitude + (qx / lngToMeters);
        final snappedLat = point.latitude + (qy / latToMeters);
        bestPoint = LatLng(snappedLat, snappedLng);
      }
    }

    if (minDistance <= maxRadiusMeters) {
      return SnapResult(
        point: bestPoint,
        distanceMeters: minDistance,
        segment: bestSegment,
        isSnapped: true,
      );
    }

    return SnapResult(
      point: point,
      distanceMeters: minDistance,
      segment: bestSegment,
      isSnapped: false,
    );
  }
}
