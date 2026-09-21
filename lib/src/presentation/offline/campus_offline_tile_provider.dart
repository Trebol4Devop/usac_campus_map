import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/offline/offline_tile_package.dart';
import '../../core/offline/tile_coordinates.dart';

class CampusOfflineTileProvider extends TileProvider {
  final OfflineTilePackage? package;
  final String assetPathPrefix;
  final bool fallbackToTransparent;
  final ImageProvider Function(TileCoordinates coordinates, TileLayer options)?
      customLoader;

  CampusOfflineTileProvider({
    this.package,
    this.assetPathPrefix = 'assets/tiles',
    this.fallbackToTransparent = true,
    this.customLoader,
    super.headers,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (customLoader != null) {
      return customLoader!(coordinates, options);
    }

    final tile = TileIndex(
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
    );

    if (package != null && !package!.containsTile(tile)) {
      return MemoryImage(TileProvider.transparentImage);
    }

    try {
      final path =
          '$assetPathPrefix/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
      return AssetImage(path);
    } catch (_) {
      if (fallbackToTransparent) {
        return MemoryImage(TileProvider.transparentImage);
      }
      rethrow;
    }
  }
}
