import 'dart:ui';
import 'package:latlong2/latlong.dart';

class ArWaypoint {
  final String id;
  final String title;
  final String? subtitle;
  final LatLng location;
  final double altitude;
  final String type;
  final Map<String, dynamic>? metadata;

  const ArWaypoint({
    required this.id,
    required this.title,
    this.subtitle,
    required this.location,
    this.altitude = 0.0,
    this.type = 'building',
    this.metadata,
  });
}

class ArProjectionResult {
  final ArWaypoint waypoint;
  final double distanceMeters;
  final double targetBearing;
  final double relativeAzimuth;
  final double relativePitch;
  final Offset screenPosition;
  final bool isVisibleInFov;
  final double indicatorAngle;

  const ArProjectionResult({
    required this.waypoint,
    required this.distanceMeters,
    required this.targetBearing,
    required this.relativeAzimuth,
    required this.relativePitch,
    required this.screenPosition,
    required this.isVisibleInFov,
    required this.indicatorAngle,
  });
}
