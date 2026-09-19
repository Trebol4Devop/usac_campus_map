import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/usac_campus_boundary.dart';
import '../data/usac_campus_dataset.dart';
import '../models/building_category.dart';
import '../models/campus_building.dart';
import '../models/campus_route.dart';
import '../services/distance_service.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import 'building_detail_modal.dart';

abstract final class UsacMapTileServers {
  static const String openStreetMap =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> defaultSubdomains = [];
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
  final List<Polyline>? customPolylines;
  final CampusBuilding? routeDestination;
  final CampusRoute? activeRoute;
  final VoidCallback? onClearRoute;
  final Color routeColor;
  final double routeStrokeWidth;
  final bool animateCameraTransitions;
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
  final MapController? mapController;
  final bool showRecenterCampusButton;
  final bool showLocationButton;
  final bool showZoomButtons;
  final bool enableActiveTracking;
  final VoidCallback? onRecenterCampus;
  final ValueChanged<LatLng>? onUserLocationTap;
  final ValueChanged<LatLng>? onUserLocationChanged;

  const UsacCampusMap({
    super.key,
    this.buildings,
    this.onBuildingTap,
    this.markerBuilder,
    this.initialCenter,
    this.initialZoom = 16.5,
    this.minZoom = 15.0,
    this.maxZoom = 19.0,
    this.showCampusBoundary = true,
    this.customPolygons,
    this.customPolylines,
    this.routeDestination,
    this.activeRoute,
    this.onClearRoute,
    this.routeColor = const Color(0xFF002B49),
    this.routeStrokeWidth = 4.5,
    this.animateCameraTransitions = true,
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
    this.mapController,
    this.showRecenterCampusButton = true,
    this.showLocationButton = true,
    this.showZoomButtons = true,
    this.enableActiveTracking = false,
    this.onRecenterCampus,
    this.onUserLocationTap,
    this.onUserLocationChanged,
  });

  @override
  State<UsacCampusMap> createState() => _UsacCampusMapState();
}

