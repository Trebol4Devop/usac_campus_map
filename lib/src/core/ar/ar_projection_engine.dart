import 'dart:math';
import 'dart:ui';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import '../utils/distance_calculator.dart';
import '../../models/ar_waypoint.dart';

class ArProjectionEngine {
  final double horizontalFov;
  final double verticalFov;

  const ArProjectionEngine({
    this.horizontalFov = 60.0,
    this.verticalFov = 45.0,
  });

  ArProjectionResult projectWaypoint({
    required LatLng userLocation,
    required double deviceHeading,
    required ArWaypoint waypoint,
    double devicePitch = 0.0,
    double userAltitude = 0.0,
    Size screenSize = const Size(360.0, 640.0),
  }) {
    final distanceMeters = DistanceCalculator.haversineDistance(
      userLocation,
      waypoint.location,
    );

    final targetBearing = DistanceCalculator.calculateBearing(
      userLocation,
      waypoint.location,
    );

    final relativeAzimuth =
        ((targetBearing - deviceHeading + 540.0) % 360.0) - 180.0;

    final altitudeDelta = waypoint.altitude - userAltitude;
    final targetPitch = distanceMeters > 0.0
        ? (atan2(altitudeDelta, distanceMeters) * 180.0 / pi)
        : 0.0;
    final relativePitch = targetPitch - devicePitch;

    final halfH = horizontalFov / 2.0;
    final halfV = verticalFov / 2.0;

    final isVisibleInFov =
        relativeAzimuth.abs() <= halfH && relativePitch.abs() <= halfV;

    final normX = (relativeAzimuth / halfH).clamp(-1.0, 1.0);
    final normY = (-relativePitch / halfV).clamp(-1.0, 1.0);

    final screenX = (screenSize.width / 2.0) + (normX * (screenSize.width / 2.0));
    final screenY =
        (screenSize.height / 2.0) + (normY * (screenSize.height / 2.0));

    final indicatorAngle = atan2(normY, normX);

    return ArProjectionResult(
      waypoint: waypoint,
      distanceMeters: distanceMeters,
      targetBearing: targetBearing,
      relativeAzimuth: relativeAzimuth,
      relativePitch: relativePitch,
      screenPosition: Offset(screenX, screenY),
      isVisibleInFov: isVisibleInFov,
      indicatorAngle: indicatorAngle,
    );
  }

  List<ArProjectionResult> projectWaypoints({
    required LatLng userLocation,
    required double deviceHeading,
    required List<ArWaypoint> waypoints,
    double devicePitch = 0.0,
    double userAltitude = 0.0,
    Size screenSize = const Size(360.0, 640.0),
  }) {
    final results = waypoints.map((w) {
      return projectWaypoint(
        userLocation: userLocation,
        deviceHeading: deviceHeading,
        waypoint: w,
        devicePitch: devicePitch,
        userAltitude: userAltitude,
        screenSize: screenSize,
      );
    }).toList();

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }
}
