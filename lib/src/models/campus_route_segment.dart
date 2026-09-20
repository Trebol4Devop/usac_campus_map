import 'package:latlong2/latlong.dart';
import 'walkway_type.dart';

/// Segmento de una ruta peatonal clasificado por tipo de via (pasillo, camino o calle).
class CampusRouteSegment {
  /// Vertices que componen este tramo de la ruta.
  final List<LatLng> points;

  /// Tipo de via del segmento (corridor, pathway o street).
  final WalkwayType type;

  /// Longitud en metros del segmento.
  final double distanceInMeters;

  /// Instruccion o guia de navegacion para este tramo.
  final String instruction;

  const CampusRouteSegment({
    required this.points,
    required this.type,
    required this.distanceInMeters,
    required this.instruction,
  });
}
