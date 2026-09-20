import 'package:latlong2/latlong.dart';
import 'walkway_type.dart';

/// Tipo de entrada o acceso al edificio.
enum EntranceType {
  /// Entrada principal visible y de mayor flujo.
  main,

  /// Entrada secundaria o lateral.
  secondary,

  /// Acceso orientado a plazas o explanadas (ej. Plaza de los Martires).
  plaza,

  /// Acceso directo por pasillo techado o breezeway interfacultades.
  corridor,

  /// Acceso inmediato desde area de estacionamiento.
  parking,

  /// Acceso mixto peatonal / garita vehicular.
  vehicularPedestrian,
}

/// Representa una puerta, entrada o salida oficial de un edificio en el campus.
class BuildingEntrance {
  /// Identificador unico de la entrada (ej. 't3-oriente', 'biblio-norte').
  final String id;

  /// Nombre legible de la entrada (ej. 'Puerta Oriente (Plaza de los Martires)').
  final String name;

  /// Coordenadas exactas de la puerta o umbral de acceso.
  final LatLng location;

  /// Tipo de acceso.
  final EntranceType type;

  /// Indica si la entrada cuenta con accesibilidad universal (rampa / sin barreras).
  final bool isAccessible;

  /// Tipo de via con la que conecta directamente la entrada.
  final WalkwayType connectedWalkwayType;

  const BuildingEntrance({
    required this.id,
    required this.name,
    required this.location,
    this.type = EntranceType.main,
    this.isAccessible = true,
    this.connectedWalkwayType = WalkwayType.pathway,
  });

  @override
  String toString() => 'BuildingEntrance($name at $location)';
}
