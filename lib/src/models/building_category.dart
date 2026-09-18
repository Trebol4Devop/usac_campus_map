enum BuildingCategory {
  faculty,
  administrative,
  library,
  sports,
  food,
  parking,
  access,
  health,
  generalAcademic;

  String get label {
    switch (this) {
      case BuildingCategory.faculty:
        return 'Facultades y Escuelas';
      case BuildingCategory.administrative:
        return 'Administracion';
      case BuildingCategory.library:
        return 'Bibliotecas';
      case BuildingCategory.sports:
        return 'Deportes y Recreacion';
      case BuildingCategory.food:
        return 'Alimentacion y Cafeterias';
      case BuildingCategory.parking:
        return 'Estacionamientos';
      case BuildingCategory.access:
        return 'Garitas y Accesos';
      case BuildingCategory.health:
        return 'Salud y Emergencias';
      case BuildingCategory.generalAcademic:
        return 'Academico General';
    }
  }
}
