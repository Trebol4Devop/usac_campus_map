import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/usac_campus_boundary.dart';
import '../data/usac_campus_dataset.dart';
import '../models/building_category.dart';
import '../models/campus_building.dart';
import '../services/location_service.dart';

abstract final class UsacMapTileServers {
  static const String openStreetMap =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> defaultSubdomains = ['a', 'b', 'c'];
}

class UsacCampusMap extends StatefulWidget {
  final List<CampusBuilding>? buildings;
  final Function(CampusBuilding)? onBuildingTap;
  final Widget Function(BuildContext, CampusBuilding)? markerBuilder;
  final LatLng? initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final bool showCampusBoundary;
  final List<Polygon>? customPolygons;
  final CameraConstraint? cameraConstraint;
  final InteractionOptions? interactionOptions;
  final ValueChanged<bool>? onCampusStatusChanged;
  final bool showOutOfCampusBanner;
  final String? outOfCampusMessage;
  final String urlTemplate;
  final List<String> subdomains;
  final TileProvider? tileProvider;
  final TileDisplay tileDisplay;
  final TileUpdateTransformer? tileUpdateTransformer;
  final int keepBuffer;
  final int panBuffer;
  final LatLngBounds? tileBounds;
  final String userAgentPackageName;

  const UsacCampusMap({
    super.key,
    this.buildings,
    this.onBuildingTap,
    this.markerBuilder,
    this.initialCenter,
    this.initialZoom = 16.5,
    this.minZoom = 3.0,
    this.maxZoom = 19.0,
    this.showCampusBoundary = true,
    this.customPolygons,
    this.cameraConstraint,
    this.interactionOptions,
    this.onCampusStatusChanged,
    this.showOutOfCampusBanner = true,
    this.outOfCampusMessage,
    this.urlTemplate = UsacMapTileServers.openStreetMap,
    this.subdomains = UsacMapTileServers.defaultSubdomains,
    this.tileProvider,
    this.tileDisplay = const TileDisplay.instantaneous(),
    this.tileUpdateTransformer,
    this.keepBuffer = 2,
    this.panBuffer = 0,
    this.tileBounds,
    this.userAgentPackageName = 'gt.edu.usac.map',
  });

  @override
  State<UsacCampusMap> createState() => _UsacCampusMapState();
}

class _UsacCampusMapState extends State<UsacCampusMap> {
  final MapController _mapController = MapController();
  final CampusLocationService _locationService = CampusLocationService();
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _currentPosition;
  bool _isInsideCampus = true;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  void _initTracking() {
    _locationSubscription = _locationService.studentPositionStream.listen(
      (LatLng pos) {
        if (mounted) {
          final isInside = UsacCampusBoundary.isInsideCampus(pos);
          final statusChanged = isInside != _isInsideCampus;
          setState(() {
            _currentPosition = pos;
            _isInsideCampus = isInside;
            if (statusChanged && isInside) {
              _bannerDismissed = false;
            }
          });
          if (statusChanged) {
            widget.onCampusStatusChanged?.call(isInside);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  List<CampusBuilding> get _activeBuildings {
    if (widget.buildings != null && widget.buildings!.isNotEmpty) {
      return widget.buildings!;
    }
    return UsacCampusDataset.allBuildings;
  }

  List<Polygon> get _polygons {
    final list = <Polygon>[];
    if (widget.showCampusBoundary) {
      list.add(UsacCampusBoundary.defaultPerimeterPolygon);
    }
    if (widget.customPolygons != null) {
      list.addAll(widget.customPolygons!);
    }
    return list;
  }

  Color _getCategoryColor(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.faculty:
        return const Color(0xFF1E3A8A);
      case BuildingCategory.administrative:
        return const Color(0xFF0F766E);
      case BuildingCategory.library:
        return const Color(0xFFB45309);
      case BuildingCategory.sports:
        return const Color(0xFF15803D);
      case BuildingCategory.food:
        return const Color(0xFFC2410C);
      case BuildingCategory.parking:
        return const Color(0xFF475569);
      case BuildingCategory.access:
        return const Color(0xFF78350F);
      case BuildingCategory.health:
        return const Color(0xFFDC2626);
      case BuildingCategory.generalAcademic:
        return const Color(0xFF6D28D9);
    }
  }

  IconData _getCategoryIcon(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.faculty:
        return Icons.school;
      case BuildingCategory.administrative:
        return Icons.account_balance;
      case BuildingCategory.library:
        return Icons.menu_book;
      case BuildingCategory.sports:
        return Icons.sports_soccer;
      case BuildingCategory.food:
        return Icons.restaurant;
      case BuildingCategory.parking:
        return Icons.local_parking;
      case BuildingCategory.access:
        return Icons.sensor_door;
      case BuildingCategory.health:
        return Icons.local_hospital;
      case BuildingCategory.generalAcademic:
        return Icons.auto_stories;
    }
  }

  Widget _buildDefaultMarker(CampusBuilding building) {
    final color = _getCategoryColor(building.category);
    final icon = _getCategoryIcon(building.category);

    return GestureDetector(
      onTap: () => widget.onBuildingTap?.call(building),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polygons = _polygons;

    final mapWidget = RepaintBoundary(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: widget.initialCenter ?? UsacCampusDataset.campusCenter,
          initialZoom: widget.initialZoom,
          maxZoom: widget.maxZoom,
          minZoom: widget.minZoom,
          cameraConstraint:
              widget.cameraConstraint ?? const CameraConstraint.unconstrained(),
          interactionOptions: widget.interactionOptions ??
              const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: widget.urlTemplate,
            subdomains: widget.subdomains,
            tileProvider: widget.tileProvider,
            userAgentPackageName: widget.userAgentPackageName,
            tileDisplay: widget.tileDisplay,
            tileUpdateTransformer: widget.tileUpdateTransformer ??
                TileUpdateTransformers.throttle(
                  const Duration(milliseconds: 100),
                ),
            keepBuffer: widget.keepBuffer,
            panBuffer: widget.panBuffer,
            tileBounds: widget.tileBounds,
            evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
          ),
          if (polygons.isNotEmpty)
            PolygonLayer(
              polygons: polygons,
            ),
          MarkerLayer(
            markers: [
              ..._activeBuildings.map(
                (building) => Marker(
                  point: building.location,
                  width: 36,
                  height: 36,
                  child: RepaintBoundary(
                    child: widget.markerBuilder?.call(context, building) ??
                        _buildDefaultMarker(building),
                  ),
                ),
              ),
              if (_currentPosition != null)
                Marker(
                  point: _currentPosition!,
                  width: 36,
                  height: 36,
                  child: RepaintBoundary(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!widget.showOutOfCampusBanner) {
      return mapWidget;
    }

    return Stack(
      children: [
        Positioned.fill(child: mapWidget),
        if (_currentPosition != null && !_isInsideCampus && !_bannerDismissed)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFFBEB),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFB45309),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.outOfCampusMessage ??
                            'No estás en la universidad, pero puedes navegar el mapa con normalidad.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _bannerDismissed = true;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
