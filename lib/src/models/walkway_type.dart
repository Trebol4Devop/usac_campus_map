/// Clasificacion de vias peatonales en el campus universitario de la USAC.
enum WalkwayType {
  /// Pasillo techado, breezeway o corredor cubierto entre modulos de edificios.
  corridor,

  /// Camino peatonal, plazoleta, sendero en jardines o andador exclusivo.
  pathway,

  /// Calle vehicular interna con banqueta o paso peatonal senalizado.
  street;

  /// Nombre descriptivo en espanol para la interfaz de usuario.
  String get label {
    switch (this) {
      case WalkwayType.corridor:
        return 'Pasillo techado';
      case WalkwayType.pathway:
        return 'Camino peatonal';
      case WalkwayType.street:
        return 'Calle con acera';
    }
  }

  /// Factor de costo para ponderacion de rutas a pie.
  /// Los estudiantes prefieren pasillos techados (protegidos de lluvia y sol)
  /// y caminos peatonales sobre calles vehiculares.
  double get preferenceCostFactor {
    switch (this) {
      case WalkwayType.corridor:
        return 1.0;
      case WalkwayType.pathway:
        return 1.0;
      case WalkwayType.street:
        return 1.25; // Ligera penalizacion para preferir caminos peatonales seguros
    }
  }
}
