import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import '../core/algorithms/a_star.dart';
import '../core/algorithms/snap_to_path.dart';
import '../core/utils/distance_calculator.dart';
import '../models/campus_building.dart';
import '../models/campus_node.dart';
import '../models/campus_route.dart';
import '../models/navigation_mode.dart';
import 'campus_data_repository.dart';

class RouteEngine {
  final CampusDataRepository repository;
  late final List<PathSegment> _pathSegments;

  RouteEngine({required this.repository}) {
    _initPathSegments();
  }

  void _initPathSegments() {
    final segments = <PathSegment>[];
    for (final edge in repository.edges) {
      final startNode = repository.nodesById[edge.source];
      final endNode = repository.nodesById[edge.target];
      if (startNode != null && endNode != null) {
        segments.add(
          PathSegment(
            start: startNode.location,
            end: endNode.location,
            edge: edge,
          ),
        );
      }
    }
    _pathSegments = segments;
  }

  SnapResult snapCoordinate(
    LatLng point, {
    double maxRadiusMeters = SnapToPath.defaultMaxRadiusMeters,
  }) {
    return SnapToPath.snapPoint(
      point,
      _pathSegments,
      maxRadiusMeters: maxRadiusMeters,
    );
  }

  CampusRoute? findRoute({
    required LatLng origin,
    required String destinationId,
    NavigationMode mode = NavigationMode.pedestrian,
  }) {
    if (!repository.isLoaded || repository.nodes.isEmpty) {
      return null;
    }

    final snap = snapCoordinate(origin);
    final effectiveOrigin = snap.point;

    final startNode = _findNearestNode(effectiveOrigin, mode: mode);
    if (startNode == null) {
      return null;
    }

    final targetNodeIds = _resolveDestinationNodeIds(
      destinationId,
      referenceOrigin: effectiveOrigin,
      mode: mode,
    );

    if (targetNodeIds.isEmpty) {
      return null;
    }

    final aStar = AStar(
      nodes: repository.nodesById,
      adjacencyList: repository.adjacencyList,
    );

    final route = aStar.findShortestPath(
      startNodeId: startNode.id,
      targetNodeIds: targetNodeIds,
      mode: mode,
    );

    if (route == null) {
      return null;
    }

    final allPoints = <LatLng>[];
    if (DistanceCalculator.haversineDistance(origin, route.points.first) > 2.0) {
      allPoints.add(origin);
    }
    allPoints.addAll(route.points);

    return CampusRoute(
      points: allPoints,
      nodes: route.nodes,
      edges: route.edges,
      totalDistance: route.totalDistance,
      estimatedTimeMinutes: route.estimatedTimeMinutes,
      mode: route.mode,
      steps: route.steps,
    );
  }

  CampusRoute? findRouteBetweenBuildings({
    required String originBuildingId,
    required String destinationBuildingId,
    NavigationMode mode = NavigationMode.pedestrian,
  }) {
    final originBuilding = repository.buildingsById[originBuildingId];
    if (originBuilding == null) return null;

    final candidateOrigins = originBuilding.entrances.isNotEmpty
        ? originBuilding.entrances.map((e) => e.location).toList()
        : [originBuilding.center];

    CampusRoute? bestRoute;
    for (final originLoc in candidateOrigins) {
      final route = findRoute(
        origin: originLoc,
        destinationId: destinationBuildingId,
        mode: mode,
      );
      if (route != null) {
        if (bestRoute == null || route.totalDistance < bestRoute.totalDistance) {
          bestRoute = route;
        }
      }
    }

    return bestRoute;
  }

  Set<String> _resolveDestinationNodeIds(
    String destinationId, {
    required LatLng referenceOrigin,
    required NavigationMode mode,
  }) {
    final building = repository.buildingsById[destinationId];
    if (building != null) {
      return _getNodeIdsForBuilding(building, referenceOrigin: referenceOrigin);
    }

    final poi = repository.poisById[destinationId];
    if (poi != null) {
      final parentBuilding = repository.buildingsById[poi.buildingId];
      if (parentBuilding != null) {
        return _getNodeIdsForBuilding(
          parentBuilding,
          referenceOrigin: referenceOrigin,
        );
      }
      if (poi.location != null) {
        final node = _findNearestNode(poi.location!, mode: mode);
        if (node != null) return {node.id};
      }
    }

    if (repository.nodesById.containsKey(destinationId)) {
      return {destinationId};
    }

    final nearest = _findNearestNode(referenceOrigin, mode: mode);
    return nearest != null ? {nearest.id} : const <String>{};
  }

  Set<String> _getNodeIdsForBuilding(
    CampusBuilding building, {
    required LatLng referenceOrigin,
  }) {
    final targetIds = <String>{};

    if (building.entrances.isNotEmpty) {
      final sortedEntrances = List<BuildingEntrance>.from(building.entrances);
      sortedEntrances.sort((a, b) {
        final distA = DistanceCalculator.haversineDistance(
          referenceOrigin,
          a.location,
        );
        final distB = DistanceCalculator.haversineDistance(
          referenceOrigin,
          b.location,
        );
        return distA.compareTo(distB);
      });

      for (final entrance in sortedEntrances) {
        if (entrance.nearestNodeId != null &&
            repository.nodesById.containsKey(entrance.nearestNodeId)) {
          targetIds.add(entrance.nearestNodeId!);
        } else {
          final nearNode = _findNearestNode(entrance.location);
          if (nearNode != null) {
            targetIds.add(nearNode.id);
          }
        }
      }
    }

    if (targetIds.isEmpty) {
      final centerNode = _findNearestNode(building.center);
      if (centerNode != null) {
        targetIds.add(centerNode.id);
      }
    }

    return targetIds;
  }

  CampusNode? _findNearestNode(
    LatLng point, {
    NavigationMode mode = NavigationMode.pedestrian,
  }) {
    CampusNode? nearest;
    double minDistance = double.infinity;

    for (final node in repository.nodes) {
      if (mode == NavigationMode.vehicle) {
        final edges = repository.adjacencyList[node.id] ?? const [];
        final hasRoadway = edges.any((e) => e.type == 'roadway');
        if (!hasRoadway) continue;
      }

      final d = DistanceCalculator.haversineDistance(point, node.location);
      if (d < minDistance) {
        minDistance = d;
        nearest = node;
      }
    }

    return nearest;
  }
}
