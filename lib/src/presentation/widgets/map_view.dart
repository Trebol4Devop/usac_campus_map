import 'dart:async';

import 'package:flutter/material.dart' hide NavigationMode;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import '../../controllers/usac_campus_map_controller.dart';
import '../../core/utils/distance_calculator.dart';
import '../../models/campus_building.dart';
import '../../models/campus_poi.dart';
import '../../models/campus_route.dart';
import '../../core/offline/offline_tile_package.dart';
import '../offline/campus_offline_tile_provider.dart';
import '../themes/usac_map_theme.dart';
import 'floor_selector.dart';
import 'poi_detail_sheet.dart';
import 'turn_by_turn_banner.dart';

typedef MapView = UsacCampusMap;

class UsacCampusMap extends StatefulWidget {
  final UsacCampusMapController? controller;
  final UsacMapTheme theme;
  final ValueChanged<CampusBuilding?>? onBuildingSelected;
  final ValueChanged<CampusRoute>? onRouteCalculated;
  final ValueChanged<CampusPoi>? onPoiTapped;
  final LatLng initialCenter;
  final double initialZoom;
  final List<CampusBuilding>? buildings;
  final CampusBuilding? routeDestination;
  final VoidCallback? onClearRoute;
  final ValueChanged<LatLng>? onUserLocationTap;
  final ValueChanged<LatLng>? onUserLocationChanged;
  final bool showControls;

  const UsacCampusMap({
    super.key,
    this.controller,
    this.theme = const UsacMapTheme(),
    this.onBuildingSelected,
    this.onRouteCalculated,
    this.onPoiTapped,
    this.initialCenter = const LatLng(14.5868, -90.5518),
    this.initialZoom = 16.5,
    this.buildings,
    this.routeDestination,
    this.onClearRoute,
    this.onUserLocationTap,
    this.onUserLocationChanged,
    this.showControls = true,
  });

  @override
  State<UsacCampusMap> createState() => _UsacCampusMapState();
}

