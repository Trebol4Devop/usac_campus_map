import 'dart:math';
import 'package:latlong2/latlong.dart';

class TileIndex {
  final int z;
  final int x;
  final int y;

  const TileIndex({
    required this.z,
    required this.x,
    required this.y,
  });

  static TileIndex fromLatLng({
    required double latitude,
    required double longitude,
    required int zoom,
  }) {
    final clampedZoom = zoom.clamp(0, 22);
    final n = 1 << clampedZoom;
    final clampedLon = longitude.clamp(-180.0, 180.0);
    final clampedLat = latitude.clamp(-85.05112878, 85.05112878);

    final x = ((clampedLon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
    final latRad = clampedLat * pi / 180.0;
    final y = ((1.0 - log(tan(latRad) + (1.0 / cos(latRad))) / pi) / 2.0 * n)
        .floor()
        .clamp(0, n - 1);

    return TileIndex(z: clampedZoom, x: x, y: y);
  }

  static LatLng toLatLng(TileIndex tile) {
    final n = 1 << tile.z;
    final lon = tile.x / n * 360.0 - 180.0;
    final latRad = atan(_sinh(pi * (1.0 - 2.0 * tile.y / n)));
    final lat = latRad * 180.0 / pi;
    return LatLng(lat, lon);
  }

  static List<TileIndex> getTilesInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    required int zoom,
  }) {
    final nw = fromLatLng(latitude: maxLat, longitude: minLng, zoom: zoom);
    final se = fromLatLng(latitude: minLat, longitude: maxLng, zoom: zoom);

    final minX = min(nw.x, se.x);
    final maxX = max(nw.x, se.x);
    final minY = min(nw.y, se.y);
    final maxY = max(nw.y, se.y);

    final tiles = <TileIndex>[];
    for (var x = minX; x <= maxX; x++) {
      for (var y = minY; y <= maxY; y++) {
        tiles.add(TileIndex(z: zoom, x: x, y: y));
      }
    }
    return tiles;
  }

  static double _sinh(double x) {
    return (exp(x) - exp(-x)) / 2.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileIndex &&
          runtimeType == other.runtimeType &&
          z == other.z &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => z.hashCode ^ x.hashCode ^ y.hashCode;

  @override
  String toString() => 'TileIndex(z: $z, x: $x, y: $y)';
}
