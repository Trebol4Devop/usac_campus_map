import 'dart:math';
import 'package:flutter/material.dart' hide NavigationMode;
import 'package:latlong2/latlong.dart' hide DistanceCalculator, Path;
import '../../core/utils/distance_calculator.dart';
import '../../models/campus_building.dart';
import '../../models/campus_route.dart';
import '../../models/navigation_tracking_state.dart';
import '../themes/usac_map_theme.dart';

class CampusWalk3DView extends StatefulWidget {
  final CampusRoute route;
  final List<CampusBuilding> buildings;
  final LatLng? initialLocation;
  final double? initialHeading;
  final UsacMapTheme theme;
  final NavigationTrackingState? trackingState;
  final VoidCallback? onClose;
  final ValueChanged<LatLng>? onLocationChanged;
  final VoidCallback? onDestinationReached;

  const CampusWalk3DView({
    super.key,
    required this.route,
    required this.buildings,
    this.initialLocation,
    this.initialHeading,
    this.theme = const UsacMapTheme(),
    this.trackingState,
    this.onClose,
    this.onLocationChanged,
    this.onDestinationReached,
  });

  @override
  State<CampusWalk3DView> createState() => _CampusWalk3DViewState();
}

class _CampusWalk3DViewState extends State<CampusWalk3DView>
    with SingleTickerProviderStateMixin {
  late LatLng _currentLocation;
  double _cameraHeading = 0.0;
  int _currentStepIndex = 0;
  bool _manualHeadingAdjusted = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation ??
        (widget.route.points.isNotEmpty
            ? widget.route.points.first
            : const LatLng(14.5868, -90.5518));

    if (widget.initialLocation != null && widget.route.points.isNotEmpty) {
      int closestIdx = 0;
      double minDistance = double.infinity;
      for (int i = 0; i < widget.route.points.length; i++) {
        final d = DistanceCalculator.haversineDistance(
          widget.initialLocation!,
          widget.route.points[i],
        );
        if (d < minDistance) {
          minDistance = d;
          closestIdx = i;
        }
      }
      _currentStepIndex = closestIdx;
    }

    if (widget.initialHeading != null) {
      _cameraHeading = widget.initialHeading!;
    } else if (widget.route.points.length >= 2) {
      _cameraHeading = DistanceCalculator.calculateBearing(
        widget.route.points[0],
        widget.route.points[1],
      );
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant CampusWalk3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != null &&
        widget.initialLocation != oldWidget.initialLocation) {
      _currentLocation = widget.initialLocation!;
      if (!_manualHeadingAdjusted && widget.initialHeading != null) {
        _cameraHeading = widget.initialHeading!;
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _advanceAlongRoute(double distanceMeters) {
    if (widget.route.points.isEmpty) return;

    final points = widget.route.points;
    if (_currentStepIndex >= points.length - 1) {
      widget.onDestinationReached?.call();
      return;
    }

    var remainingToAdvance = distanceMeters;
    var stepIdx = _currentStepIndex;
    var curLoc = _currentLocation;

    while (remainingToAdvance > 0 && stepIdx < points.length - 1) {
      final nextPt = points[stepIdx + 1];
      final distToNext = DistanceCalculator.haversineDistance(curLoc, nextPt);

      if (remainingToAdvance < distToNext) {
        final ratio = remainingToAdvance / distToNext;
        final newLat =
            curLoc.latitude + (nextPt.latitude - curLoc.latitude) * ratio;
        final newLng =
            curLoc.longitude + (nextPt.longitude - curLoc.longitude) * ratio;
        curLoc = LatLng(newLat, newLng);
        remainingToAdvance = 0.0;
      } else {
        remainingToAdvance -= distToNext;
        stepIdx++;
        curLoc = points[stepIdx];
      }
    }

    setState(() {
      _currentStepIndex = stepIdx;
      _currentLocation = curLoc;
      if (!_manualHeadingAdjusted && stepIdx < points.length - 1) {
        _cameraHeading = DistanceCalculator.calculateBearing(
          curLoc,
          points[stepIdx + 1],
        );
      }
    });

    widget.onLocationChanged?.call(curLoc);

    if (_currentStepIndex >= points.length - 1) {
      widget.onDestinationReached?.call();
    }
  }

  void _resetToHeading() {
    final points = widget.route.points;
    if (_currentStepIndex < points.length - 1) {
      final nextPt = points[_currentStepIndex + 1];
      final targetHeading =
          DistanceCalculator.calculateBearing(_currentLocation, nextPt);
      setState(() {
        _cameraHeading = targetHeading;
        _manualHeadingAdjusted = false;
      });
    }
  }

  double _calculateRemainingDistance() {
    final points = widget.route.points;
    if (points.isEmpty || _currentStepIndex >= points.length - 1) {
      return 0.0;
    }

    var remaining = DistanceCalculator.haversineDistance(
      _currentLocation,
      points[_currentStepIndex + 1],
    );

    for (var i = _currentStepIndex + 1; i < points.length - 1; i++) {
      remaining +=
          DistanceCalculator.haversineDistance(points[i], points[i + 1]);
    }

    return remaining;
  }

  RouteStep? _findCurrentRouteStep() {
    if (widget.route.steps.isEmpty) return null;
    if (widget.trackingState?.currentStep != null) {
      return widget.trackingState!.currentStep;
    }
    final ratio = widget.route.points.isNotEmpty
        ? (_currentStepIndex / widget.route.points.length).clamp(0.0, 1.0)
        : 0.0;
    final stepIndex = (ratio * widget.route.steps.length)
        .floor()
        .clamp(0, widget.route.steps.length - 1);
    return widget.route.steps[stepIndex];
  }

  @override
  Widget build(BuildContext context) {
    final remainingDist = _calculateRemainingDistance();
    final remainingMinutes = (remainingDist / (1.2 * 60.0)).ceil();
    final currentStep = _findCurrentRouteStep();
    final isArrived =
        remainingDist <= 6.0 || _currentStepIndex >= widget.route.points.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _cameraHeading =
                      (_cameraHeading - (details.delta.dx * 0.4) + 360.0) % 360.0;
                  _manualHeadingAdjusted = true;
                });
              },
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CampusWalk3DPainter(
                      currentLocation: _currentLocation,
                      cameraHeading: _cameraHeading,
                      routePoints: widget.route.points,
                      currentStepIndex: _currentStepIndex,
                      buildings: widget.buildings,
                      theme: widget.theme,
                      pulseAnimationValue: _animController.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            Positioned(
              top: 12.0,
              left: 16.0,
              right: 16.0,
              child: Material(
                elevation: 8.0,
                color: widget.theme.primaryColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.0,
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isArrived
                              ? Icons.flag
                              : _getStepIcon(currentStep?.type),
                          color: Colors.white,
                          size: 28.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isArrived
                                  ? 'Has llegado a tu destino'
                                  : (currentStep?.instruction ??
                                      'Avanza por el sendero principal'),
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
                                  '${remainingDist.toStringAsFixed(0)} m restantes',
                                  style: TextStyle(
                                    color: widget.theme.accentColor,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                const Text('•',
                                    style: TextStyle(color: Colors.white38)),
                                const SizedBox(width: 8.0),
                                Text(
                                  '~$remainingMinutes min a pie',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                        tooltip: 'Salir de Vista 3D',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 96.0,
              right: 16.0,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'fab_walk_compass_reset',
                    backgroundColor: _manualHeadingAdjusted
                        ? widget.theme.accentColor
                        : Colors.white.withValues(alpha: 0.85),
                    foregroundColor: _manualHeadingAdjusted
                        ? Colors.black
                        : widget.theme.primaryColor,
                    onPressed: _resetToHeading,
                    tooltip: 'Alinear vista con la ruta',
                    child: Transform.rotate(
                      angle: -_cameraHeading * pi / 180.0,
                      child: const Icon(Icons.navigation, size: 20.0),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24.0,
              left: 20.0,
              right: 20.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app,
                            color: Colors.white70, size: 16.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'Arrastra para mirar 360° • ${_cameraHeading.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          icon: const Icon(Icons.directions_walk),
                          label: const Text(
                            'Simular Paso (10 m)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: isArrived
                              ? null
                              : () => _advanceAlongRoute(10.0),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        onPressed: isArrived
                            ? null
                            : () => _advanceAlongRoute(30.0),
                        child: const Text(
                          '+30 m',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
}

class _CampusWalk3DPainter extends CustomPainter {
  final LatLng currentLocation;
  final double cameraHeading;
  final List<LatLng> routePoints;
  final int currentStepIndex;
  final List<CampusBuilding> buildings;
  final UsacMapTheme theme;
  final double pulseAnimationValue;

  const _CampusWalk3DPainter({
    required this.currentLocation,
    required this.cameraHeading,
    required this.routePoints,
    required this.currentStepIndex,
    required this.buildings,
    required this.theme,
    required this.pulseAnimationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.44;

    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F2027),
          Color(0xFF203A43),
          Color(0xFF2C5364),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    final groundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E3A2F),
          Color(0xFF2E5A44),
          Color(0xFF3B6E52),
        ],
      ).createShader(
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      groundPaint,
    );

    final horizonLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      horizonLinePaint,
    );

    _drawWalkwayPath(canvas, size, horizonY);
    _drawBuildingsIn3D(canvas, size, horizonY);
    _drawTurnDirectionIndicator(canvas, size, horizonY);
  }

  void _drawWalkwayPath(Canvas canvas, Size size, double horizonY) {
    if (routePoints.isEmpty) return;

    final pathPoly = Path();
    final halfBottomWidth = size.width * 0.38;
    final halfTopWidth = size.width * 0.04;
    final centerX = size.width * 0.5;

    pathPoly.moveTo(centerX - halfBottomWidth, size.height);
    pathPoly.lineTo(centerX - halfTopWidth, horizonY);
    pathPoly.lineTo(centerX + halfTopWidth, horizonY);
    pathPoly.lineTo(centerX + halfBottomWidth, size.height);
    pathPoly.close();

    final walkwayPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF616161),
          Color(0xFF757575),
          Color(0xFF9E9E9E),
        ],
      ).createShader(
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      );
    canvas.drawPath(pathPoly, walkwayPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX - halfBottomWidth, size.height),
      Offset(centerX - halfTopWidth, horizonY),
      borderPaint,
    );
    canvas.drawLine(
      Offset(centerX + halfBottomWidth, size.height),
      Offset(centerX + halfTopWidth, horizonY),
      borderPaint,
    );

    for (int i = 0; i < 4; i++) {
      final t = (pulseAnimationValue + (i * 0.25)) % 1.0;
      final y = horizonY + (size.height - horizonY) * t;
      final arrowSize = 10.0 + 24.0 * t;

      final arrowPaint = Paint()
        ..color = theme.accentColor.withValues(alpha: 0.35 + 0.6 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + 3.0 * t
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final arrowPath = Path();
      arrowPath.moveTo(centerX - arrowSize, y + arrowSize * 0.5);
      arrowPath.lineTo(centerX, y - arrowSize * 0.4);
      arrowPath.lineTo(centerX + arrowSize, y + arrowSize * 0.5);
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  void _drawBuildingsIn3D(Canvas canvas, Size size, double horizonY) {
    final buildingsWithDist = <_BuildingPerspective>[];

    for (final b in buildings) {
      final dist = DistanceCalculator.haversineDistance(
        currentLocation,
        b.center,
      );
      if (dist > 300.0) continue;

      final bearing = DistanceCalculator.calculateBearing(
        currentLocation,
        b.center,
      );
      final relAngle = ((bearing - cameraHeading + 540.0) % 360.0) - 180.0;

      if (relAngle.abs() <= 85.0 && dist >= 3.0) {
        buildingsWithDist.add(_BuildingPerspective(
          building: b,
          distanceMeters: dist,
          relativeAngleDegrees: relAngle,
        ));
      }
    }

    buildingsWithDist.sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));

    for (final bp in buildingsWithDist) {
      _renderBuildingBlock(canvas, size, horizonY, bp);
    }
  }

  void _renderBuildingBlock(
    Canvas canvas,
    Size size,
    double horizonY,
    _BuildingPerspective bp,
  ) {
    const fovX = 75.0;
    final normalizedX = bp.relativeAngleDegrees / (fovX / 2.0);
    final screenCenterX = (size.width * 0.5) + (normalizedX * (size.width * 0.5));

    final distFactor = (1.0 - (bp.distanceMeters / 300.0)).clamp(0.05, 1.0);
    final scale = pow(distFactor, 1.6).toDouble();

    final buildingWidth = (140.0 * scale).clamp(24.0, 320.0);
    final floors = max(1, bp.building.floorsCount);
    final buildingHeight = (floors * 38.0 * scale).clamp(20.0, 260.0);

    final baseY = horizonY + (size.height - horizonY) * (1.0 - distFactor * 0.65);
    final topY = baseY - buildingHeight;

    final left = screenCenterX - (buildingWidth * 0.5);
    final right = screenCenterX + (buildingWidth * 0.5);

    final facadeRect = Rect.fromLTRB(left, topY, right, baseY);

    final depthOffset = bp.relativeAngleDegrees >= 0.0
        ? -(buildingWidth * 0.25)
        : (buildingWidth * 0.25);

    final isSelected = bp.distanceMeters < 50.0;
    final wallColor = isSelected
        ? const Color(0xFF1565C0).withValues(alpha: 0.9)
        : const Color(0xFF263238).withValues(alpha: 0.88);

    final wallPaint = Paint()..color = wallColor;
    canvas.drawRect(facadeRect, wallPaint);

    final roofPath = Path();
    roofPath.moveTo(left, topY);
    roofPath.lineTo(left + depthOffset, topY - (buildingHeight * 0.15));
    roofPath.lineTo(right + depthOffset, topY - (buildingHeight * 0.15));
    roofPath.lineTo(right, topY);
    roofPath.close();

    final roofPaint = Paint()
      ..color = isSelected
          ? theme.accentColor.withValues(alpha: 0.95)
          : const Color(0xFF455A64).withValues(alpha: 0.95);
    canvas.drawPath(roofPath, roofPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(facadeRect, borderPaint);
    canvas.drawPath(roofPath, borderPaint);

    if (floors > 1 && buildingHeight > 45.0) {
      final floorLinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1.0;
      for (int f = 1; f < floors; f++) {
        final fy = baseY - (buildingHeight * (f / floors));
        canvas.drawLine(Offset(left, fy), Offset(right, fy), floorLinePaint);
      }
    }

    _drawFloatingBuildingBadge(
      canvas,
      bp.building,
      Offset(screenCenterX, topY - (buildingHeight * 0.15) - 18.0),
      bp.distanceMeters,
      scale,
    );
  }

  void _drawFloatingBuildingBadge(
    Canvas canvas,
    CampusBuilding building,
    Offset position,
    double distanceMeters,
    double scale,
  ) {
    final code = building.code.isNotEmpty ? building.code : building.name;
    final badgeText = '$code • ${distanceMeters.toStringAsFixed(0)} m';

    final textSpan = TextSpan(
      text: badgeText,
      style: TextStyle(
        color: Colors.white,
        fontSize: (11.0 * scale).clamp(9.0, 13.0),
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const badgePadding = EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0);
    final badgeWidth = textPainter.width + badgePadding.horizontal;
    final badgeHeight = textPainter.height + badgePadding.vertical;

    final badgeRect = Rect.fromCenter(
      center: position,
      width: badgeWidth,
      height: badgeHeight,
    );

    final bgPaint = Paint()
      ..color = theme.primaryColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = theme.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(4.0));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        position.dx - (textPainter.width * 0.5),
        position.dy - (textPainter.height * 0.5),
      ),
    );
  }

  void _drawTurnDirectionIndicator(Canvas canvas, Size size, double horizonY) {
    if (routePoints.isEmpty || currentStepIndex >= routePoints.length - 1) {
      return;
    }

    final nextPt = routePoints[currentStepIndex + 1];
    final distToNext = DistanceCalculator.haversineDistance(
      currentLocation,
      nextPt,
    );

    if (distToNext > 45.0) return;

    final targetBearing = DistanceCalculator.calculateBearing(
      currentLocation,
      nextPt,
    );
    final relTurnAngle =
        ((targetBearing - cameraHeading + 540.0) % 360.0) - 180.0;

    final centerX = size.width * 0.5;
    final arrowY = size.height * 0.62;

    canvas.save();
    canvas.translate(centerX, arrowY);
    canvas.rotate(relTurnAngle * pi / 180.0);

    final arrowPaint = Paint()
      ..color = theme.accentColor
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    arrowPath.moveTo(0, -28);
    arrowPath.lineTo(16, 8);
    arrowPath.lineTo(6, 4);
    arrowPath.lineTo(6, 26);
    arrowPath.lineTo(-6, 26);
    arrowPath.lineTo(-6, 4);
    arrowPath.lineTo(-16, 8);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CampusWalk3DPainter oldDelegate) {
    return oldDelegate.currentLocation != currentLocation ||
        oldDelegate.cameraHeading != cameraHeading ||
        oldDelegate.currentStepIndex != currentStepIndex ||
        oldDelegate.pulseAnimationValue != pulseAnimationValue;
  }
}

class _BuildingPerspective {
  final CampusBuilding building;
  final double distanceMeters;
  final double relativeAngleDegrees;

  const _BuildingPerspective({
    required this.building,
    required this.distanceMeters,
    required this.relativeAngleDegrees,
  });
}
