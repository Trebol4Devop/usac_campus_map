import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../data/usac_campus_dataset.dart';
import '../models/campus_building.dart';

class CampusDistanceService {
  static const double defaultWalkingSpeed = 1.2;
  static const double defaultCampusDetourFactor = 1.2;

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

  double calculatePathDistance(List<LatLng> path) {
    if (path.length < 2) {
      return 0.0;
    }

    double total = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      total += calculateDistance(path[i], path[i + 1]);
    }
    return total;
  }

  Duration estimateWalkingDuration(
    double distanceInMeters, {
    double speedMetersPerSecond = defaultWalkingSpeed,
    double detourFactor = 1.0,
  }) {
    if (distanceInMeters <= 0 || speedMetersPerSecond <= 0) {
      return Duration.zero;
    }
    final effectiveDistance = distanceInMeters * detourFactor;
    final seconds = (effectiveDistance / speedMetersPerSecond).round();
    return Duration(seconds: seconds);
  }

  Duration estimateCampusWalkingDuration(
    double distanceInMeters, {
    double speedMetersPerSecond = defaultWalkingSpeed,
    double detourFactor = defaultCampusDetourFactor,
  }) {
    return estimateWalkingDuration(
      distanceInMeters,
      speedMetersPerSecond: speedMetersPerSecond,
      detourFactor: detourFactor,
    );
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  String formatWalkingTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return 'Inmediato';
    }
    if (totalSeconds < 45) {
      return '< 1 min';
    }

    final totalMinutes = (totalSeconds / 60.0).round();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    if (remainingMinutes == 0) {
      return '$hours h';
    }
    return '$hours h $remainingMinutes min';
  }

  List<CampusBuildingDistance> rankBuildingsByProximity({
    required LatLng from,
    List<CampusBuilding>? buildings,
    double maxDistanceMeters = double.infinity,
    bool applyCampusDetour = false,
  }) {
    final source = buildings ?? UsacCampusDataset.allBuildings;
    final results = <CampusBuildingDistance>[];

    for (final building in source) {
      final distance = calculateBuildingDistance(from, building);
      if (distance <= maxDistanceMeters) {
        final duration = applyCampusDetour
            ? estimateCampusWalkingDuration(distance)
            : estimateWalkingDuration(distance);
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
