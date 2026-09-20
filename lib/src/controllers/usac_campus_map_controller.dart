import 'package:flutter/material.dart' hide NavigationMode;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../engine/campus_data_repository.dart';
import '../engine/route_engine.dart';
import '../engine/search_engine.dart';
import '../models/campus_building.dart';
import '../models/campus_poi.dart';
import '../models/campus_route.dart';
import '../models/navigation_mode.dart';

class UsacCampusMapController extends ChangeNotifier {
  final CampusDataRepository repository;
  final MapController mapController;

  late RouteEngine _routeEngine;
  late SearchEngine _searchEngine;

  bool _isLoading = false;
  bool _isLoaded = false;
  CampusRoute? _currentRoute;
  CampusBuilding? _selectedBuilding;
  CampusBuilding? _currentOriginBuilding;
  LatLng? _currentOriginLocation;
  String? _currentDestinationId;
  CampusPoi? _selectedPoi;
  int _selectedFloor = 1;
  LatLng? _userLocation;
  String _searchQuery = '';
  List<SearchResult> _searchResults = const [];
  NavigationMode _navigationMode = NavigationMode.pedestrian;

  UsacCampusMapController({
    CampusDataRepository? repository,
    MapController? mapController,
  })  : repository = repository ?? CampusDataRepository(),
        mapController = mapController ?? MapController() {
    _routeEngine = RouteEngine(repository: this.repository);
    _searchEngine = SearchEngine(repository: this.repository);
  }

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  CampusRoute? get currentRoute => _currentRoute;
  CampusBuilding? get selectedBuilding => _selectedBuilding;
  CampusPoi? get selectedPoi => _selectedPoi;
  int get selectedFloor => _selectedFloor;
  LatLng? get userLocation => _userLocation;
  String get searchQuery => _searchQuery;
  List<SearchResult> get searchResults => _searchResults;
  NavigationMode get navigationMode => _navigationMode;
  RouteEngine get routeEngine => _routeEngine;
  SearchEngine get searchEngine => _searchEngine;
  List<CampusBuilding> get buildings => repository.buildings;
  List<LatLng> get boundary => repository.boundary;

  Future<void> loadData({AssetBundle? bundle}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await repository.loadFromAssets(bundle: bundle);
      _routeEngine = RouteEngine(repository: repository);
      _searchEngine = SearchEngine(repository: repository);
      _isLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  CampusRoute? findRoute({
    required LatLng origin,
    required String destinationId,
    NavigationMode? mode,
  }) {
    final effectiveMode = mode ?? _navigationMode;
    _navigationMode = effectiveMode;
    _currentOriginLocation = origin;
    _currentOriginBuilding = null;
    _currentDestinationId = destinationId;
    final route = _routeEngine.findRoute(
      origin: origin,
      destinationId: destinationId,
      mode: effectiveMode,
    );
    _currentRoute = route;
    notifyListeners();
    return route;
  }

  CampusRoute? startRouteBetweenBuildings({
    required CampusBuilding origin,
    required CampusBuilding destination,
    NavigationMode mode = NavigationMode.pedestrian,
  }) {
    _navigationMode = mode;
    _currentOriginBuilding = origin;
    _currentOriginLocation = origin.entrances.isNotEmpty
        ? origin.entrances.first.location
        : origin.center;
    _currentDestinationId = destination.id;
    final route = _routeEngine.findRouteBetweenBuildings(
      originBuildingId: origin.id,
      destinationBuildingId: destination.id,
      mode: mode,
    );
    _currentRoute = route;
    _selectedBuilding = destination;
    notifyListeners();
    return route;
  }

  List<SearchResult> search(String query, {String? category}) {
    _searchQuery = query;
    _searchResults = _searchEngine.search(query, category: category);
    notifyListeners();
    return _searchResults;
  }

  void selectBuilding(String? buildingId) {
    if (buildingId == null) {
      _selectedBuilding = null;
      _selectedFloor = 1;
      _selectedPoi = null;
    } else {
      _selectedBuilding = repository.buildingsById[buildingId];
      _selectedFloor = 1;
      _selectedPoi = null;
      if (_selectedBuilding != null) {
        try {
          mapController.move(_selectedBuilding!.center, 17.5);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  void highlightBuilding(String buildingId) {
    selectBuilding(buildingId);
  }

  void selectFloor(int level) {
    _selectedFloor = level;
    _selectedPoi = null;
    notifyListeners();
  }

  void selectPoi(CampusPoi? poi) {
    _selectedPoi = poi;
    if (poi != null) {
      _selectedFloor = poi.floorLevel;
      if (_selectedBuilding?.id != poi.buildingId) {
        _selectedBuilding = repository.buildingsById[poi.buildingId];
      }
    }
    notifyListeners();
  }

  void clearRoute() {
    _currentRoute = null;
    _currentOriginBuilding = null;
    _currentOriginLocation = null;
    _currentDestinationId = null;
    notifyListeners();
  }

  void updateUserLocation(LatLng location) {
    _userLocation = location;
    notifyListeners();
  }

  void setNavigationMode(NavigationMode mode) {
    _navigationMode = mode;
    if (_currentRoute != null) {
      if (_currentOriginBuilding != null && _selectedBuilding != null) {
        startRouteBetweenBuildings(
          origin: _currentOriginBuilding!,
          destination: _selectedBuilding!,
          mode: mode,
        );
        return;
      }
      if (_currentOriginLocation != null && _currentDestinationId != null) {
        findRoute(
          origin: _currentOriginLocation!,
          destinationId: _currentDestinationId!,
          mode: mode,
        );
        return;
      }
      if (_userLocation != null && _selectedBuilding != null) {
        findRoute(
          origin: _userLocation!,
          destinationId: _selectedBuilding!.id,
          mode: mode,
        );
        return;
      }
    }
    notifyListeners();
  }

  void centerOnUser() {
    if (_userLocation != null) {
      try {
        mapController.move(_userLocation!, 17.5);
      } catch (_) {}
    }
  }

  void centerOnBounds(LatLngBounds bounds) {
    try {
      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(24.0)),
      );
    } catch (_) {}
  }
}
