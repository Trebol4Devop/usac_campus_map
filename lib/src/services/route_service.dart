import 'package:latlong2/latlong.dart';
import '../data/usac_campus_boundary.dart';
import '../data/usac_campus_dataset.dart';
import '../data/usac_campus_walkway_graph.dart';
import '../models/building_entrance.dart';
import '../models/campus_building.dart';
import '../models/campus_route.dart';
import '../models/campus_route_segment.dart';
import '../models/walkway_type.dart';
import 'distance_service.dart';

/// Servicio de navegacion peatonal de alta precision para el Campus Central de la USAC.
/// Utiliza Teoria de Grafos y el algoritmo A* ponderado por tipo de via
/// (pasillos techados, caminos peatonales y calles internas con acera),
/// navegando estrictamente de puerta a puerta entre las entradas y salidas oficiales
/// de cada edificio, sin atravesar paredes ni obstaculos.
class CampusRouteService {
  final CampusDistanceService _distanceService = CampusDistanceService();

  /// Calcula la ruta peatonal optima entre una ubicacion origen y un edificio de destino.
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

    if (directDistance <= 5.0) {
      final points = <LatLng>[origin, destination.location];
      return CampusRoute(
        origin: origin,
        destination: destination,
        points: points,
        distanceInMeters: directDistance,
        estimatedDuration: Duration.zero,
        destinationEntrance: destination.primaryEntrance,
        steps: ['Te encuentras en la entrada de ${destination.name}.'],
      );
    }

    // Identificar si el origen corresponde a las puertas de algun edificio
    BuildingEntrance? originEntrance;
    for (final b in UsacCampusDataset.allBuildings) {
      if (_distanceService.calculateDistance(origin, b.location) <= 15.0) {
        originEntrance = _findBestEntrance(b.entrances, destination.location);
        break;
      }
    }

    final startNodeIndex = originEntrance != null
        ? _findClosestNodeIndex(originEntrance.location)
        : _findClosestNodeIndex(origin);

    // Seleccionar la puerta de entrada optima del edificio de destino
    final bestDestEntrance = _findBestEntrance(
      destination.entrances,
      originEntrance?.location ?? origin,
    );
    final goalNodeIndex = _findClosestNodeIndex(bestDestEntrance.location);

    final pathNodeIndices = _runWeightedAStar(startNodeIndex, goalNodeIndex);

    final points = <LatLng>[origin];

    if (pathNodeIndices != null && pathNodeIndices.isNotEmpty) {
      for (final idx in pathNodeIndices) {
        final nodePos = UsacWalkwayGraphData.nodes[idx];
        if (points.last != nodePos) {
          points.add(nodePos);
        }
      }
    } else {
      final startPos = UsacWalkwayGraphData.nodes[startNodeIndex];
      final goalPos = UsacWalkwayGraphData.nodes[goalNodeIndex];
      if (points.last != startPos) points.add(startPos);
      if (startPos != goalPos) points.add(goalPos);
    }

    // Asegurar llegada exacta a la puerta oficial del edificio destino
    if (points.last != bestDestEntrance.location) {
      points.add(bestDestEntrance.location);
    }

    final totalDistance = _distanceService.calculatePathDistance(points);
    final duration = _distanceService.estimateWalkingDuration(totalDistance);

    final segments = _buildRouteSegments(
      pathNodeIndices ?? [startNodeIndex, goalNodeIndex],
      originEntrance: originEntrance,
      destinationEntrance: bestDestEntrance,
      destinationName: destination.name,
    );

    final steps = _generateStepInstructions(
      originEntrance: originEntrance,
      destinationEntrance: bestDestEntrance,
      destinationName: destination.name,
      segments: segments,
    );

