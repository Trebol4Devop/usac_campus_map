import 'package:flutter/material.dart' hide NavigationMode;
import '../../models/campus_route.dart';
import '../../models/navigation_mode.dart';
import '../themes/usac_map_theme.dart';

class TurnByTurnBanner extends StatelessWidget {
  final CampusRoute route;
  final VoidCallback onClose;
  final UsacMapTheme theme;

  const TurnByTurnBanner({
    super.key,
    required this.route,
    required this.onClose,
    this.theme = const UsacMapTheme(),
  });

  @override
  Widget build(BuildContext context) {
    final firstStep = route.steps.isNotEmpty ? route.steps.first : null;
    final instruction = firstStep?.instruction ?? 'Siga la ruta trazada';

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Material(
          elevation: 6.0,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(16.0),
          color: theme.primaryColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStepIcon(firstStep?.type),
                    color: Colors.white,
                    size: 26.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Text(
                            '${route.totalDistance.toStringAsFixed(0)} m',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Text('•', style: TextStyle(color: Colors.white54)),
                          const SizedBox(width: 8.0),
                          Text(
                            '~${route.estimatedTimeMinutes.ceil()} min',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Text('•', style: TextStyle(color: Colors.white54)),
                          const SizedBox(width: 8.0),
                          Text(
                            _getModeLabel(route.mode),
                            style: TextStyle(
                              color: theme.accentColor,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: onClose,
                  tooltip: 'Cerrar navegación',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStepIcon(String? type) {
    switch (type) {
      case 'stairs':
        return Icons.stairs;
      case 'covered':
        return Icons.roofing;
      case 'roadway':
        return Icons.directions_car;
      case 'arrive':
        return Icons.flag;
      default:
        return Icons.directions_walk;
    }
  }

  String _getModeLabel(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.accessible:
        return 'Accesible';
      case NavigationMode.covered:
        return 'Techado';
      case NavigationMode.vehicle:
        return 'Vehicular';
      case NavigationMode.pedestrian:
        return 'Peatonal';
    }
  }
}