class _UsacCampusMapState extends State<UsacCampusMap>
    with TickerProviderStateMixin {
  MapController? _internalMapController;
  MapController get _effectiveMapController =>
      widget.mapController ?? (_internalMapController ??= MapController());
  final CampusLocationService _locationService = CampusLocationService();
  final CampusDistanceService _distanceService = CampusDistanceService();
  final CampusRouteService _routeService = CampusRouteService();
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _currentPosition;
  bool _isInsideCampus = true;
  bool _bannerDismissed = false;
  AnimationController? _cameraAnimController;
  CampusRoute? _internalActiveRoute;

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
            _currentPosition = isInside ? pos : null;
            _isInsideCampus = isInside;
            if (statusChanged && isInside) {
              _bannerDismissed = false;
            }
          });
          if (isInside) {
            if (widget.enableActiveTracking) {
              _animatedMapMove(
                pos,
                _effectiveMapController.camera.zoom,
              );
            }
            widget.onUserLocationChanged?.call(pos);
          }
          if (statusChanged) {
            widget.onCampusStatusChanged?.call(isInside);
          }
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant UsacCampusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController &&
        widget.mapController != null) {
      _internalMapController?.dispose();
      _internalMapController = null;
    }

    if (oldWidget.routeDestination != widget.routeDestination &&
        widget.routeDestination != null) {
      _animatedMapMove(widget.routeDestination!.location, 17.5);
    } else if (oldWidget.activeRoute != widget.activeRoute &&
        widget.activeRoute != null) {
      _animatedMapMove(widget.activeRoute!.destination.location, 17.5);
    }
  }

  @override
  void dispose() {
    _cameraAnimController?.dispose();
    _locationSubscription?.cancel();
    _internalMapController?.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!widget.animateCameraTransitions) {
      _effectiveMapController.move(destLocation, destZoom);
      return;
    }

    _cameraAnimController?.dispose();

    final latTween = Tween<double>(
      begin: _effectiveMapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _effectiveMapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _effectiveMapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cameraAnimController = controller;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    controller.addListener(() {
      _effectiveMapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_cameraAnimController == controller) {
          _cameraAnimController = null;
        }
        controller.dispose();
      }
    });

    controller.forward();
  }

  CampusRoute? get _effectiveRoute {
    if (widget.activeRoute != null) {
      if (!UsacCampusBoundary.isInsideCampus(widget.activeRoute!.origin) ||
          !UsacCampusBoundary.isInsideCampus(
              widget.activeRoute!.destination.location)) {
        return null;
      }
      return widget.activeRoute;
    }
    if (widget.routeDestination != null) {
      if (!_isInsideCampus) {
        return null;
      }
      final origin = _currentPosition ?? UsacCampusDataset.campusCenter;
      return _routeService.calculateRoute(
        origin: origin,
        destination: widget.routeDestination!,
      );
    }
    return _internalActiveRoute;
  }

  void _clearEffectiveRoute() {
    setState(() {
      _internalActiveRoute = null;
    });
    widget.onClearRoute?.call();
  }

  void _setInternalRouteToBuilding(CampusBuilding building) {
    final origin = _currentPosition;
    if (origin == null || !UsacCampusBoundary.isInsideCampus(origin)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes estar dentro del Campus Central para trazar una ruta a pie.',
            ),
          ),
        );
      }
      return;
    }
    final route = _routeService.calculateRoute(
      origin: origin,
      destination: building,
    );
    if (route != null) {
      setState(() {
        _internalActiveRoute = route;
      });
      _animatedMapMove(building.location, 17.5);
    }
  }

  List<CampusBuilding> get _activeBuildings {
    final source = widget.buildings != null && widget.buildings!.isNotEmpty
        ? List<CampusBuilding>.from(widget.buildings!)
        : List<CampusBuilding>.from(UsacCampusDataset.allBuildings);

    final destId = _effectiveRoute?.destination.id;
    if (destId != null) {
      final destIndex = source.indexWhere((b) => b.id == destId);
      if (destIndex != -1) {
        final target = source.removeAt(destIndex);
        source.add(target);
      }
    }

    return source;
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

  List<Polyline> get _polylines {
    final list = <Polyline>[];
    if (widget.customPolylines != null) {
      list.addAll(widget.customPolylines!);
    }

    final currentRoute = _effectiveRoute;
    if (currentRoute != null && currentRoute.points.length >= 2) {
      list.add(
        Polyline(
          points: currentRoute.points,
          strokeWidth: widget.routeStrokeWidth,
          color: widget.routeColor,
          borderColor: Colors.white,
          borderStrokeWidth: 2.0,
        ),
      );
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
    final isDestination = _effectiveRoute?.destination.id == building.id;

    return GestureDetector(
      onTap: () {
        if (widget.onBuildingTap != null) {
          widget.onBuildingTap!(building);
        } else {
          BuildingDetailModal.show(
            context: context,
            building: building,
            referencePosition: _currentPosition,
            onNavigate: () {
              Navigator.of(context).pop();
              _setInternalRouteToBuilding(building);
            },
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDestination ? const Color(0xFFDC2626) : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDestination ? const Color(0xFFFDE047) : Colors.white,
            width: isDestination ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDestination
                  ? const Color(0x66DC2626)
                  : Colors.black26,
              blurRadius: isDestination ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isDestination ? Icons.flag : icon,
          color: Colors.white,
          size: isDestination ? 22 : 20,
        ),
      ),
    );
  }

  void _zoomIn() {
    final currentZoom = _effectiveMapController.camera.zoom;
    if (currentZoom < widget.maxZoom) {
      final targetZoom =
          (currentZoom + 1.0).clamp(widget.minZoom, widget.maxZoom);
      _animatedMapMove(
        _effectiveMapController.camera.center,
        targetZoom,
      );
    }
  }

  void _zoomOut() {
    final currentZoom = _effectiveMapController.camera.zoom;
    if (currentZoom > widget.minZoom) {
      final targetZoom =
          (currentZoom - 1.0).clamp(widget.minZoom, widget.maxZoom);
      _animatedMapMove(
        _effectiveMapController.camera.center,
        targetZoom,
      );
    }
  }

  void _recenterCampus() {
    _animatedMapMove(
      widget.initialCenter ?? UsacCampusDataset.campusCenter,
      widget.initialZoom,
    );
    widget.onRecenterCampus?.call();
  }

  Future<void> _goToUserLocation() async {
    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El servicio de ubicacion se encuentra desactivado.'),
          ),
        );
      }
      return;
    }

    if (_currentPosition != null &&
        UsacCampusBoundary.isInsideCampus(_currentPosition!)) {
      _animatedMapMove(_currentPosition!, 17.0);
      widget.onUserLocationTap?.call(_currentPosition!);
      return;
    }

    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      final isInside = UsacCampusBoundary.isInsideCampus(pos);
      if (!isInside) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tu ubicacion actual se encuentra fuera del Campus Central.',
              ),
            ),
          );
        }
        return;
      }
      setState(() {
        _currentPosition = pos;
        _isInsideCampus = true;
      });
      _animatedMapMove(pos, 17.0);
      widget.onUserLocationTap?.call(pos);
      widget.onUserLocationChanged?.call(pos);
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? const Color(0xFF002B49),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polygons = _polygons;
    final polylines = _polylines;
    final activeRoute = _effectiveRoute;

    final mapWidget = RepaintBoundary(
      child: FlutterMap(
        mapController: _effectiveMapController,
        options: MapOptions(
          initialCenter: widget.initialCenter ??
              widget.activeRoute?.destination.location ??
              widget.routeDestination?.location ??
              UsacCampusDataset.campusCenter,
          initialZoom:
              (widget.routeDestination != null || widget.activeRoute != null)
                  ? 17.0
                  : widget.initialZoom,
          maxZoom: widget.maxZoom,
          minZoom: widget.minZoom,
          cameraConstraint: widget.cameraConstraint ??
              CameraConstraint.containCenter(
                bounds: UsacCampusBoundary.defaultCameraBounds,
              ),
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
            tileBounds:
                widget.tileBounds ?? UsacCampusBoundary.defaultCameraBounds,
            evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
          ),
          if (polygons.isNotEmpty)
            PolygonLayer(
              polygons: polygons,
            ),
          if (polylines.isNotEmpty)
            PolylineLayer(
              polylines: polylines,
            ),
          MarkerLayer(
            markers: [
              ..._activeBuildings.map(
                (building) => Marker(
                  point: building.location,
                  width: 38,
                  height: 38,
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

    final hasActiveBanner = widget.showOutOfCampusBanner &&
        _currentPosition != null &&
        !_isInsideCampus &&
        !_bannerDismissed;
    final showAnyControl = widget.showRecenterCampusButton ||
        widget.showLocationButton ||
        widget.showZoomButtons;
    final hasActiveRoute = activeRoute != null;

    if (!hasActiveBanner && !showAnyControl && !hasActiveRoute) {
      return mapWidget;
    }

    return Stack(
      children: [
        Positioned.fill(child: mapWidget),
        if (hasActiveRoute)
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF002B49).withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF002B49).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Color(0xFF002B49),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ruta a ${activeRoute.destination.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF002B49),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Distancia: ${_distanceService.formatDistance(activeRoute.distanceInMeters)} (${_distanceService.formatWalkingTime(activeRoute.estimatedDuration)} a pie)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Cancelar ruta',
                      onPressed: _clearEffectiveRoute,
                      splashRadius: 18,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (showAnyControl)
          Positioned(
            right: 16,
            bottom: hasActiveBanner ? 88 : 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showZoomButtons) ...[
                  _buildControlButton(
                    icon: Icons.add,
                    onPressed: _zoomIn,
                    tooltip: 'Acercar',
                  ),
                  const SizedBox(height: 6),
                  _buildControlButton(
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                    tooltip: 'Alejar',
                  ),
                  const SizedBox(height: 10),
                ],
                if (widget.showRecenterCampusButton) ...[
                  _buildControlButton(
                    icon: Icons.account_balance,
                    onPressed: _recenterCampus,
                    tooltip: 'Centrar en Campus Central',
                  ),
                  const SizedBox(height: 10),
                ],
                if (widget.showLocationButton)
                  _buildControlButton(
                    icon: _currentPosition != null
                        ? Icons.my_location
                        : Icons.location_searching,
                    onPressed: _goToUserLocation,
                    tooltip: 'Mi ubicacion',
                    iconColor: _currentPosition != null
                        ? Colors.blueAccent
                        : Colors.grey,
                  ),
              ],
            ),
          ),
        if (hasActiveBanner)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFFBEB),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFF59E0B), width: 1.2),
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
                            'No estas en la universidad, pero puedes navegar el mapa con normalidad.',
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
