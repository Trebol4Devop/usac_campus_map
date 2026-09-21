import 'package:flutter/material.dart' hide NavigationMode;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../engine/campus_data_repository.dart';
import '../engine/realtime_navigation_engine.dart';
import '../engine/route_engine.dart';
import '../engine/search_engine.dart';
import '../models/campus_building.dart';
import '../models/campus_poi.dart';
import '../models/campus_route.dart';
import '../models/navigation_mode.dart';
import '../models/navigation_tracking_state.dart';

class UsacCampusMapController extends ChangeNotifier {
  final CampusDataRepository repository;
  final MapController mapController;

  late RouteEngine _routeEngine;
  late SearchEngine _searchEngine;
  RealtimeNavigationEngine? _navigationEngine;

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
  double? _userHeading;
  String _searchQuery = '';
  List<SearchResult> _searchResults = const [];
  NavigationMode _navigationMode = NavigationMode.pedestrian;
  NavigationTrackingState? _navigationTrackingState;
  void Function(String prompt)? onVoicePrompt;
  bool _is3DMode = false;
  bool _is3DWalkingViewOpen = false;
  bool _followUserHeading = false;

  UsacCampusMapController({
    CampusDataRepository? repository,
    MapController? mapController,
    this.onVoicePrompt,
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
  double? get userHeading => _userHeading;
  String get searchQuery => _searchQuery;
  List<SearchResult> get searchResults => _searchResults;
  NavigationMode get navigationMode => _navigationMode;
  RouteEngine get routeEngine => _routeEngine;
  SearchEngine get searchEngine => _searchEngine;
  RealtimeNavigationEngine? get navigationEngine => _navigationEngine;
  NavigationTrackingState? get navigationTrackingState =>
      _navigationTrackingState;
  bool get isNavigating => _navigationEngine?.isNavigating ?? false;
  List<CampusBuilding> get buildings => repository.buildings;
  List<LatLng> get boundary => repository.boundary;
  bool get is3DMode => _is3DMode;
  bool get is3DWalkingViewOpen => _is3DWalkingViewOpen;
  bool get followUserHeading => _followUserHeading;

  void toggle3DMode() {
    _is3DMode = !_is3DMode;
    notifyListeners();
  }

  void set3DMode(bool enabled) {
    if (_is3DMode != enabled) {
      _is3DMode = enabled;
      notifyListeners();
    }
  }

  void toggle3DWalkingView() {
    _is3DWalkingViewOpen = !_is3DWalkingViewOpen;
    notifyListeners();
  }

  void set3DWalkingViewOpen(bool open) {
    if (_is3DWalkingViewOpen != open) {
      _is3DWalkingViewOpen = open;
      notifyListeners();
    }
  }

  void open3DWalkingView() {
    set3DWalkingViewOpen(true);
  }

  void close3DWalkingView() {
    set3DWalkingViewOpen(false);
  }

  void setFollowUserHeading(bool follow) {
    if (_followUserHeading != follow) {
      _followUserHeading = follow;
      notifyListeners();
    }
  }

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
    if (route != null) {
      startRealtimeNavigation(route);
    } else {
      stopRealtimeNavigation();
    }
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
    if (route != null) {
      startRealtimeNavigation(route);
    } else {
      stopRealtimeNavigation();
    }
    notifyListeners();
    return route;
  }

  void startRealtimeNavigation(
    CampusRoute route, {
    bool autoReroute = true,
    void Function(String prompt)? onVoicePromptCallback,
  }) {
    _currentRoute = route;
    _navigationEngine = RealtimeNavigationEngine(
      onVoicePrompt: onVoicePromptCallback ?? onVoicePrompt,
      onStateUpdated: (state) {
        _navigationTrackingState = state;
        notifyListeners();
      },
      onDeviationDetected: (oldRoute, currentLocation) {
        if (autoReroute && _currentDestinationId != null) {
          final newRoute = _routeEngine.findRoute(
            origin: currentLocation,
            destinationId: _currentDestinationId!,
            mode: _navigationMode,
          );
          if (newRoute != null) {
            _currentRoute = newRoute;
            _navigationEngine?.updateRoute(newRoute);
            notifyListeners();
          }
        }
      },
      onDestinationReached: () {
        notifyListeners();
      },
    );

    _navigationEngine!.startNavigation(route);
    if (_userLocation != null) {
      _navigationEngine!.updatePosition(
        _userLocation!,
        heading: _userHeading,
      );
    }
    notifyListeners();
  }

  void stopRealtimeNavigation() {
    _navigationEngine?.stopNavigation();
    _navigationEngine = null;
    _navigationTrackingState = null;
    notifyListeners();
  }

  void updateRealtimeUserPosition(
    LatLng location, {
    double? heading,
    double? speed,
  }) {
    _userLocation = location;
    if (heading != null) {
      _userHeading = heading;
    }
    if (_navigationEngine != null && _navigationEngine!.isNavigating) {
      _navigationEngine!.updatePosition(
        location,
        heading: heading ?? _userHeading,
        speed: speed,
      );
    }
    if (_followUserHeading && _userHeading != null) {
      try {
        mapController.rotate(-_userHeading!);
        mapController.move(location, mapController.camera.zoom);
      } catch (_) {}
    }
    notifyListeners();
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
    stopRealtimeNavigation();
    _currentRoute = null;
    _currentOriginBuilding = null;
    _currentOriginLocation = null;
    _currentDestinationId = null;
    notifyListeners();
  }

  void updateUserLocation(LatLng location, {double? heading}) {
    updateRealtimeUserPosition(location, heading: heading);
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
