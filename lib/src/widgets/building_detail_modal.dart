import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/usac_campus_boundary.dart';
import '../data/usac_campus_dataset.dart';
import '../models/campus_building.dart';
import '../services/distance_service.dart';

class BuildingDetailModal extends StatelessWidget {
  final CampusBuilding building;
  final LatLng? referencePosition;
  final VoidCallback? onNavigate;
  final VoidCallback? onClose;

  const BuildingDetailModal({
    super.key,
    required this.building,
    this.referencePosition,
    this.onNavigate,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required CampusBuilding building,
    LatLng? referencePosition,
    VoidCallback? onNavigate,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BuildingDetailModal(
        building: building,
        referencePosition: referencePosition,
        onNavigate: onNavigate,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceService = CampusDistanceService();
    final effectiveReference =
        referencePosition ?? UsacCampusDataset.campusCenter;
    final distanceMeters =
        distanceService.calculateBuildingDistance(effectiveReference, building);
    final distanceText = distanceService.formatDistance(distanceMeters);
    final walkingDuration =
        distanceService.estimateCampusWalkingDuration(distanceMeters);
    final walkingText = distanceService.formatWalkingTime(walkingDuration);
    final categoryColor = building.category.color;
    final categoryIcon = building.category.icon;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF002B49),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (building.acronym != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF002B49),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                building.acronym!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              building.category.label,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              building.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (building.floors != null) ...[
              Row(
                children: [
                  Icon(Icons.layers_outlined,
                      size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Niveles: ${building.floors}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (building.entrances.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.door_front_door_outlined,
                      size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          building.entrances.length == 1
                              ? 'Acceso: ${building.entrances.first.name}'
                              : 'Accesos disponibles:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (building.entrances.length > 1)
                          ...building.entrances.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    e.isAccessible
                                        ? Icons.accessible
                                        : Icons.chevron_right,
                                    size: 14,
                                    color: e.isAccessible
                                        ? const Color(0xFF0F766E)
                                        : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      e.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 18,
                  color: Color(0xFF002B49),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    referencePosition != null &&
                            !UsacCampusBoundary.isInsideCampus(
                                referencePosition!)
                        ? 'Tu ubicacion actual se encuentra fuera del Campus Central'
                        : referencePosition != null && distanceMeters <= 25
                            ? 'En este edificio (< 1 min a pie)'
                            : referencePosition == null
                                ? 'Desde centro USAC: $distanceText ($walkingText a pie)'
                                : 'Distancia actual: $distanceText ($walkingText a pie)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B49),
                    ),
                  ),
                ),
              ],
            ),
            if (onNavigate != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('Cómo llegar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002B49),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