class _UsacCampusMapState extends State<UsacCampusMap> {
  late UsacCampusMapController _controller;
  bool _internalController = false;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = UsacCampusMapController();
      _internalController = true;
      _controller.loadData();
    }
    _controller.addListener(_onControllerChange);
    _startLocationTracking();

    if (widget.routeDestination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.selectBuilding(widget.routeDestination!.id);
      });
    }
  }

  @override
  void didUpdateWidget(covariant UsacCampusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      oldWidget.controller?.removeListener(_onControllerChange);
      _controller = widget.controller!;
      _controller.addListener(_onControllerChange);
    }

    if (widget.routeDestination != oldWidget.routeDestination &&
        widget.routeDestination != null) {
      _controller.selectBuilding(widget.routeDestination!.id);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _controller.removeListener(_onControllerChange);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    final buildings = widget.buildings ?? _controller.buildings;
    CampusBuilding? tappedBuilding;

    for (final b in buildings) {
      if (b.polygon.isNotEmpty &&
          DistanceCalculator.isPointInPolygon(point, b.polygon)) {
        tappedBuilding = b;
        break;
      }
    }

    if (tappedBuilding == null) {
      for (final b in buildings) {
        if (DistanceCalculator.haversineDistance(point, b.center) <= 25.0) {
          tappedBuilding = b;
          break;
        }
      }
    }

    if (tappedBuilding != null) {
      _controller.selectBuilding(tappedBuilding.id);
      widget.onBuildingSelected?.call(tappedBuilding);
      _showBuildingSheet(tappedBuilding);
    } else {
      _controller.selectBuilding(null);
      widget.onBuildingSelected?.call(null);
    }
  }

  void _showBuildingSheet(CampusBuilding building) {
    PoiDetailSheet.show(
      context: context,
      building: building,
      currentFloor: _controller.selectedFloor,
      userLocation: _controller.userLocation,
      theme: widget.theme,
      onNavigate: (mode) async {
        Navigator.of(context).pop();
        var userLoc = _controller.userLocation;
        if (userLoc == null) {
          await _updateCurrentPosition();
          userLoc = _controller.userLocation;
        }
        if (userLoc == null) return;
        final route = _controller.findRoute(
          origin: userLoc,
          destinationId: building.id,
          mode: mode,
        );
        if (route != null) {
          widget.onRouteCalculated?.call(route);
        }
      },
    );
  }

  Future<void> _startLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    await _updateCurrentPosition();
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionReceived);
  }

  Future<void> _updateCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _onPositionReceived(position);
    } catch (_) {}
  }

  void _onPositionReceived(Position position) {
    final userLoc = LatLng(position.latitude, position.longitude);
    _controller.updateUserLocation(userLoc);
    widget.onUserLocationChanged?.call(userLoc);
  }

  Future<void> _handleLocationTap() async {
    if (_controller.userLocation == null) {
      await _updateCurrentPosition();
    }
    _controller.centerOnUser();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBuildings = widget.buildings ?? _controller.buildings;
    final selectedBuilding = _controller.selectedBuilding;
    final currentRoute = _controller.currentRoute;
    final boundary = _controller.boundary;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller.mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 14.0,
            maxZoom: 19.5,
            onTap: _handleMapTap,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: widget.theme.tileUrlTemplate,
              userAgentPackageName: widget.theme.userAgentPackageName,
              tileProvider: widget.theme.tileProvider ??
                  (widget.theme.offlineOnly
                      ? CampusOfflineTileProvider(
                          package: OfflineTilePackage.usacCampusDefault(),
                        )
                      : null),
              maxZoom: 19,
            ),
            if (boundary.isNotEmpty)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: boundary,
                    color: widget.theme.boundaryFillColor,
                    borderColor: widget.theme.boundaryBorderColor,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
            PolygonLayer(
              polygons: effectiveBuildings.map((b) {
                final isSelected = selectedBuilding?.id == b.id;
                final colors = _getPolygonColors(b, isSelected);
                return Polygon(
                  points: b.polygon.isNotEmpty
                      ? b.polygon
                      : _generateSquare(b.center, 25.0),
                  color: colors.$1,
                  borderColor: colors.$2,
                  borderStrokeWidth: isSelected ? 3.0 : 1.5,
                );
              }).toList(),
            ),
            if (currentRoute != null)
              PolylineLayer(
                polylines: _buildRoutePolylines(currentRoute),
              ),
            MarkerLayer(
              markers: _buildMarkers(effectiveBuildings),
            ),
          ],
        ),
        if (currentRoute != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TurnByTurnBanner(
              route: currentRoute,
              theme: widget.theme,
              onClose: () {
                _controller.clearRoute();
                widget.onClearRoute?.call();
              },
            ),
          ),
        if (selectedBuilding != null && selectedBuilding.floorsCount > 1)
          Positioned(
            right: 16.0,
            top: currentRoute != null ? 100.0 : 80.0,
            child: FloorSelector(
              floorsCount: selectedBuilding.floorsCount,
              selectedFloor: _controller.selectedFloor,
              theme: widget.theme,
              onFloorSelected: (level) {
                _controller.selectFloor(level);
              },
            ),
          ),
        if (widget.showControls)
          Positioned(
            right: 16.0,
            bottom: 24.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_usac_center',
                  backgroundColor: Colors.white,
                  foregroundColor: widget.theme.primaryColor,
                  onPressed: () {
                    _controller.mapController.move(
                      const LatLng(14.5868, -90.5518),
                      16.5,
                    );
                  },
                  tooltip: 'Centrar campus',
                  child: const Icon(Icons.school),
                ),
                const SizedBox(height: 8.0),
                FloatingActionButton.small(
                  heroTag: 'fab_usac_location',
                  backgroundColor: Colors.white,
                  foregroundColor: widget.theme.primaryColor,
                  onPressed: _handleLocationTap,
                  tooltip: 'Mi ubicación',
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Polyline> _buildRoutePolylines(CampusRoute route) {
    if (route.edges.isEmpty) {
      return [
        Polyline(
          points: route.points,
          strokeWidth: widget.theme.routeWidth,
          color: widget.theme.routeStandardColor,
        ),
      ];
    }

    final polylines = <Polyline>[];
    for (int i = 0; i < route.edges.length && i + 1 < route.nodes.length; i++) {
      final edge = route.edges[i];
      final start = route.nodes[i].location;
      final end = route.nodes[i + 1].location;

      Color color;
      double width = widget.theme.routeWidth;
      if (edge.type == 'stairs') {
        color = widget.theme.routeStairsColor;
        width += 1.5;
      } else if (edge.type == 'covered') {
        color = widget.theme.routeCoveredColor;
      } else {
        color = widget.theme.routeStandardColor;
      }

      polylines.add(
        Polyline(
          points: [start, end],
          strokeWidth: width,
          color: color,
        ),
      );
    }

    return polylines;
  }

  List<Marker> _buildMarkers(List<CampusBuilding> buildings) {
    final markers = <Marker>[];

    if (_controller.userLocation != null) {
      markers.add(
        Marker(
          point: _controller.userLocation!,
          width: 36.0,
          height: 36.0,
          child: GestureDetector(
            onTap: () =>
                widget.onUserLocationTap?.call(_controller.userLocation!),
            child: Container(
              decoration: BoxDecoration(
                color: widget.theme.userLocationColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.theme.userLocationColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final selected = _controller.selectedBuilding;
    if (selected != null) {
      for (final entrance in selected.entrances) {
        markers.add(
          Marker(
            point: entrance.location,
            width: 28.0,
            height: 28.0,
            child: Tooltip(
              message: entrance.name,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                child: const Icon(
                  Icons.meeting_room,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
            ),
          ),
        );
      }

      final currentFloorPois = selected.floors
          .where((f) => f.level == _controller.selectedFloor)
          .expand((f) => f.pois)
          .toList();

      for (int i = 0; i < currentFloorPois.length; i++) {
        final poi = currentFloorPois[i];
        final offsetLat = selected.center.latitude + (i - 1) * 0.00012;
        final offsetLng = selected.center.longitude + (i - 1) * 0.00012;
        final poiLoc = poi.location ?? LatLng(offsetLat, offsetLng);

        markers.add(
          Marker(
            point: poiLoc,
            width: 32.0,
            height: 32.0,
            child: GestureDetector(
              onTap: () {
                _controller.selectPoi(poi);
                widget.onPoiTapped?.call(poi);
                PoiDetailSheet.show(
                  context: context,
                  building: selected,
                  poi: poi,
                  currentFloor: _controller.selectedFloor,
                  userLocation: _controller.userLocation,
                  theme: widget.theme,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: widget.theme.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                child: const Icon(
                  Icons.place,
                  color: Colors.white,
                  size: 18.0,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (_controller.currentRoute != null &&
        _controller.currentRoute!.points.isNotEmpty) {
      final originPt = _controller.currentRoute!.points.first;
      final destPt = _controller.currentRoute!.points.last;

      markers.add(
        Marker(
          point: originPt,
          width: 30.0,
          height: 30.0,
          child: const Icon(Icons.trip_origin, color: Colors.green, size: 28.0),
        ),
      );

      markers.add(
        Marker(
          point: destPt,
          width: 32.0,
          height: 32.0,
          child: const Icon(Icons.location_on, color: Colors.red, size: 30.0),
        ),
      );
    }

    return markers;
  }

  List<LatLng> _generateSquare(LatLng center, double radiusMeters) {
    const latToMeters = 111320.0;
    const lngToMeters = latToMeters * 0.967;
    final dLat = radiusMeters / latToMeters;
    final dLng = radiusMeters / lngToMeters;

    return [
      LatLng(center.latitude + dLat, center.longitude - dLng),
      LatLng(center.latitude + dLat, center.longitude + dLng),
      LatLng(center.latitude - dLat, center.longitude + dLng),
      LatLng(center.latitude - dLat, center.longitude - dLng),
      LatLng(center.latitude + dLat, center.longitude - dLng),
    ];
  }

  (Color, Color) _getPolygonColors(CampusBuilding b, bool isSelected) {
    if (isSelected) {
      return (
        widget.theme.buildingSelectedColor,
        widget.theme.buildingSelectedBorderColor,
      );
    }
    switch (b.category.toLowerCase()) {
      case 'green_area':
      case 'garden':
      case 'park':
        return (const Color(0x354CAF50), const Color(0xFF2E7D32));
      case 'parking':
        return (const Color(0x30607D8B), const Color(0xFF546E7A));
      case 'sports':
        return (const Color(0x35FF9800), const Color(0xFFE65100));
      default:
        return (
          widget.theme.buildingDefaultColor,
          widget.theme.buildingBorderColor,
        );
    }
  }
}
