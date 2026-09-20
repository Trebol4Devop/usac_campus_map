import 'package:flutter/material.dart';

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

  IconData get icon {
    switch (this) {
      case BuildingCategory.faculty:
        return Icons.school_outlined;
      case BuildingCategory.administrative:
        return Icons.account_balance_outlined;
      case BuildingCategory.library:
        return Icons.local_library_outlined;
      case BuildingCategory.sports:
        return Icons.fitness_center_outlined;
      case BuildingCategory.food:
        return Icons.restaurant_outlined;
      case BuildingCategory.parking:
        return Icons.local_parking_outlined;
      case BuildingCategory.access:
        return Icons.door_sliding_outlined;
      case BuildingCategory.health:
        return Icons.medical_services_outlined;
      case BuildingCategory.generalAcademic:
        return Icons.cast_for_education_outlined;
    }
  }

  Color get color {
    switch (this) {
      case BuildingCategory.faculty:
        return const Color(0xFF1E3A8A);
      case BuildingCategory.administrative:
        return const Color(0xFF0F766E);
      case BuildingCategory.library:
        return const Color(0xFFB45309);
      case BuildingCategory.sports:
        return const Color(0xFF15803D);
      case BuildingCategory.food:
        return const Color(0xFFC2410C);
      case BuildingCategory.parking:
        return const Color(0xFF475569);
      case BuildingCategory.access:
        return const Color(0xFF78350F);
      case BuildingCategory.health:
        return const Color(0xFFDC2626);
      case BuildingCategory.generalAcademic:
        return const Color(0xFF6D28D9);
    }
  }
}
