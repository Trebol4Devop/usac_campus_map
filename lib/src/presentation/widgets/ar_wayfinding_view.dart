import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/ar_waypoint.dart';
import '../themes/usac_map_theme.dart';

class ArWayfindingView extends StatelessWidget {
  final List<ArProjectionResult> projections;
  final ValueChanged<ArWaypoint>? onWaypointTap;
  final UsacMapTheme theme;

  const ArWayfindingView({
    super.key,
    required this.projections,
    this.onWaypointTap,
    this.theme = const UsacMapTheme(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final proj in projections) ...[
              if (proj.isVisibleInFov)
                _buildInFovCard(proj, constraints)
              else
                _buildEdgeIndicator(proj, constraints),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInFovCard(ArProjectionResult proj, BoxConstraints constraints) {
    final scale = (1.0 - (proj.distanceMeters / 600.0)).clamp(0.65, 1.1);

    return Positioned(
      left: proj.screenPosition.dx - 90.0,
      top: proj.screenPosition.dy - 40.0,
      child: Transform.scale(
        scale: scale,
        child: GestureDetector(
          onTap: () => onWaypointTap?.call(proj.waypoint),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(16.0),
            color: theme.primaryColor.withValues(alpha: 0.92),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              constraints: const BoxConstraints(maxWidth: 180.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getWaypointIcon(proj.waypoint.type),
                        color: theme.accentColor,
                        size: 18.0,
                      ),
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: Text(
                          proj.waypoint.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${proj.distanceMeters.toStringAsFixed(0)} m',
                    style: TextStyle(
                      color: theme.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeIndicator(
      ArProjectionResult proj, BoxConstraints constraints) {
    final cx = constraints.maxWidth / 2.0;
    final cy = constraints.maxHeight / 2.0;
    const margin = 32.0;

    final cosA = cos(proj.indicatorAngle);
    final sinA = sin(proj.indicatorAngle);

    final edgeX = (cx + cosA * (cx - margin))
        .clamp(margin, constraints.maxWidth - margin);
    final edgeY = (cy + sinA * (cy - margin))
        .clamp(margin, constraints.maxHeight - margin);

    return Positioned(
      left: edgeX - 22.0,
      top: edgeY - 22.0,
      child: GestureDetector(
        onTap: () => onWaypointTap?.call(proj.waypoint),
        child: Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.accentColor, width: 2.0),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 6.0),
            ],
          ),
          child: Transform.rotate(
            angle: proj.indicatorAngle,
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20.0,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWaypointIcon(String type) {
    switch (type) {
      case 'entrance':
        return Icons.door_front_door;
      case 'poi':
        return Icons.place;
      case 'step':
        return Icons.navigation;
      default:
        return Icons.apartment;
    }
  }
}