    return CampusRoute(
      origin: origin,
      destination: destination,
      points: points,
      distanceInMeters: totalDistance,
      estimatedDuration: duration,
      startEntrance: originEntrance,
      destinationEntrance: bestDestEntrance,
      segments: segments,
      steps: steps,
    );
  }

  /// Calcula la ruta peatonal puerta a puerta entre dos edificios universitarios.
  /// Evalua las salidas del edificio origen y las entradas del edificio destino,
  /// encontrando la combinacion optima a traves de pasillos, caminos y aceras.
  CampusRoute? calculateRouteBetweenBuildings({
    required CampusBuilding origin,
    required CampusBuilding destination,
  }) {
    if (!UsacCampusBoundary.isInsideCampus(origin.location) ||
        !UsacCampusBoundary.isInsideCampus(destination.location)) {
      return null;
    }

    final originEntrances =
        origin.entrances.isNotEmpty ? origin.entrances : [origin.primaryEntrance];
    final destEntrances = destination.entrances.isNotEmpty
        ? destination.entrances
        : [destination.primaryEntrance];

    // Encontrar el mejor par de puertas (salida de origen -> entrada de destino)
    BuildingEntrance bestExit = originEntrances.first;
    BuildingEntrance bestEnter = destEntrances.first;
    List<int>? bestPath;
    double minCost = double.infinity;

    for (final exitDoor in originEntrances) {
      final startIdx = _findClosestNodeIndex(exitDoor.location);
      for (final enterDoor in destEntrances) {
        final goalIdx = _findClosestNodeIndex(enterDoor.location);
        final path = _runWeightedAStar(startIdx, goalIdx);
        if (path != null) {
          final cost = _calculatePathCost(path);
          if (cost < minCost) {
            minCost = cost;
            bestExit = exitDoor;
            bestEnter = enterDoor;
            bestPath = path;
          }
        }
      }
    }

    final points = <LatLng>[];

    // Iniciar en la ubicacion del edificio origen / puerta de salida
    points.add(origin.location);
    if (points.last != bestExit.location) {
      points.add(bestExit.location);
    }

    if (bestPath != null && bestPath.isNotEmpty) {
      for (final idx in bestPath) {
        final nodePos = UsacWalkwayGraphData.nodes[idx];
        if (points.last != nodePos) {
          points.add(nodePos);
        }
      }
    }

    // Llegada a la puerta del edificio destino
    if (points.last != bestEnter.location) {
      points.add(bestEnter.location);
    }
    if (points.last != destination.location) {
      points.add(destination.location);
    }

    final totalDistance = _distanceService.calculatePathDistance(points);
    final duration = _distanceService.estimateWalkingDuration(totalDistance);

    final segments = _buildRouteSegments(
      bestPath ?? [_findClosestNodeIndex(bestExit.location)],
      originEntrance: bestExit,
      destinationEntrance: bestEnter,
      destinationName: destination.name,
    );

    final steps = _generateStepInstructions(
      originEntrance: bestExit,
      destinationEntrance: bestEnter,
      destinationName: destination.name,
      originName: origin.name,
      segments: segments,
    );

    return CampusRoute(
      origin: origin.location,
      destination: destination,
      points: points,
      distanceInMeters: totalDistance,
      estimatedDuration: duration,
      startEntrance: bestExit,
      destinationEntrance: bestEnter,
      segments: segments,
      steps: steps,
    );
  }

  /// Calcula una ruta peatonal hacia coordenadas arbitrarias en el campus.
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

    final route = calculateRoute(origin: origin, destination: targetBuilding);
    if (route == null) return null;

    final updatedPoints = List<LatLng>.from(route.points);
    if (updatedPoints.last != destinationCoords) {
      updatedPoints.add(destinationCoords);
    }

    final totalDist = _distanceService.calculatePathDistance(updatedPoints);
    return CampusRoute(
      origin: origin,
      destination: targetBuilding,
      points: updatedPoints,
      distanceInMeters: totalDist,
      estimatedDuration: _distanceService.estimateWalkingDuration(totalDist),
      startEntrance: route.startEntrance,
      destinationEntrance: route.destinationEntrance,
      segments: route.segments,
      steps: route.steps,
    );
  }

  BuildingEntrance _findBestEntrance(List<BuildingEntrance> entrances, LatLng reference) {
    if (entrances.isEmpty) {
      return BuildingEntrance(
        id: 'default',
        name: 'Entrada Principal',
        location: reference,
      );
    }
    BuildingEntrance best = entrances.first;
    double minD = _distanceService.calculateDistance(reference, best.location);

    for (int i = 1; i < entrances.length; i++) {
      final d = _distanceService.calculateDistance(reference, entrances[i].location);
      if (d < minD) {
        minD = d;
        best = entrances[i];
      }
    }
    return best;
  }

  int _findClosestNodeIndex(LatLng point) {
    int closestIdx = 0;
    double minDistance = double.infinity;
    const nodes = UsacWalkwayGraphData.nodes;

    for (int i = 0; i < nodes.length; i++) {
      final d = _distanceService.calculateDistance(point, nodes[i]);
      if (d < minDistance) {
        minDistance = d;
        closestIdx = i;
      }
    }

    return closestIdx;
  }

  /// Algoritmo A* con ponderacion de preferencias viales (prioriza pasillos techados y caminos peatonales sobre calles vehiculares).
  List<int>? _runWeightedAStar(int startIndex, int goalIndex) {
    if (startIndex == goalIndex) {
      return [startIndex];
    }

    const nodes = UsacWalkwayGraphData.nodes;
    const adjacency = UsacWalkwayGraphData.adjacency;
    const edgeTypes = UsacWalkwayGraphData.edgeTypes;
    final goalPoint = nodes[goalIndex];

    final openSet = _PriorityQueue();
    final gScore = <int, double>{startIndex: 0.0};
    final cameFrom = <int, int>{};

    final initialH = _distanceService.calculateDistance(nodes[startIndex], goalPoint);
    openSet.insert(startIndex, initialH);

    while (openSet.isNotEmpty) {
      final current = openSet.pop();

      if (current == goalIndex) {
        final path = <int>[current];
        int? curr = current;
        while (cameFrom.containsKey(curr)) {
          curr = cameFrom[curr]!;
          path.add(curr);
        }
        return path.reversed.toList(growable: false);
      }

      final currentG = gScore[current] ?? double.infinity;
      final neighbors = adjacency[current];
      final types = edgeTypes[current];

      for (int i = 0; i < neighbors.length; i++) {
        final neighbor = neighbors[i];
        final edgeDist = _distanceService.calculateDistance(nodes[current], nodes[neighbor]);

        // Ponderar por tipo de via (pasillo: 1.0, camino: 1.0, calle: 1.25)
        final edgeTypeInt = i < types.length ? types[i] : 1;
        final walkwayType = edgeTypeInt >= 0 && edgeTypeInt < WalkwayType.values.length
            ? WalkwayType.values[edgeTypeInt]
            : WalkwayType.pathway;

        final weightedDistance = edgeDist * walkwayType.preferenceCostFactor;
        final tentativeG = currentG + weightedDistance;

        if (tentativeG < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeG;
          final h = _distanceService.calculateDistance(nodes[neighbor], goalPoint);
          openSet.insert(neighbor, tentativeG + h);
        }
      }
    }

    return null;
  }

  double _calculatePathCost(List<int> path) {
    if (path.length < 2) return 0.0;
    double cost = 0.0;
    const nodes = UsacWalkwayGraphData.nodes;
    const adjacency = UsacWalkwayGraphData.adjacency;
    const edgeTypes = UsacWalkwayGraphData.edgeTypes;

    for (int i = 0; i < path.length - 1; i++) {
      final u = path[i];
      final v = path[i + 1];
      final dist = _distanceService.calculateDistance(nodes[u], nodes[v]);
      final nbrIdx = adjacency[u].indexOf(v);
      final edgeTypeInt = nbrIdx != -1 && nbrIdx < edgeTypes[u].length
          ? edgeTypes[u][nbrIdx]
          : 1;
      final wType = WalkwayType.values[edgeTypeInt.clamp(0, 2)];
      cost += dist * wType.preferenceCostFactor;
    }
    return cost;
  }

  List<CampusRouteSegment> _buildRouteSegments(
    List<int> pathIndices, {
    BuildingEntrance? originEntrance,
    required BuildingEntrance destinationEntrance,
    required String destinationName,
  }) {
    if (pathIndices.length < 2) return const [];

    const nodes = UsacWalkwayGraphData.nodes;
    const adjacency = UsacWalkwayGraphData.adjacency;
    const edgeTypes = UsacWalkwayGraphData.edgeTypes;

    final segments = <CampusRouteSegment>[];
    var currentSegmentPoints = <LatLng>[nodes[pathIndices.first]];
    WalkwayType? currentType;

    for (int i = 0; i < pathIndices.length - 1; i++) {
      final u = pathIndices[i];
      final v = pathIndices[i + 1];
      final nbrIdx = adjacency[u].indexOf(v);
      final edgeTypeInt = nbrIdx != -1 && nbrIdx < edgeTypes[u].length
          ? edgeTypes[u][nbrIdx]
          : 1;
      final type = WalkwayType.values[edgeTypeInt.clamp(0, 2)];

      if (currentType == null) {
        currentType = type;
      } else if (currentType != type) {
        final dist = _distanceService.calculatePathDistance(currentSegmentPoints);
        segments.add(
          CampusRouteSegment(
            points: List.from(currentSegmentPoints),
            type: currentType,
            distanceInMeters: dist,
            instruction: _segmentInstruction(currentType, dist),
          ),
        );
        currentSegmentPoints = <LatLng>[nodes[u]];
        currentType = type;
      }
      currentSegmentPoints.add(nodes[v]);
    }

    if (currentSegmentPoints.length >= 2 && currentType != null) {
      final dist = _distanceService.calculatePathDistance(currentSegmentPoints);
      segments.add(
        CampusRouteSegment(
          points: List.from(currentSegmentPoints),
          type: currentType,
          distanceInMeters: dist,
          instruction: _segmentInstruction(currentType, dist),
        ),
      );
    }

    return segments;
  }

  String _segmentInstruction(WalkwayType type, double dist) {
    final m = dist.round();
    switch (type) {
      case WalkwayType.corridor:
        return 'Avanza $m m por el pasillo techado.';
      case WalkwayType.pathway:
        return 'Camina $m m por el andador / camino peatonal.';
      case WalkwayType.street:
        return 'Continua $m m por la acera de la calle interna.';
    }
  }

  List<String> _generateStepInstructions({
    BuildingEntrance? originEntrance,
    required BuildingEntrance destinationEntrance,
    required String destinationName,
    String? originName,
    required List<CampusRouteSegment> segments,
  }) {
    final steps = <String>[];
    if (originEntrance != null) {
      steps.add(
        originName != null
            ? 'Sal por ${originEntrance.name} de $originName.'
            : 'Inicia en ${originEntrance.name}.',
      );
    } else {
      steps.add('Inicia tu recorrido hacia el camino peatonal.');
    }

    for (final seg in segments) {
      steps.add(seg.instruction);
    }

    steps.add(
      'Llega a ${destinationEntrance.name} de $destinationName.',
    );
    return steps;
  }
}

