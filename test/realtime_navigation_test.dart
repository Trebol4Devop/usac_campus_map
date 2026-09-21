import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CampusRoute testRoute;

  setUp(() {
    testRoute = const CampusRoute(
      points: [
        LatLng(14.5860, -90.5520),
        LatLng(14.5865, -90.5520),
        LatLng(14.5870, -90.5520),
        LatLng(14.5870, -90.5510),
      ],
      nodes: [
        CampusNode(id: 'n1', location: LatLng(14.5860, -90.5520)),
        CampusNode(id: 'n2', location: LatLng(14.5865, -90.5520)),
        CampusNode(id: 'n3', location: LatLng(14.5870, -90.5520)),
        CampusNode(id: 'n4', location: LatLng(14.5870, -90.5510)),
      ],
      edges: [
        CampusEdge(source: 'n1', target: 'n2', weight: 55.0, type: 'walkway'),
        CampusEdge(source: 'n2', target: 'n3', weight: 55.0, type: 'walkway'),
        CampusEdge(source: 'n3', target: 'n4', weight: 110.0, type: 'walkway'),
      ],
      totalDistance: 220.0,
      estimatedTimeMinutes: 3.0,
      mode: NavigationMode.pedestrian,
      steps: [
        RouteStep(
          instruction: 'Camine hacia el norte sobre el andador',
          distance: 110.0,
          type: 'walkway',
          location: LatLng(14.5860, -90.5520),
        ),
        RouteStep(
          instruction: 'Gire a la derecha hacia el Edificio T-3',
          distance: 110.0,
          type: 'walkway',
          location: LatLng(14.5870, -90.5520),
        ),
      ],
    );
  });

  group('NavigationVoiceNotifier', () {
    test('Announces steps with distance', () {
      final prompts = <String>[];
      final notifier = NavigationVoiceNotifier(onSpeak: prompts.add);

      notifier.announceStep(testRoute.steps.first, 0, 80.0);
      expect(prompts.length, equals(1));
      expect(prompts.first, contains('En 80 metros'));

      notifier.announceOffRoute(20.0);
      expect(prompts.length, equals(2));
      expect(prompts.last, contains('Desviación detectada'));

      notifier.announceArrival('Edificio T-3');
      expect(prompts.length, equals(3));
      expect(prompts.last, contains('Ha llegado a su destino'));
    });
  });

  group('RealtimeNavigationEngine', () {
    test('Starts navigation and generates tracking state', () {
      final prompts = <String>[];
      final engine = RealtimeNavigationEngine(
        onVoicePrompt: prompts.add,
      );

      engine.startNavigation(testRoute);
      expect(engine.isNavigating, isTrue);
      expect(prompts.isNotEmpty, isTrue);

      final state = engine.updatePosition(
        const LatLng(14.5861, -90.5520),
        heading: 0.0,
      );

      expect(state, isNotNull);
      expect(state!.isOffRoute, isFalse);
      expect(state.currentStepIndex, equals(0));
      expect(state.remainingDistance, isPositive);
    });

    test('Advances step when user approaches waypoint', () {
      final engine = RealtimeNavigationEngine();
      engine.startNavigation(testRoute);

      final state = engine.updatePosition(
        const LatLng(14.5870, -90.5520),
      );

      expect(state, isNotNull);
      expect(state!.currentStepIndex, equals(1));
    });

    test('Triggers deviation callback when user leaves path beyond threshold', () {
      CampusRoute? deviatedRoute;
      LatLng? deviatedPoint;

      final engine = RealtimeNavigationEngine(
        deviationThresholdMeters: 15.0,
        onDeviationDetected: (route, loc) {
          deviatedRoute = route;
          deviatedPoint = loc;
        },
      );

      engine.startNavigation(testRoute);

      const farPoint = LatLng(14.5900, -90.5500);
      final state = engine.updatePosition(farPoint);

      expect(state, isNotNull);
      expect(state!.isOffRoute, isTrue);
      expect(deviatedRoute, equals(testRoute));
      expect(deviatedPoint, equals(farPoint));
    });

    test('Triggers destination reached callback on arrival', () {
      var destinationReached = false;
      final engine = RealtimeNavigationEngine(
        destinationArrivalThresholdMeters: 8.0,
        onDestinationReached: () {
          destinationReached = true;
        },
      );

      engine.startNavigation(testRoute);

      final endPoint = testRoute.points.last;
      final state = engine.updatePosition(endPoint);

      expect(state, isNotNull);
      expect(state!.hasArrived, isTrue);
      expect(destinationReached, isTrue);
      expect(engine.hasArrived, isTrue);
    });
  });

  group('UsacCampusMapController Realtime Navigation Integration', () {
    test('Starts and stops realtime navigation updates', () {
      final controller = UsacCampusMapController();
      controller.startRealtimeNavigation(testRoute);

      expect(controller.isNavigating, isTrue);
      expect(controller.currentRoute, equals(testRoute));

      controller.updateRealtimeUserPosition(
        const LatLng(14.5862, -90.5520),
        heading: 45.0,
      );

      expect(controller.userLocation, isNotNull);
      expect(controller.userHeading, equals(45.0));
      expect(controller.navigationTrackingState, isNotNull);

      controller.stopRealtimeNavigation();
      expect(controller.isNavigating, isFalse);
      expect(controller.navigationTrackingState, isNull);
    });
  });
}
