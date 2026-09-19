import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../data/usac_campus_dataset.dart';
import '../models/campus_building.dart';

class CampusDistanceService {
  static const double defaultWalkingSpeed = 1.2;

  double calculateDistance(LatLng from, LatLng to) {
    const earthRadius = 6371000.0;

    final dLat = _degToRad(to.latitude - from.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(from.latitude)) *
            math.cos(_degToRad(to.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double calculateBuildingDistance(LatLng from, CampusBuilding building) {
    return calculateDistance(from, building.location);
  }

  Duration estimateWalkingDuration(
    double distanceInMeters, {
    double speedMetersPerSecond = defaultWalkingSpeed,
  }) {
    if (distanceInMeters <= 0 || speedMetersPerSecond <= 0) {
      return Duration.zero;
    }
    final seconds = (distanceInMeters / speedMetersPerSecond).round();
    return Duration(seconds: seconds);
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  String formatWalkingTime(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 1) {
      return '< 1 min';
    }
    return '$minutes min';
  }

  List<CampusBuildingDistance> rankBuildingsByProximity({
    required LatLng from,
    List<CampusBuilding>? buildings,
    double maxDistanceMeters = double.infinity,
  }) {
    final source = buildings ?? UsacCampusDataset.allBuildings;
    final results = <CampusBuildingDistance>[];

    for (final building in source) {
      final distance = calculateBuildingDistance(from, building);
      if (distance <= maxDistanceMeters) {
        final duration = estimateWalkingDuration(distance);
        results.add(
          CampusBuildingDistance(
            building: building,
            distanceInMeters: distance,
            walkingDuration: duration,
          ),
        );
      }
    }

    results.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
    return results;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}

class CampusBuildingDistance {
  final CampusBuilding building;
  final double distanceInMeters;
  final Duration walkingDuration;

  const CampusBuildingDistance({
    required this.building,
    required this.distanceInMeters,
    required this.walkingDuration,
  });
}
