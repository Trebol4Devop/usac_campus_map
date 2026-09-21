import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import '../core/algorithms/snap_to_path.dart';
import '../core/utils/distance_calculator.dart';
import '../models/campus_route.dart';
import '../models/navigation_tracking_state.dart';
import 'navigation_voice_notifier.dart';

class RealtimeNavigationEngine {
  final double deviationThresholdMeters;
  final double stepArrivalThresholdMeters;
  final double destinationArrivalThresholdMeters;

  final void Function(CampusRoute oldRoute, LatLng currentLocation)?
      onDeviationDetected;
  final void Function(String prompt)? onVoicePrompt;
  final void Function()? onDestinationReached;
  final void Function(NavigationTrackingState state)? onStateUpdated;

  late final NavigationVoiceNotifier _voiceNotifier;

  CampusRoute? _activeRoute;
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  bool _hasArrived = false;
  NavigationTrackingState? _currentState;

  RealtimeNavigationEngine({
    this.deviationThresholdMeters = 15.0,
    this.stepArrivalThresholdMeters = 10.0,
    this.destinationArrivalThresholdMeters = 8.0,
    this.onDeviationDetected,
    this.onVoicePrompt,
    this.onDestinationReached,
    this.onStateUpdated,
  }) {
    _voiceNotifier = NavigationVoiceNotifier(onSpeak: onVoicePrompt);
  }

  bool get isNavigating => _isNavigating;
  bool get hasArrived => _hasArrived;
  CampusRoute? get activeRoute => _activeRoute;
  NavigationTrackingState? get currentState => _currentState;

  void startNavigation(CampusRoute route) {
    _activeRoute = route;
    _currentStepIndex = 0;
    _isNavigating = true;
    _hasArrived = false;
    _voiceNotifier.reset();

    if (route.steps.isNotEmpty) {
      _voiceNotifier.announceStep(
        route.steps.first,
        0,
        route.steps.first.distance,
      );
    }
  }

  void stopNavigation() {
    _isNavigating = false;
    _activeRoute = null;
    _currentState = null;
    _voiceNotifier.reset();
  }

  void updateRoute(CampusRoute newRoute) {
    _activeRoute = newRoute;
    _currentStepIndex = 0;
    _hasArrived = false;
    _voiceNotifier.announceRerouting();
    if (newRoute.steps.isNotEmpty) {
      _voiceNotifier.announceStep(
        newRoute.steps.first,
        0,
        newRoute.steps.first.distance,
      );
    }
  }

  NavigationTrackingState? updatePosition(
    LatLng rawPosition, {
    double? heading,
    double? speed,
  }) {
    if (!_isNavigating || _activeRoute == null) return null;

    final route = _activeRoute!;
    if (route.points.isEmpty) return null;

    final destination = route.points.last;
    final distToDestination = DistanceCalculator.haversineDistance(
      rawPosition,
      destination,
    );

    if (distToDestination <= destinationArrivalThresholdMeters && !_hasArrived) {
      _hasArrived = true;
      _voiceNotifier.announceArrival('su destino');
      onDestinationReached?.call();

      final arrivalState = NavigationTrackingState(
        route: route,
        rawPosition: rawPosition,
        snappedPosition: destination,
        currentStepIndex: route.steps.isNotEmpty ? route.steps.length - 1 : 0,
        distanceToNextStep: 0.0,
        remainingDistance: 0.0,
        remainingDurationSeconds: 0,
        isOffRoute: false,
        offRouteDistance: 0.0,
        userHeading: heading,
        hasArrived: true,
      );
      _currentState = arrivalState;
      onStateUpdated?.call(arrivalState);
      return arrivalState;
    }

    final segments = <PathSegment>[];
    for (var i = 0; i < route.points.length - 1; i++) {
      segments.add(
        PathSegment(start: route.points[i], end: route.points[i + 1]),
      );
    }

    final snapResult = SnapToPath.snapPoint(
      rawPosition,
      segments,
      maxRadiusMeters: deviationThresholdMeters,
    );

    final isOffRoute = !snapResult.isSnapped;
    final offRouteDistance = snapResult.distanceMeters;

    if (isOffRoute) {
      _voiceNotifier.announceOffRoute(offRouteDistance);
      onDeviationDetected?.call(route, rawPosition);
    }

    final effectiveSnapped = snapResult.point;

    _advanceStepIfNeeded(effectiveSnapped, route);

    final distanceToNext = _calculateDistanceToNextStep(
      effectiveSnapped,
      route,
      _currentStepIndex,
    );
    final remainingDist = _calculateRemainingDistance(
      effectiveSnapped,
      route,
    );
    final remainingSeconds = (remainingDist / 1.2).round();

    if (!_hasArrived && _currentStepIndex < route.steps.length) {
      _voiceNotifier.announceStep(
        route.steps[_currentStepIndex],
        _currentStepIndex,
        distanceToNext,
      );
    }

    final newState = NavigationTrackingState(
      route: route,
      rawPosition: rawPosition,
      snappedPosition: effectiveSnapped,
      currentStepIndex: _currentStepIndex,
      distanceToNextStep: distanceToNext,
      remainingDistance: remainingDist,
      remainingDurationSeconds: remainingSeconds,
      isOffRoute: isOffRoute,
      offRouteDistance: offRouteDistance,
      userHeading: heading,
      hasArrived: _hasArrived,
    );

    _currentState = newState;
    onStateUpdated?.call(newState);
    return newState;
  }

  void _advanceStepIfNeeded(LatLng snapped, CampusRoute route) {
    if (_currentStepIndex >= route.steps.length - 1) return;

    final nextStep = route.steps[_currentStepIndex + 1];
    final distanceToStep = DistanceCalculator.haversineDistance(
      snapped,
      nextStep.location,
    );

    if (distanceToStep <= stepArrivalThresholdMeters) {
      _currentStepIndex++;
    }
  }

  double _calculateDistanceToNextStep(
    LatLng snapped,
    CampusRoute route,
    int stepIndex,
  ) {
    if (route.steps.isEmpty || stepIndex >= route.steps.length) {
      return 0.0;
    }
    return DistanceCalculator.haversineDistance(
      snapped,
      route.steps[stepIndex].location,
    );
  }

  double _calculateRemainingDistance(LatLng snapped, CampusRoute route) {
    if (route.points.isEmpty) return 0.0;
    if (route.points.length == 1) {
      return DistanceCalculator.haversineDistance(snapped, route.points.first);
    }

    var closestSegmentIndex = 0;
    var minDistance = double.infinity;

    for (var i = 0; i < route.points.length - 1; i++) {
      final segStart = route.points[i];
      final segEnd = route.points[i + 1];
      final segSnap = SnapToPath.snapPoint(
        snapped,
        [PathSegment(start: segStart, end: segEnd)],
        maxRadiusMeters: double.infinity,
      );
      if (segSnap.distanceMeters < minDistance) {
        minDistance = segSnap.distanceMeters;
        closestSegmentIndex = i;
      }
    }

    var total = DistanceCalculator.haversineDistance(
      snapped,
      route.points[closestSegmentIndex + 1],
    );

    for (var i = closestSegmentIndex + 1; i < route.points.length - 1; i++) {
      total += DistanceCalculator.haversineDistance(
        route.points[i],
        route.points[i + 1],
      );
    }

    return total;
  }
}
