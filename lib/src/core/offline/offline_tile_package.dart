import 'tile_coordinates.dart';

class OfflineTilePackage {
  final String id;
  final String name;
  final String version;
  final int minZoom;
  final int maxZoom;
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;
  final String format;
  final int totalTiles;
  final int sizeBytes;

  const OfflineTilePackage({
    required this.id,
    required this.name,
    required this.version,
    required this.minZoom,
    required this.maxZoom,
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
    this.format = 'png',
    this.totalTiles = 0,
    this.sizeBytes = 0,
  });

  factory OfflineTilePackage.usacCampusDefault() {
    const minLat = 14.5780;
    const maxLat = 14.5940;
    const minLng = -90.5590;
    const maxLng = -90.5420;
    const minZoom = 14;
    const maxZoom = 18;

    var count = 0;
    for (var z = minZoom; z <= maxZoom; z++) {
      count += TileIndex.getTilesInBounds(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
        zoom: z,
      ).length;
    }

    return OfflineTilePackage(
      id: 'usac-campus-central-offline',
      name: 'USAC Campus Central Offline Tile Package',
      version: '1.0.0',
      minZoom: minZoom,
      maxZoom: maxZoom,
      minLat: minLat,
      minLng: minLng,
      maxLat: maxLat,
      maxLng: maxLng,
      format: 'png',
      totalTiles: count,
      sizeBytes: count * 18500,
    );
  }

  bool containsTile(TileIndex tile) {
    if (tile.z < minZoom || tile.z > maxZoom) return false;
    final nw = TileIndex.fromLatLng(latitude: maxLat, longitude: minLng, zoom: tile.z);
    final se = TileIndex.fromLatLng(latitude: minLat, longitude: maxLng, zoom: tile.z);
    return tile.x >= nw.x && tile.x <= se.x && tile.y >= nw.y && tile.y <= se.y;
  }

  bool containsCoordinate(double latitude, double longitude) {
    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }

  List<TileIndex> listExpectedTiles() {
    final list = <TileIndex>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      list.addAll(
        TileIndex.getTilesInBounds(
          minLat: minLat,
          minLng: minLng,
          maxLat: maxLat,
          maxLng: maxLng,
          zoom: z,
        ),
      );
    }
    return list;
  }

  factory OfflineTilePackage.fromJson(Map<String, dynamic> json) {
    return OfflineTilePackage(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String? ?? '1.0.0',
      minZoom: (json['minZoom'] as num).toInt(),
      maxZoom: (json['maxZoom'] as num).toInt(),
      minLat: (json['minLat'] as num).toDouble(),
      minLng: (json['minLng'] as num).toDouble(),
      maxLat: (json['maxLat'] as num).toDouble(),
      maxLng: (json['maxLng'] as num).toDouble(),
      format: json['format'] as String? ?? 'png',
      totalTiles: (json['totalTiles'] as num?)?.toInt() ?? 0,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'minLat': minLat,
      'minLng': minLng,
      'maxLat': maxLat,
      'maxLng': maxLng,
      'format': format,
      'totalTiles': totalTiles,
      'sizeBytes': sizeBytes,
    };
  }
}
