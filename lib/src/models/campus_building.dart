import 'package:latlong2/latlong.dart';
import 'building_category.dart';

class CampusBuilding {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final String? acronym;
  final BuildingCategory category;
  final int? floors;

  const CampusBuilding({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    this.acronym,
    this.category = BuildingCategory.faculty,
    this.floors,
  });
}
