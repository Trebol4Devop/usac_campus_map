import '../models/campus_route.dart';

class NavigationVoiceNotifier {
  final void Function(String prompt)? onSpeak;
  int? _lastAnnouncedStepIndex;
  double _lastAnnouncedDistance = -1.0;
  bool _reroutingAnnounced = false;
  bool _arrivalAnnounced = false;

  NavigationVoiceNotifier({this.onSpeak});

  void announceStep(RouteStep step, int stepIndex, double distanceMeters) {
    if (onSpeak == null) return;

    final shouldAnnounce = _lastAnnouncedStepIndex != stepIndex ||
        (_lastAnnouncedDistance - distanceMeters).abs() > 35.0;

    if (!shouldAnnounce) return;

    _lastAnnouncedStepIndex = stepIndex;
    _lastAnnouncedDistance = distanceMeters;
    _reroutingAnnounced = false;

    final distanceRounded = (distanceMeters / 5).round() * 5;
    final message = distanceRounded <= 10
        ? step.instruction
        : 'En $distanceRounded metros, ${step.instruction.toLowerCase()}';

    onSpeak!(message);
  }

  void announceOffRoute(double deviationMeters) {
    if (onSpeak == null || _reroutingAnnounced) return;
    _reroutingAnnounced = true;
    final devRounded = deviationMeters.round();
    onSpeak!('Desviación detectada de $devRounded metros. Recalculando ruta sancarlista.');
  }

  void announceRerouting() {
    if (onSpeak == null) return;
    onSpeak!('Ruta recalculada. Continúe con la nueva instrucción.');
  }

  void announceArrival(String destinationName) {
    if (onSpeak == null || _arrivalAnnounced) return;
    _arrivalAnnounced = true;
    onSpeak!('Ha llegado a su destino: $destinationName.');
  }

  void reset() {
    _lastAnnouncedStepIndex = null;
    _lastAnnouncedDistance = -1.0;
    _reroutingAnnounced = false;
    _arrivalAnnounced = false;
  }
}
