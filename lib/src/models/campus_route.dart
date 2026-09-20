import 'package:latlong2/latlong.dart';
import 'building_entrance.dart';
import 'campus_building.dart';
import 'campus_route_segment.dart';
import 'walkway_type.dart';

class CampusRoute {
  final LatLng origin;
  final CampusBuilding destination;
  final List<LatLng> points;
  final double distanceInMeters;
  final Duration estimatedDuration;

  /// Puerta o salida utilizada para iniciar la ruta (si inicio en un edificio).
  final BuildingEntrance? startEntrance;

  /// Puerta o entrada oficial de llegada en el edificio de destino.
  final BuildingEntrance? destinationEntrance;

  /// Tramos clasificados de la ruta (pasillos techados, caminos peatonales y calles).
  final List<CampusRouteSegment> segments;

  /// Pasos secuenciales de navegacion peatonal en el campus.
  final List<String> steps;

  const CampusRoute({
    required this.origin,
    required this.destination,
    required this.points,
    required this.distanceInMeters,
    required this.estimatedDuration,
    this.startEntrance,
    this.destinationEntrance,
    this.segments = const [],
    this.steps = const [],
  });

  /// Distancia total transitada bajo pasillos techados y breezeways protegidos (en metros).
  double get corridorDistanceInMeters => segments
      .where((s) => s.type == WalkwayType.corridor)
      .fold(0.0, (sum, s) => sum + s.distanceInMeters);

  /// Distancia total transitada por caminos peatonales y plazoletas (en metros).
  double get pathwayDistanceInMeters => segments
      .where((s) => s.type == WalkwayType.pathway)
      .fold(0.0, (sum, s) => sum + s.distanceInMeters);

  /// Distancia total transitada por aceras de calles vehiculares internas (en metros).
  double get streetDistanceInMeters => segments
      .where((s) => s.type == WalkwayType.street)
      .fold(0.0, (sum, s) => sum + s.distanceInMeters);
}
