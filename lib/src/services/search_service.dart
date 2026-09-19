import '../data/usac_campus_dataset.dart';
import '../models/building_category.dart';
import '../models/campus_building.dart';

class CampusSearchService {
  List<CampusBuilding> search({
    required String query,
    List<CampusBuilding>? buildings,
    BuildingCategory? category,
    Set<BuildingCategory>? categories,
  }) {
    var source = buildings ?? UsacCampusDataset.allBuildings;

    if (category != null) {
      source = source.where((b) => b.category == category).toList();
    } else if (categories != null && categories.isNotEmpty) {
      source = source.where((b) => categories.contains(b.category)).toList();
    }

    final cleanQuery = _normalize(query);
    if (cleanQuery.isEmpty) {
      return source;
    }

    final queryWords = cleanQuery.split(' ').where((w) => w.isNotEmpty).toList();
    final simplifiedQuery = cleanQuery.replaceAll(RegExp(r'[^a-z0-9]'), '');

    return source.where((building) {
      final nameNorm = _normalize(building.name);
      final descNorm = _normalize(building.description);
      final acronymNorm = building.acronym != null ? _normalize(building.acronym!) : '';
      final idNorm = _normalize(building.id);

      final combined = '$nameNorm $acronymNorm $descNorm $idNorm';

      if (queryWords.every((word) => combined.contains(word))) {
        return true;
      }

      if (simplifiedQuery.isNotEmpty) {
        final simplifiedAcronym = acronymNorm.replaceAll(RegExp(r'[^a-z0-9]'), '');
        final simplifiedId = idNorm.replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (simplifiedAcronym.contains(simplifiedQuery) ||
            simplifiedId.contains(simplifiedQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  List<CampusBuilding> filterByCategory(
    List<CampusBuilding> buildings,
    BuildingCategory category,
  ) {
    return buildings.where((b) => b.category == category).toList();
  }

  List<CampusBuilding> filterByCategories(
    List<CampusBuilding> buildings,
    Set<BuildingCategory> categories,
  ) {
    if (categories.isEmpty) {
      return buildings;
    }
    return buildings.where((b) => categories.contains(b.category)).toList();
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .trim();
  }
}
