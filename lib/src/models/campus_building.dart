import 'package:latlong2/latlong.dart';
import 'indoor_floor.dart';

class BuildingEntrance {
  final String id;
  final String name;
  final LatLng location;
  final String? nearestNodeId;

  const BuildingEntrance({
    required this.id,
    required this.name,
    required this.location,
    this.nearestNodeId,
  });

  factory BuildingEntrance.fromJson(Map<String, dynamic> json) {
    return BuildingEntrance(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      nearestNodeId: json['nearest_node_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': location.latitude,
    'lng': location.longitude,
    if (nearestNodeId != null) 'nearest_node_id': nearestNodeId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildingEntrance &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CampusBuilding {
  final String id;
  final String name;
  final String code;
  final String category;
  final int floorsCount;
  final LatLng center;
  final List<LatLng> polygon;
  final List<BuildingEntrance> entrances;
  final List<IndoorFloor> floors;

  const CampusBuilding({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.floorsCount,
    required this.center,
    this.polygon = const [],
    this.entrances = const [],
    this.floors = const [],
  });

  factory CampusBuilding.fromGeoJsonFeature(
    Map<String, dynamic> feature, {
    List<IndoorFloor> floors = const [],
  }) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final geom = feature['geometry'] as Map<String, dynamic>? ?? {};
    final id = props['id'] as String? ?? '';
    final name = props['name'] as String? ?? '';
    final code = props['code'] as String? ?? '';
    final category = props['category'] as String? ?? 'general';
    final floorsCount = (props['floors_count'] as num?)?.toInt() ?? 1;

    final List<LatLng> polygonPoints = [];
    if (geom['type'] == 'Polygon' && geom['coordinates'] is List) {
      final rawCoords = (geom['coordinates'] as List).first as List;
      for (final pt in rawCoords) {
        if (pt is List && pt.length >= 2) {
          final lng = (pt[0] as num).toDouble();
          final lat = (pt[1] as num).toDouble();
          polygonPoints.add(LatLng(lat, lng));
        }
      }
    }

    LatLng calculatedCenter;
    if (polygonPoints.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      final count = polygonPoints.length > 1 &&
              polygonPoints.first == polygonPoints.last
          ? polygonPoints.length - 1
          : polygonPoints.length;
      for (int i = 0; i < count; i++) {
        sumLat += polygonPoints[i].latitude;
        sumLng += polygonPoints[i].longitude;
      }
      calculatedCenter = LatLng(sumLat / count, sumLng / count);
    } else {
      calculatedCenter = const LatLng(14.5868, -90.5518);
    }

    final rawEntrances = props['entrances'] as List<dynamic>? ?? [];
    final entrances = rawEntrances
        .map((e) => BuildingEntrance.fromJson(e as Map<String, dynamic>))
        .toList();

    return CampusBuilding(
      id: id,
      name: name,
      code: code,
      category: category,
      floorsCount: floorsCount,
      center: calculatedCenter,
      polygon: polygonPoints,
      entrances: entrances,
      floors: floors,
    );
  }

  CampusBuilding copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    int? floorsCount,
    LatLng? center,
    List<LatLng>? polygon,
    List<BuildingEntrance>? entrances,
    List<IndoorFloor>? floors,
  }) {
    return CampusBuilding(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      floorsCount: floorsCount ?? this.floorsCount,
      center: center ?? this.center,
      polygon: polygon ?? this.polygon,
      entrances: entrances ?? this.entrances,
      floors: floors ?? this.floors,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusBuilding &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