class _QueueEntry {
  final int index;
  final double priority;

  const _QueueEntry(this.index, this.priority);
}

class _PriorityQueue {
  final List<_QueueEntry> _heap = [];

  bool get isNotEmpty => _heap.isNotEmpty;

  void insert(int index, double priority) {
    _heap.add(_QueueEntry(index, priority));
    _siftUp(_heap.length - 1);
  }

  int pop() {
    final root = _heap[0].index;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _siftDown(0);
    }
    return root;
  }

  void _siftUp(int index) {
    int current = index;
    while (current > 0) {
      final parent = (current - 1) >> 1;
      if (_heap[current].priority < _heap[parent].priority) {
        final temp = _heap[current];
        _heap[current] = _heap[parent];
        _heap[parent] = temp;
        current = parent;
      } else {
        break;
      }
    }
  }

  void _siftDown(int index) {
    int current = index;
    final length = _heap.length;
    while (true) {
      final left = (current << 1) + 1;
      final right = left + 1;
      int smallest = current;

      if (left < length && _heap[left].priority < _heap[smallest].priority) {
        smallest = left;
      }
      if (right < length && _heap[right].priority < _heap[smallest].priority) {
        smallest = right;
      }

      if (smallest != current) {
        final temp = _heap[current];
        _heap[current] = _heap[smallest];
        _heap[smallest] = temp;
        current = smallest;
      } else {
        break;
      }
    }
  }
}
