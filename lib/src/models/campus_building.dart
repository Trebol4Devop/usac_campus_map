import 'package:latlong2/latlong.dart';

class CampusBuilding {
  final String id;
  final String name;
  final LatLng location;
  final String description;

  const CampusBuilding({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
  });
}
