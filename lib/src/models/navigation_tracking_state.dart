import 'package:latlong2/latlong.dart';
import 'campus_route.dart';

class NavigationTrackingState {
  final CampusRoute route;
  final LatLng rawPosition;
  final LatLng snappedPosition;
  final int currentStepIndex;
  final double distanceToNextStep;
  final double remainingDistance;
  final int remainingDurationSeconds;
  final bool isOffRoute;
  final double offRouteDistance;
  final double? userHeading;
  final bool hasArrived;

  const NavigationTrackingState({
    required this.route,
    required this.rawPosition,
    required this.snappedPosition,
    required this.currentStepIndex,
    required this.distanceToNextStep,
    required this.remainingDistance,
    required this.remainingDurationSeconds,
    required this.isOffRoute,
    required this.offRouteDistance,
    this.userHeading,
    required this.hasArrived,
  });

  RouteStep? get currentStep {
    if (route.steps.isEmpty || currentStepIndex >= route.steps.length) {
      return null;
    }
    return route.steps[currentStepIndex];
  }

  RouteStep? get nextStep {
    final nextIndex = currentStepIndex + 1;
    if (nextIndex >= route.steps.length) {
      return null;
    }
    return route.steps[nextIndex];
  }

  int get totalSteps => route.steps.length;

  double get progressPercentage {
    if (route.totalDistanceMeters <= 0.0) return 1.0;
    final traversed = route.totalDistanceMeters - remainingDistance;
    return (traversed / route.totalDistanceMeters).clamp(0.0, 1.0);
  }
}
