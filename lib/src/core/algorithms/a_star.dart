import '../../models/campus_edge.dart';
import '../../models/campus_node.dart';
import '../../models/campus_route.dart';
import '../../models/navigation_mode.dart';
import '../utils/distance_calculator.dart';
import 'priority_queue.dart';

class AStar {
  final Map<String, CampusNode> nodes;
  final Map<String, List<CampusEdge>> adjacencyList;

  AStar({
    required this.nodes,
    required this.adjacencyList,
  });

  CampusRoute? findShortestPath({
    required String startNodeId,
    required Set<String> targetNodeIds,
    required NavigationMode mode,
  }) {
    if (!nodes.containsKey(startNodeId) || targetNodeIds.isEmpty) {
      return null;
    }

    final validTargets = targetNodeIds.where(nodes.containsKey).toSet();
    if (validTargets.isEmpty) {
      return null;
    }

    if (validTargets.contains(startNodeId)) {
      final node = nodes[startNodeId]!;
      return CampusRoute(
        points: [node.location],
        nodes: [node],
        edges: const [],
        totalDistance: 0.0,
        estimatedTimeMinutes: 0.0,
        mode: mode,
        steps: [
          RouteStep(
            instruction: 'Se encuentra en el destino',
            distance: 0.0,
            type: 'arrive',
            location: node.location,
          ),
        ],
      );
    }

    final distances = <String, double>{startNodeId: 0.0};
    final previousNode = <String, String>{};
    final previousEdge = <String, CampusEdge>{};
    final openSet = PriorityQueue<String>();
    final closedSet = <String>{};

    openSet.enqueue(
      startNodeId,
      _heuristic(startNodeId, validTargets, mode),
    );

    String? reachedTarget;

    while (openSet.isNotEmpty) {
      final currentId = openSet.dequeue();

      if (validTargets.contains(currentId)) {
        reachedTarget = currentId;
        break;
      }

      if (closedSet.contains(currentId)) {
        continue;
      }
      closedSet.add(currentId);

      final currentDist = distances[currentId] ?? double.infinity;
      final edges = adjacencyList[currentId] ?? const [];

      for (final edge in edges) {
        final neighborId = edge.target;
        if (closedSet.contains(neighborId)) {
          continue;
        }

        final edgeCost = _calculateEdgeWeight(edge, mode);
        if (edgeCost == double.infinity) {
          continue;
        }

        final tentativeDist = currentDist + edgeCost;
        final neighborDist = distances[neighborId] ?? double.infinity;

        if (tentativeDist < neighborDist) {
          distances[neighborId] = tentativeDist;
          previousNode[neighborId] = currentId;
          previousEdge[neighborId] = edge;

          final priority =
              tentativeDist + _heuristic(neighborId, validTargets, mode);
          openSet.enqueue(neighborId, priority);
        }
      }
    }

    if (reachedTarget == null) {
      return null;
    }

    return _reconstructRoute(
      startNodeId: startNodeId,
      targetNodeId: reachedTarget,
      previousNode: previousNode,
      previousEdge: previousEdge,
      mode: mode,
    );
  }

  double _calculateEdgeWeight(CampusEdge edge, NavigationMode mode) {
    switch (mode) {
      case NavigationMode.accessible:
        if (edge.type == 'stairs') {
          return double.infinity;
        }
        return edge.weight;

      case NavigationMode.covered:
        if (edge.type == 'covered') {
          return edge.weight * 0.4;
        }
        return edge.weight * 1.5;

      case NavigationMode.vehicle:
        if (edge.type != 'roadway') {
          return double.infinity;
        }
        return edge.weight;

      case NavigationMode.pedestrian:
        if (edge.type == 'stairs') {
          return edge.weight * 1.05;
        }
        if (edge.type == 'roadway') {
          return edge.weight * 1.1;
        }
        return edge.weight;
    }
  }

