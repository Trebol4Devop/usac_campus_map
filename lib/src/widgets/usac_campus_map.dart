import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/usac_campus_boundary.dart';
import '../data/usac_campus_dataset.dart';
import '../models/building_category.dart';
import '../models/campus_building.dart';
import '../services/location_service.dart';

class UsacCampusMap extends StatefulWidget {
  final List<CampusBuilding>? buildings;
  final Function(CampusBuilding)? onBuildingTap;
  final Widget Function(BuildContext, CampusBuilding)? markerBuilder;
  final LatLng? initialCenter;
  final double initialZoom;
  final bool showCampusBoundary;
  final List<Polygon>? customPolygons;

  const UsacCampusMap({
    super.key,
    this.buildings,
    this.onBuildingTap,
    this.markerBuilder,
    this.initialCenter,
    this.initialZoom = 16.5,
    this.showCampusBoundary = true,
    this.customPolygons,
  });

  @override
  State<UsacCampusMap> createState() => _UsacCampusMapState();
}

class _UsacCampusMapState extends State<UsacCampusMap> {
  final MapController _mapController = MapController();
  final CampusLocationService _locationService = CampusLocationService();
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  void _initTracking() {
    _locationSubscription = _locationService.studentPositionStream.listen(
      (LatLng pos) {
        if (mounted) {
          setState(() {
            _currentPosition = pos;
          });
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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter ?? UsacCampusDataset.campusCenter,
        initialZoom: widget.initialZoom,
        maxZoom: 19.0,
        minZoom: 14.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'gt.edu.usac.map',
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
                child: widget.markerBuilder?.call(context, building) ??
                    _buildDefaultMarker(building),
              ),
            ),
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 36,
                height: 36,
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
          ],
        ),
      ],
    );
  }
}
