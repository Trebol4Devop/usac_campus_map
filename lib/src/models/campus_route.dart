import 'package:latlong2/latlong.dart';
import 'campus_edge.dart';
import 'campus_node.dart';
import 'navigation_mode.dart';

class RouteStep {
  final String instruction;
  final double distance;
  final String type;
  final LatLng location;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.type,
    required this.location,
  });

  double get distanceMeters => distance;
  LatLng get coordinate => location;
}

class CampusRoute {
  final List<LatLng> points;
  final List<CampusNode> nodes;
  final List<CampusEdge> edges;
  final double totalDistance;
  final double estimatedTimeMinutes;
  final NavigationMode mode;
  final List<RouteStep> steps;

  const CampusRoute({
    required this.points,
    required this.nodes,
    required this.edges,
    required this.totalDistance,
    required this.estimatedTimeMinutes,
    required this.mode,
    this.steps = const [],
  });

  List<LatLng> get polyline => points;
  double get totalDistanceMeters => totalDistance;

  bool get hasStairs => edges.any((e) => e.type == 'stairs');

  bool get isCoveredOnly =>
      edges.isNotEmpty && edges.every((e) => e.type == 'covered');
}
