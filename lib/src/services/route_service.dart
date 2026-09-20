import 'package:latlong2/latlong.dart';
import '../data/usac_campus_boundary.dart';
import '../data/usac_campus_dataset.dart';
import '../models/campus_building.dart';
import '../models/campus_route.dart';
import 'distance_service.dart';

class CampusRouteService {
  final CampusDistanceService _distanceService = CampusDistanceService();

  static const List<LatLng> _primaryWalkwayHubs = [
    LatLng(14.587500, -90.551845),
    LatLng(14.588146, -90.551704),
    LatLng(14.586838, -90.551859),
    LatLng(14.588300, -90.553000),
    LatLng(14.587400, -90.553200),
    LatLng(14.586900, -90.553500),
    LatLng(14.585500, -90.553300),
    LatLng(14.587050, -90.549800),
    LatLng(14.586700, -90.550500),
    LatLng(14.586200, -90.550000),
    LatLng(14.588200, -90.549600),
    LatLng(14.586000, -90.548000),
    LatLng(14.583924, -90.555003),
    LatLng(14.583500, -90.554800),
    LatLng(14.588497, -90.547154),
    LatLng(14.588200, -90.547800),
    LatLng(14.589839, -90.549338),
    LatLng(14.589000, -90.549500),
  ];

  CampusRoute? calculateRoute({
    required LatLng origin,
    required CampusBuilding destination,
  }) {
    if (!UsacCampusBoundary.isInsideCampus(origin) ||
        !UsacCampusBoundary.isInsideCampus(destination.location)) {
      return null;
    }

    final directDistance =
        _distanceService.calculateDistance(origin, destination.location);

    if (directDistance <= 65.0) {
      final points = <LatLng>[origin, destination.location];
      final duration =
          _distanceService.estimateWalkingDuration(directDistance);
      return CampusRoute(
        origin: origin,
        destination: destination,
        points: points,
        distanceInMeters: directDistance,
        estimatedDuration: duration,
      );
    }

    final originHub = _findClosestHub(origin);
    final destinationHub = _findClosestHub(destination.location);

    final points = <LatLng>[origin];

    if (originHub != null &&
        _distanceService.calculateDistance(origin, originHub) > 15.0) {
      points.add(originHub);
    }

    if (originHub != null &&
        destinationHub != null &&
        originHub != destinationHub) {
      final intermediateHubs = _findIntermediateHubs(originHub, destinationHub);
      points.addAll(intermediateHubs);
    }

    if (destinationHub != null &&
        _distanceService.calculateDistance(
                destinationHub, destination.location) >
            15.0 &&
        !points.contains(destinationHub)) {
      points.add(destinationHub);
    }

    if (!points.contains(destination.location)) {
      points.add(destination.location);
    }

    final totalDistance = _distanceService.calculatePathDistance(points);
    final duration =
        _distanceService.estimateWalkingDuration(totalDistance);

    return CampusRoute(
      origin: origin,
      destination: destination,
      points: points,
      distanceInMeters: totalDistance,
      estimatedDuration: duration,
    );
  }

  CampusRoute? calculateRouteBetweenBuildings({
    required CampusBuilding origin,
    required CampusBuilding destination,
  }) {
    return calculateRoute(
      origin: origin.location,
      destination: destination,
    );
  }

  CampusRoute? calculateRouteToCoordinates({
    required LatLng origin,
    required LatLng destinationCoords,
    String? destinationName,
  }) {
    if (!UsacCampusBoundary.isInsideCampus(origin) ||
        !UsacCampusBoundary.isInsideCampus(destinationCoords)) {
      return null;
    }

    final targetBuilding = UsacCampusDataset.allBuildings.firstWhere(
      (b) =>
          _distanceService.calculateDistance(b.location, destinationCoords) <
          30.0,
      orElse: () => CampusBuilding(
        id: 'target-coords',
        name: destinationName ?? 'Destino en campus',
        location: destinationCoords,
        description: 'Ubicacion personalizada en el campus',
      ),
    );

    return calculateRoute(origin: origin, destination: targetBuilding);
  }

  LatLng? _findClosestHub(LatLng point) {
    if (_primaryWalkwayHubs.isEmpty) {
      return null;
    }

    LatLng? closest;
    double minDistance = double.infinity;

    for (final hub in _primaryWalkwayHubs) {
      final d = _distanceService.calculateDistance(point, hub);
      if (d < minDistance) {
        minDistance = d;
        closest = hub;
      }
    }

    return closest;
  }

  List<LatLng> _findIntermediateHubs(LatLng startHub, LatLng endHub) {
    const centralHub = LatLng(14.587500, -90.551845);
    final results = <LatLng>[];

    final distanceDirect =
        _distanceService.calculateDistance(startHub, endHub);
    final distanceViaCenter =
        _distanceService.calculateDistance(startHub, centralHub) +
            _distanceService.calculateDistance(centralHub, endHub);

    if (distanceViaCenter < distanceDirect * 1.3 &&
        startHub != centralHub &&
        endHub != centralHub) {
      results.add(centralHub);
    }

    return results;
  }
}
