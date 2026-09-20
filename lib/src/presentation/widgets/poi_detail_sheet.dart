import 'package:flutter/material.dart' hide NavigationMode;
import 'package:latlong2/latlong.dart';
import '../../models/campus_building.dart';
import '../../models/campus_poi.dart';
import '../../models/navigation_mode.dart';
import '../themes/usac_map_theme.dart';

class PoiDetailSheet extends StatelessWidget {
  final CampusBuilding? building;
  final CampusPoi? poi;
  final int currentFloor;
  final LatLng? userLocation;
  final UsacMapTheme theme;
  final void Function(NavigationMode mode)? onNavigate;
  final VoidCallback? onClose;

  const PoiDetailSheet({
    super.key,
    this.building,
    this.poi,
    this.currentFloor = 1,
    this.userLocation,
    this.theme = const UsacMapTheme(),
    this.onNavigate,
    this.onClose,
  });

  static Future<void> show({
    required BuildContext context,
    CampusBuilding? building,
    CampusPoi? poi,
    int currentFloor = 1,
    LatLng? userLocation,
    UsacMapTheme theme = const UsacMapTheme(),
    void Function(NavigationMode mode)? onNavigate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PoiDetailSheet(
        building: building,
        poi: poi,
        currentFloor: currentFloor,
        userLocation: userLocation,
        theme: theme,
        onNavigate: onNavigate,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = poi?.name ?? building?.name ?? 'Detalles del Lugar';
    final code = poi?.code ?? building?.code ?? '';
    final category = poi?.category ?? building?.category ?? '';

    final floorPois = (building?.floors ?? [])
        .where((f) => f.level == currentFloor)
        .expand((f) => f.pois)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: theme.primaryColor,
                  size: 28.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        if (code.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              code,
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (building != null) ...[
                          const SizedBox(width: 6.0),
                          Text(
                            '• ${building!.floorsCount} niveles',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose ?? () => Navigator.of(context).pop(),
              ),
            ],
          ),
          if (floorPois.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Text(
              'En Nivel $currentFloor:',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 6.0,
              children: floorPois.map((p) {
                return Chip(
                  label: Text(p.name),
                  labelStyle: const TextStyle(fontSize: 12.0),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(color: Colors.grey.shade300),
                  avatar: Icon(_getCategoryIcon(p.category), size: 16.0),
                );
              }).toList(),
            ),
          ],
          if (building?.entrances.isNotEmpty ?? false) ...[
            const SizedBox(height: 16.0),
            Text(
              'Accesos Peatonales:',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 6.0),
            ...building!.entrances.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room,
                        size: 16.0, color: Colors.grey),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        e.name,
                        style: const TextStyle(fontSize: 13.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20.0),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  icon: const Icon(Icons.directions_walk),
                  label: const Text(
                    'Cómo llegar / Trazar Ruta',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    onNavigate?.call(NavigationMode.pedestrian);
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton.filledTonal(
                tooltip: 'Ruta Techada (Lluvia)',
                icon: const Icon(Icons.roofing),
                onPressed: () {
                  onNavigate?.call(NavigationMode.covered);
                },
              ),
              IconButton.filledTonal(
                tooltip: 'Ruta Accesible (Sin Gradas)',
                icon: const Icon(Icons.accessible),
                onPressed: () {
                  onNavigate?.call(NavigationMode.accessible);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'faculty':
        return Icons.school;
      case 'library':
      case 'bibliotecas':
        return Icons.local_library;
      case 'administrative':
      case 'oficinas':
        return Icons.account_balance;
      case 'health':
        return Icons.local_hospital;
      case 'sports':
        return Icons.sports_soccer;
      case 'plaza':
      case 'monumentos':
        return Icons.flag;
      case 'cafeterias':
        return Icons.restaurant;
      case 'cajeros':
        return Icons.atm;
      case 'sanitarios':
        return Icons.wc;
      case 'laboratorios':
        return Icons.biotech;
      case 'aulas':
        return Icons.meeting_room;
      default:
        return Icons.place;
    }
  }
}