  double _heuristic(
    String fromId,
    Set<String> targetIds,
    NavigationMode mode,
  ) {
    final fromNode = nodes[fromId];
    if (fromNode == null) return double.infinity;

    double minDistance = double.infinity;
    for (final targetId in targetIds) {
      final targetNode = nodes[targetId];
      if (targetNode != null) {
        final d = DistanceCalculator.haversineDistance(
          fromNode.location,
          targetNode.location,
        );
        if (d < minDistance) {
          minDistance = d;
        }
      }
    }

    if (mode == NavigationMode.covered) {
      return minDistance * 0.4;
    }
    return minDistance;
  }

  CampusRoute _reconstructRoute({
    required String startNodeId,
    required String targetNodeId,
    required Map<String, String> previousNode,
    required Map<String, CampusEdge> previousEdge,
    required NavigationMode mode,
  }) {
    final pathNodeIds = <String>[targetNodeId];
    final pathEdges = <CampusEdge>[];

    var curr = targetNodeId;
    while (curr != startNodeId) {
      final prev = previousNode[curr];
      final edge = previousEdge[curr];
      if (prev == null || edge == null) {
        break;
      }
      pathEdges.add(edge);
      curr = prev;
      pathNodeIds.add(curr);
    }

    final reversedNodeIds = pathNodeIds.reversed.toList();
    final reversedEdges = pathEdges.reversed.toList();

    final pathNodes =
        reversedNodeIds.map((id) => nodes[id]!).toList(growable: false);
    final points = pathNodes.map((n) => n.location).toList(growable: false);

    double totalRealDistance = 0.0;
    for (final edge in reversedEdges) {
      totalRealDistance += edge.weight;
    }

    final speedMetersPerMinute = mode == NavigationMode.vehicle ? 500.0 : 80.0;
    final estimatedMinutes = totalRealDistance / speedMetersPerMinute;

    final steps = _generateSteps(pathNodes, reversedEdges);

    return CampusRoute(
      points: points,
      nodes: pathNodes,
      edges: reversedEdges,
      totalDistance: totalRealDistance,
      estimatedTimeMinutes: estimatedMinutes,
      mode: mode,
      steps: steps,
    );
  }

  List<RouteStep> _generateSteps(
    List<CampusNode> routeNodes,
    List<CampusEdge> routeEdges,
  ) {
    if (routeNodes.isEmpty) return const [];
    if (routeNodes.length == 1) {
      return [
        RouteStep(
          instruction: 'Destino',
          distance: 0.0,
          type: 'arrive',
          location: routeNodes.first.location,
        ),
      ];
    }

    final steps = <RouteStep>[];
    steps.add(
      RouteStep(
        instruction: 'Inicie el recorrido hacia ${routeEdges.first.type}',
        distance: routeEdges.first.weight,
        type: routeEdges.first.type,
        location: routeNodes.first.location,
      ),
    );

    for (int i = 1; i < routeEdges.length; i++) {
      final prevNode = routeNodes[i - 1];
      final currNode = routeNodes[i];
      final nextNode = routeNodes[i + 1];
      final currentEdge = routeEdges[i];

      final bearing1 = DistanceCalculator.calculateBearing(
        prevNode.location,
        currNode.location,
      );
      final bearing2 = DistanceCalculator.calculateBearing(
        currNode.location,
        nextNode.location,
      );

      final diff = ((bearing2 - bearing1 + 540) % 360) - 180;
      String turn;
      if (currentEdge.type == 'stairs') {
        turn = 'Suba o baje gradas';
      } else if (currentEdge.type == 'covered') {
        turn = 'Continúe por pasillo techado';
      } else if (diff < -45) {
        turn = 'Gire a la izquierda';
      } else if (diff > 45) {
        turn = 'Gire a la derecha';
      } else {
        turn = 'Continúe recto';
      }

      steps.add(
        RouteStep(
          instruction: '$turn (${currentEdge.weight.toStringAsFixed(0)} m)',
          distance: currentEdge.weight,
          type: currentEdge.type,
          location: currNode.location,
        ),
      );
    }

    steps.add(
      RouteStep(
        instruction: 'Ha llegado a su destino',
        distance: 0.0,
        type: 'arrive',
        location: routeNodes.last.location,
      ),
    );

    return steps;
  }
}
