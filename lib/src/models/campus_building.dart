import 'package:latlong2/latlong.dart';
import 'building_category.dart';
import 'building_entrance.dart';

class CampusBuilding {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final String? acronym;
  final BuildingCategory category;
  final int? floors;

  /// Puertas o accesos peatonales oficiales del edificio.
  final List<BuildingEntrance> entrances;

  /// Contorno poligonal arquitectonico del edificio.
  final List<LatLng>? polygonFootprint;

  const CampusBuilding({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    this.acronym,
    this.category = BuildingCategory.faculty,
    this.floors,
    this.entrances = const [],
    this.polygonFootprint,
  });

  /// Retorna la entrada principal del edificio.
  /// Si no se definieron entradas especificas, retorna una entrada por defecto en la ubicacion del edificio.
  BuildingEntrance get primaryEntrance => entrances.isNotEmpty
      ? entrances.first
      : BuildingEntrance(
          id: '$id-main',
          name: 'Entrada Principal',
          location: location,
        );
}
