import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('CampusSearchService', () {
    final searchService = CampusSearchService();

    test('returns all buildings when query is empty', () {
      final results = searchService.search(query: '');
      expect(results.length, equals(UsacCampusDataset.allBuildings.length));
    });

    test('matches buildings by acronym with or without hyphens and case', () {
      final r1 = searchService.search(query: 'T-3');
      expect(r1.any((b) => b.id == 't-3'), isTrue);

      final r2 = searchService.search(query: 't3');
      expect(r2.any((b) => b.id == 't-3'), isTrue);

      final r3 = searchService.search(query: 's12');
      expect(r3.any((b) => b.id == 's-12'), isTrue);
    });

    test('matches buildings ignoring accents and case', () {
      final r1 = searchService.search(query: 'ingenieria');
      expect(r1.any((b) => b.id == 't-3'), isTrue);

      final r2 = searchService.search(query: 'odontologia');
      expect(r2.any((b) => b.id == 'm-1'), isTrue);

      final r3 = searchService.search(query: 'rectoria');
      expect(r3.any((b) => b.id == 'rectoria'), isTrue);
    });

    test('filters by category correctly', () {
      final faculties = searchService.filterByCategory(
        UsacCampusDataset.allBuildings,
        BuildingCategory.faculty,
      );
      expect(faculties.every((b) => b.category == BuildingCategory.faculty), isTrue);

      final libraries = searchService.filterByCategory(
        UsacCampusDataset.allBuildings,
        BuildingCategory.library,
      );
      expect(libraries.any((b) => b.id == 'biblio-central'), isTrue);
    });

    test('filters by multiple categories correctly', () {
      final filtered = searchService.filterByCategories(
        UsacCampusDataset.allBuildings,
        {BuildingCategory.administrative, BuildingCategory.health},
      );
      expect(
        filtered.every((b) =>
            b.category == BuildingCategory.administrative ||
            b.category == BuildingCategory.health),
        isTrue,
      );
    });
  });
}
