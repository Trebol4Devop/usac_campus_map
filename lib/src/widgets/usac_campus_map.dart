import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/usac_campus_map_controller.dart';
import '../data/usac_campus_boundary.dart';
import '../data/usac_campus_dataset.dart';
import '../models/building_category.dart';
import '../models/campus_building.dart';
import '../models/campus_route.dart';
import '../models/walkway_type.dart';
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
  final bool clipToCampus;
  final Color campusCutoutColor;
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
  final UsacCampusMapController? controller;
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
    this.clipToCampus = true,
    this.campusCutoutColor = Colors.white,
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
    this.controller,
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
    with TickerProviderStateMixin
    implements UsacCampusMapDelegate {
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
  String? _highlightedBuildingId;
  BuildingCategory? _controllerCategoryFilter;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
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
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }

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
    widget.controller?.detach();
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

  @override
  void moveCamera(LatLng center, double zoom, {bool animate = true}) {
    if (animate) {
      _animatedMapMove(center, zoom);
    } else {
      _effectiveMapController.move(center, zoom);
    }
  }

  @override
  void fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(40),
    bool animate = true,
  }) {
    _effectiveMapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: padding,
      ),
    );
  }

  @override
  void setActiveRoute(CampusRoute? route) {
    setState(() {
      _internalActiveRoute = route;
    });
  }

  @override
  void setHighlightedBuilding(String? buildingId) {
    setState(() {
      _highlightedBuildingId = buildingId;
    });
  }

  @override
  void setCategoryFilter(BuildingCategory? category) {
    setState(() {
      _controllerCategoryFilter = category;
    });
  }

  @override
  LatLng? get currentUserLocation => _currentPosition;

  @override
  bool get isInsideCampus => _isInsideCampus;

  @override
  double get currentZoom => _effectiveMapController.camera.zoom;

  @override
  LatLng get currentCenter => _effectiveMapController.camera.center;

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
      final origin = (_currentPosition != null && _isInsideCampus)
          ? _currentPosition!
          : UsacCampusDataset.campusCenter;
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
    widget.controller?.notifyRouteClearedFromUi();
    widget.onClearRoute?.call();
  }

  void _setInternalRouteToBuilding(CampusBuilding building) {
    final origin = _currentPosition;
    CampusRoute? route;

    if (origin != null && UsacCampusBoundary.isInsideCampus(origin)) {
      route = _routeService.calculateRoute(
        origin: origin,
        destination: building,
      );
    } else {
      route = _routeService.calculateRoute(
        origin: UsacCampusDataset.campusCenter,
        destination: building,
      );
      if (route != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ruta calculada desde el centro del campus. Activa tu ubicación para mayor precisión.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    if (route != null) {
      setState(() {
        _internalActiveRoute = route;
      });
      _animatedMapMove(building.location, 17.5);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo calcular la ruta a este edificio.'),
        ),
      );
    }
  }

  List<CampusBuilding> get _activeBuildings {
    var source = widget.buildings != null && widget.buildings!.isNotEmpty
        ? List<CampusBuilding>.from(widget.buildings!)
        : List<CampusBuilding>.from(UsacCampusDataset.allBuildings);

    if (_controllerCategoryFilter != null) {
      source = source
          .where((b) => b.category == _controllerCategoryFilter)
          .toList();
    }

    final highlightId = _highlightedBuildingId;
    if (highlightId != null) {
      final hIndex = source.indexWhere((b) => b.id == highlightId);
      if (hIndex != -1) {
        final target = source.removeAt(hIndex);
        source.add(target);
      }
    }

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
    if (widget.clipToCampus) {
      list.add(
        UsacCampusBoundary.createCampusCutoutMask(
          color: widget.campusCutoutColor,
          borderColor: Colors.transparent,
          borderStrokeWidth: 0.0,
          disableHolesBorder: true,
        ),
      );
    }
    if (widget.showCampusBoundary && !widget.clipToCampus) {
      list.add(UsacCampusBoundary.defaultPerimeterPolygon);
    }
    if (widget.customPolygons != null) {
      list.addAll(widget.customPolygons!);
    }
    
    for (final building in _activeBuildings) {
      if (building.polygonFootprint != null) {
        final isSpecial = _effectiveRoute?.destination.id == building.id ||
            _highlightedBuildingId == building.id;
        
        list.add(
          Polygon(
            points: building.polygonFootprint!,
            color: isSpecial
                ? const Color(0xFF002B49).withValues(alpha: 0.3)
                : building.category.color.withValues(alpha: 0.15),
            borderColor: isSpecial
                ? const Color(0xFF002B49)
                : building.category.color.withValues(alpha: 0.8),
            borderStrokeWidth: isSpecial ? 2.5 : 1.5,
          ),
        );
      }
    }
    
    return list;
  }

  List<Polyline> get _polylines {
    final list = <Polyline>[];
    if (widget.clipToCampus && widget.showCampusBoundary) {
      list.addAll(UsacCampusBoundary.createCampusPerimeterShadowPolylines());
    }
    if (widget.customPolylines != null) {
      list.addAll(widget.customPolylines!);
    }

    final currentRoute = _effectiveRoute;
    if (currentRoute != null && currentRoute.points.length >= 2) {
      if (currentRoute.segments.isNotEmpty) {
        for (final segment in currentRoute.segments) {
          if (segment.points.length >= 2) {
            Color segmentColor;
            switch (segment.type) {
              case WalkwayType.corridor:
                segmentColor = const Color(0xFF1E40AF);
                break;
              case WalkwayType.pathway:
                segmentColor = const Color(0xFF0F766E);
                break;
              case WalkwayType.street:
                segmentColor = const Color(0xFFB45309);
                break;
            }
            list.add(
              Polyline(
                points: segment.points,
                strokeWidth: widget.routeStrokeWidth,
                color: segmentColor,
                borderColor: Colors.white,
                borderStrokeWidth: 1.5,
              ),
            );
          }
        }
      } else {
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
    }

    return list;
  }

  Widget _buildDefaultMarker(CampusBuilding building) {
    final color = building.category.color;
    final icon = building.category.icon;
    final isDestination = _effectiveRoute?.destination.id == building.id;
    final isHighlighted = _highlightedBuildingId == building.id;
    final hasSpecialStatus = isDestination || isHighlighted;

    double currentZoomLevel;
    try {
      currentZoomLevel = _effectiveMapController.camera.zoom;
    } catch (_) {
      currentZoomLevel = widget.initialZoom;
    }
    final showLabel = currentZoomLevel >= 17.0;
    final labelText = building.acronym ?? 
        (building.name.length > 12 ? '${building.name.substring(0, 10)}...' : building.name);

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: building.name,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isDestination
                    ? const Color(0xFFDC2626)
                    : (isHighlighted ? const Color(0xFF002B49) : color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDestination
                      ? const Color(0xFFFDE047)
                      : (isHighlighted ? const Color(0xFFF59E0B) : Colors.white),
                  width: hasSpecialStatus ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDestination
                        ? const Color(0x66DC2626)
                        : (isHighlighted ? const Color(0x66002B49) : Colors.black26),
                    blurRadius: hasSpecialStatus ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isDestination
                    ? Icons.flag
                    : (isHighlighted ? Icons.stars : icon),
                color: Colors.white,
                size: hasSpecialStatus ? 22 : 20,
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDestination
                      ? const Color(0xFFDC2626)
                      : (isHighlighted ? const Color(0xFF002B49) : color),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
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

  Widget _walkwayLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
          onTap: (tapPosition, point) {
            for (final building in _activeBuildings) {
              if (building.polygonFootprint != null) {
                if (UsacCampusBoundary.isPointInPolygon(
                    point, building.polygonFootprint!)) {
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
                  return;
                }
              }
            }
            if (_highlightedBuildingId != null) {
              setState(() {
                _highlightedBuildingId = null;
              });
              widget.controller?.clearHighlight();
            }
          },
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
                (building) {
                  return Marker(
                    point: building.location,
                    width: 80,
                    height: 65,
                    alignment: Alignment.center,
                    child: RepaintBoundary(
                      child: widget.markerBuilder?.call(context, building) ??
                          _buildDefaultMarker(building),
                    ),
                  );
                },
              ),
              if (_effectiveRoute?.destinationEntrance != null)
                Marker(
                  point: _effectiveRoute!.destinationEntrance!.location,
                  width: 32,
                  height: 32,
                  child: RepaintBoundary(
                    child: Tooltip(
                      message: _effectiveRoute!.destinationEntrance!.name,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
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
                        child: const Icon(
                          Icons.meeting_room,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
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

    return Stack(
      children: [
        mapWidget,
        if (activeRoute != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF002B49).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_walk,
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
                                '${_distanceService.formatDistance(activeRoute.distanceInMeters)} · ${_distanceService.formatWalkingTime(activeRoute.estimatedDuration)} a pie',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (activeRoute.destinationEntrance != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Acceso por: ${activeRoute.destinationEntrance!.name}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F766E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                    if (activeRoute.segments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _walkwayLegendDot(const Color(0xFF1E40AF), 'Techado'),
                          const SizedBox(width: 12),
                          _walkwayLegendDot(const Color(0xFF0F766E), 'Peatonal'),
                          const SizedBox(width: 12),
                          _walkwayLegendDot(const Color(0xFFB45309), 'Calle'),
                        ],
                      ),
                    ],
                    if (activeRoute.steps.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Ver indicaciones (${activeRoute.steps.length} pasos)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002B49),
                            ),
                          ),
                          leading: const Icon(
                            Icons.list_alt,
                            size: 18,
                            color: Color(0xFF002B49),
                          ),
                          children: activeRoute.steps
                              .asMap()
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF002B49)
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF002B49),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
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
