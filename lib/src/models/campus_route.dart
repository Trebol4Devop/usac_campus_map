import 'package:latlong2/latlong.dart';
import 'campus_building.dart';

class CampusRoute {
  final LatLng origin;
  final CampusBuilding destination;
  final List<LatLng> points;
  final double distanceInMeters;
  final Duration estimatedDuration;

  const CampusRoute({
    required this.origin,
    required this.destination,
    required this.points,
    required this.distanceInMeters,
    required this.estimatedDuration,
  });
}
