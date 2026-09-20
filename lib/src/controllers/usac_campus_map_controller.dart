import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/usac_campus_dataset.dart';
import '../models/building_category.dart';
import '../models/campus_building.dart';
import '../models/campus_route.dart';
import '../services/route_service.dart';

abstract class UsacCampusMapDelegate {
  void moveCamera(LatLng center, double zoom, {bool animate = true});
  void fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(40),
    bool animate = true,
  });
  void setActiveRoute(CampusRoute? route);
  void setHighlightedBuilding(String? buildingId);
  void setCategoryFilter(BuildingCategory? category);
  LatLng? get currentUserLocation;
  bool get isInsideCampus;
  double get currentZoom;
  LatLng get currentCenter;
}

class UsacCampusMapController extends ChangeNotifier {
  UsacCampusMapDelegate? _delegate;
  final CampusRouteService _routeService = CampusRouteService();

  String? _highlightedBuildingId;
  CampusRoute? _currentRoute;
  BuildingCategory? _categoryFilter;

  String? get highlightedBuildingId => _highlightedBuildingId;
  CampusRoute? get currentRoute => _currentRoute;
  BuildingCategory? get categoryFilter => _categoryFilter;
  bool get isAttached => _delegate != null;
  LatLng? get currentUserLocation => _delegate?.currentUserLocation;
  bool get isInsideCampus => _delegate?.isInsideCampus ?? false;
  double? get currentZoom => _delegate?.currentZoom;
  LatLng? get currentCenter => _delegate?.currentCenter;

  void attach(UsacCampusMapDelegate delegate) {
    _delegate = delegate;
    if (_highlightedBuildingId != null) {
      _delegate?.setHighlightedBuilding(_highlightedBuildingId);
    }
    if (_currentRoute != null) {
      _delegate?.setActiveRoute(_currentRoute);
    }
    if (_categoryFilter != null) {
      _delegate?.setCategoryFilter(_categoryFilter);
    }
  }

  void detach() {
    _delegate = null;
  }

  void focusBuilding(
    String buildingId, {
    bool animate = true,
    double zoom = 18.0,
  }) {
    final building = UsacCampusDataset.getById(buildingId);
    if (building != null) {
      _highlightedBuildingId = buildingId;
      _delegate?.setHighlightedBuilding(buildingId);
      _delegate?.moveCamera(building.location, zoom, animate: animate);
      notifyListeners();
    }
  }

  void focusLocation(
    LatLng location, {
    bool animate = true,
    double zoom = 17.5,
  }) {
    _delegate?.moveCamera(location, zoom, animate: animate);
  }

  void highlightBuilding(String? buildingId) {
    _highlightedBuildingId = buildingId;
    _delegate?.setHighlightedBuilding(buildingId);
    notifyListeners();
  }

  void clearHighlight() {
    _highlightedBuildingId = null;
    _delegate?.setHighlightedBuilding(null);
    notifyListeners();
  }

  CampusRoute? startRoute({
    required LatLng origin,
    required CampusBuilding destination,
    bool fitCamera = true,
  }) {
    final route = _routeService.calculateRoute(
      origin: origin,
      destination: destination,
    );
    if (route != null) {
      _currentRoute = route;
      _delegate?.setActiveRoute(route);
      if (fitCamera && route.points.length >= 2) {
        final bounds = LatLngBounds.fromPoints(route.points);
        _delegate?.fitBounds(bounds, animate: true);
      }
      notifyListeners();
    }
    return route;
  }

  CampusRoute? startRouteBetweenBuildings({
    required CampusBuilding origin,
    required CampusBuilding destination,
    bool fitCamera = true,
  }) {
    return startRoute(
      origin: origin.location,
      destination: destination,
      fitCamera: fitCamera,
    );
  }

  void clearRoute() {
    _currentRoute = null;
    _delegate?.setActiveRoute(null);
    notifyListeners();
  }

  void notifyRouteClearedFromUi() {
    _currentRoute = null;
    notifyListeners();
  }

  void setCategoryFilter(BuildingCategory? category) {
    _categoryFilter = category;
    _delegate?.setCategoryFilter(category);
    notifyListeners();
  }

  void clearCategoryFilter() {
    setCategoryFilter(null);
  }

  void recenterCampus({bool animate = true}) {
    _delegate?.moveCamera(
      UsacCampusDataset.campusCenter,
      16.5,
      animate: animate,
    );
  }

  void zoomIn({bool animate = true}) {
    final zoom = _delegate?.currentZoom;
    if (zoom != null) {
      final target = (zoom + 1.0).clamp(15.0, 19.0);
      final center = _delegate?.currentCenter ?? UsacCampusDataset.campusCenter;
      _delegate?.moveCamera(center, target, animate: animate);
    }
  }

  void zoomOut({bool animate = true}) {
    final zoom = _delegate?.currentZoom;
    if (zoom != null) {
      final target = (zoom - 1.0).clamp(15.0, 19.0);
      final center = _delegate?.currentCenter ?? UsacCampusDataset.campusCenter;
      _delegate?.moveCamera(center, target, animate: animate);
    }
  }

  void fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(40),
    bool animate = true,
  }) {
    _delegate?.fitBounds(bounds, padding: padding, animate: animate);
  }
}
