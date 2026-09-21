import 'dart:math';
import 'dart:ui';
import 'package:latlong2/latlong.dart';
import 'campus_building.dart';

class Vector3D {
  final double x;
  final double y;
  final double z;

  const Vector3D(this.x, this.y, this.z);

  Vector3D rotateZ(double angleRadians) {
    final cosA = cos(angleRadians);
    final sinA = sin(angleRadians);
    return Vector3D(
      x * cosA - y * sinA,
      x * sinA + y * cosA,
      z,
    );
  }

  Vector3D rotateX(double angleRadians) {
    final cosA = cos(angleRadians);
    final sinA = sin(angleRadians);
    return Vector3D(
      x,
      y * cosA - z * sinA,
      y * sinA + z * cosA,
    );
  }

  Offset toIsometric({
    double rotationAngle = 45.0,
    double tiltAngle = 30.0,
    double scale = 1.0,
    Offset origin = Offset.zero,
  }) {
    final rotRad = rotationAngle * pi / 180.0;
    final tiltRad = tiltAngle * pi / 180.0;

    final rotated = rotateZ(rotRad).rotateX(tiltRad);

    final screenX = origin.dx + (rotated.x * scale);
    final screenY = origin.dy - (rotated.z * scale) + (rotated.y * scale * 0.5);

    return Offset(screenX, screenY);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector3D &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}

class Polygon3D {
  final List<Vector3D> vertices;

  const Polygon3D({required this.vertices});

  List<Offset> toScreenOffsets({
    double rotationAngle = 45.0,
    double tiltAngle = 30.0,
    double scale = 1.0,
    Offset origin = Offset.zero,
  }) {
    return vertices.map((v) {
      return v.toIsometric(
        rotationAngle: rotationAngle,
        tiltAngle: tiltAngle,
        scale: scale,
        origin: origin,
      );
    }).toList();
  }
}

class Building3DModel {
  final String buildingId;
  final String buildingName;
  final double heightMeters;
  final int floors;
  final List<Polygon3D> wallFaces;
  final Polygon3D roofFace;
  final Polygon3D baseFace;

  const Building3DModel({
    required this.buildingId,
    required this.buildingName,
    required this.heightMeters,
    required this.floors,
    required this.wallFaces,
    required this.roofFace,
    required this.baseFace,
  });

  factory Building3DModel.fromBuilding(
    CampusBuilding building, {
    double floorHeightMeters = 3.5,
  }) {
    final floors = max(1, building.floorsCount);
    final height = floors * floorHeightMeters;

    final basePoints = building.polygon.isNotEmpty
        ? building.polygon
        : _generateSquare(building.center, 20.0);

    final center = building.center;
    final latRad = center.latitude * pi / 180.0;
    final metersPerLng = 111320.0 * cos(latRad);
    const metersPerLat = 110574.0;

    final baseVertices = <Vector3D>[];
    final topVertices = <Vector3D>[];

    for (final pt in basePoints) {
      final dx = (pt.longitude - center.longitude) * metersPerLng;
      final dy = (pt.latitude - center.latitude) * metersPerLat;
      baseVertices.add(Vector3D(dx, dy, 0.0));
      topVertices.add(Vector3D(dx, dy, height));
    }

    final wallFaces = <Polygon3D>[];
    for (var i = 0; i < baseVertices.length; i++) {
      final next = (i + 1) % baseVertices.length;
      wallFaces.add(
        Polygon3D(
          vertices: [
            baseVertices[i],
            baseVertices[next],
            topVertices[next],
            topVertices[i],
          ],
        ),
      );
    }

    return Building3DModel(
      buildingId: building.id,
      buildingName: building.name,
      heightMeters: height,
      floors: floors,
      wallFaces: wallFaces,
      roofFace: Polygon3D(vertices: topVertices),
      baseFace: Polygon3D(vertices: baseVertices),
    );
  }

  static List<LatLng> _generateSquare(LatLng center, double halfSideMeters) {
    final dLat = halfSideMeters / 110574.0;
    final dLng =
        halfSideMeters / (111320.0 * cos(center.latitude * pi / 180.0));

    return [
      LatLng(center.latitude - dLat, center.longitude - dLng),
      LatLng(center.latitude - dLat, center.longitude + dLng),
      LatLng(center.latitude + dLat, center.longitude + dLng),
      LatLng(center.latitude + dLat, center.longitude - dLng),
    ];
  }
}
