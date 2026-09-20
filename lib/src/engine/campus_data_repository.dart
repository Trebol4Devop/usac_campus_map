import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/campus_building.dart';
import '../models/campus_edge.dart';
import '../models/campus_node.dart';
import '../models/campus_poi.dart';
import '../models/indoor_floor.dart';

class CampusDataRepository {
  final List<LatLng> boundary = [];
  final List<CampusBuilding> buildings = [];
  final Map<String, CampusBuilding> buildingsById = {};
  final List<CampusNode> nodes = [];
  final Map<String, CampusNode> nodesById = {};
  final List<CampusEdge> edges = [];
  final Map<String, List<CampusEdge>> adjacencyList = {};
  final List<CampusPoi> allPois = [];
  final Map<String, CampusPoi> poisById = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> loadFromAssets({
    AssetBundle? bundle,
    String boundaryAsset = 'assets/geojson/usac_boundary.geojson',
    String buildingsAsset = 'assets/geojson/usac_buildings.geojson',
    String graphAsset = 'assets/graph/campus_graph.json',
    String poisAsset = 'assets/pois/usac_pois_and_indoors.json',
    String packagePrefix = 'packages/usac_campus_map/',
  }) async {
    final effectiveBundle = bundle ?? rootBundle;

    final boundaryStr = await _loadAssetString(
      effectiveBundle,
      boundaryAsset,
      packagePrefix,
    );
    final buildingsStr = await _loadAssetString(
      effectiveBundle,
      buildingsAsset,
      packagePrefix,
    );
    final graphStr = await _loadAssetString(
      effectiveBundle,
      graphAsset,
      packagePrefix,
    );
    final poisStr = await _loadAssetString(
      effectiveBundle,
      poisAsset,
      packagePrefix,
    );

    loadFromJson(
      boundaryJson: jsonDecode(boundaryStr) as Map<String, dynamic>,
      buildingsJson: jsonDecode(buildingsStr) as Map<String, dynamic>,
      graphJson: jsonDecode(graphStr) as Map<String, dynamic>,
      poisJson: jsonDecode(poisStr) as Map<String, dynamic>,
    );
  }

  Future<String> _loadAssetString(
    AssetBundle bundle,
    String assetPath,
    String packagePrefix,
  ) async {
    try {
      return await bundle.loadString('$packagePrefix$assetPath');
    } catch (_) {
      return await bundle.loadString(assetPath);
    }
  }

  void loadFromJson({
    required Map<String, dynamic> boundaryJson,
    required Map<String, dynamic> buildingsJson,
    required Map<String, dynamic> graphJson,
    required Map<String, dynamic> poisJson,
  }) {
    _clear();

    _parseBoundary(boundaryJson);
    final indoorsMap = _parseIndoors(poisJson);
    _parseBuildings(buildingsJson, indoorsMap);
    _parseGraph(graphJson);

    _isLoaded = true;
  }

  void _clear() {
    boundary.clear();
    buildings.clear();
    buildingsById.clear();
    nodes.clear();
    nodesById.clear();
    edges.clear();
    adjacencyList.clear();
    allPois.clear();
    poisById.clear();
  }

  void _parseBoundary(Map<String, dynamic> json) {
    final features = json['features'] as List<dynamic>? ?? [];
    if (features.isNotEmpty) {
      final feat = features.first as Map<String, dynamic>;
      final geom = feat['geometry'] as Map<String, dynamic>? ?? {};
      if (geom['type'] == 'Polygon' && geom['coordinates'] is List) {
        final coords = (geom['coordinates'] as List).first as List;
        for (final pt in coords) {
          if (pt is List && pt.length >= 2) {
            final lng = (pt[0] as num).toDouble();
            final lat = (pt[1] as num).toDouble();
            boundary.add(LatLng(lat, lng));
          }
        }
      }
    }
  }

  Map<String, List<IndoorFloor>> _parseIndoors(Map<String, dynamic> json) {
    final result = <String, List<IndoorFloor>>{};
    final buildingsList = json['buildings'] as List<dynamic>? ?? [];

    for (final b in buildingsList) {
      final bMap = b as Map<String, dynamic>;
      final bId = bMap['building_id'] as String;
      final floorsList = bMap['floors'] as List<dynamic>? ?? [];

      final floors = <IndoorFloor>[];
      for (final f in floorsList) {
        final fMap = f as Map<String, dynamic>;
        final floor = IndoorFloor.fromJson(fMap, buildingId: bId);
        floors.add(floor);
        for (final poi in floor.pois) {
          allPois.add(poi);
          poisById[poi.id] = poi;
        }
      }
      result[bId] = floors;
    }
    return result;
  }

  void _parseBuildings(
    Map<String, dynamic> json,
    Map<String, List<IndoorFloor>> indoorsMap,
  ) {
    final features = json['features'] as List<dynamic>? ?? [];
    for (final f in features) {
      final feat = f as Map<String, dynamic>;
      final props = feat['properties'] as Map<String, dynamic>? ?? {};
      final id = props['id'] as String? ?? '';
      final floors = indoorsMap[id] ?? const [];
      final building = CampusBuilding.fromGeoJsonFeature(feat, floors: floors);
      buildings.add(building);
      buildingsById[building.id] = building;
    }
  }

  void _parseGraph(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? [];
    for (final n in rawNodes) {
      final node = CampusNode.fromJson(n as Map<String, dynamic>);
      nodes.add(node);
      nodesById[node.id] = node;
      adjacencyList[node.id] = [];
    }

    final rawEdges = json['edges'] as List<dynamic>? ?? [];
    for (final e in rawEdges) {
      final edge = CampusEdge.fromJson(e as Map<String, dynamic>);
      edges.add(edge);
      adjacencyList.putIfAbsent(edge.source, () => []).add(edge);
    }
  }
}
