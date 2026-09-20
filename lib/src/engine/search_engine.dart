import 'dart:math' as math;
import '../models/campus_building.dart';
import '../models/campus_poi.dart';
import 'campus_data_repository.dart';

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String? matchedAlias;
  final double score;
  final CampusBuilding? building;
  final CampusPoi? poi;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    this.matchedAlias,
    required this.score,
    this.building,
    this.poi,
  });
}

class SearchEngine {
  final CampusDataRepository repository;
  final Map<String, String> _sancarlistaAliases = {
    'el iglu': 'iglu',
    'iglu': 'iglu',
    'plaza de los martires': 'plaza-martires',
    'las banderas': 'plaza-martires',
    'plaza central': 'plaza-martires',
    't-3': 't-3',
    't3': 't-3',
    't-1': 't-1',
    't1': 't-1',
    's-12': 's-12',
    's12': 's-12',
    'efpem': 's-12',
    'el huerto': 'huerto',
    'huerto': 'huerto',
    'los cubos': 'cubos',
    'cubos': 'cubos',
    'cum': 't-3',
    'rectoria': 'rectoria',
    'csu': 'rectoria',
    'rye': 'registro',
    'registro': 'registro',
    'fiusac': 't-3',
    'farusac': 't-1',
    'fausac': 't-8',
    'derecho': 's-2',
    'economicas': 's-3',
    'caja central': 'caja-central',
    'estadio': 'estadio',
    'estadio revolucion': 'estadio',
    '5b': 't-3',
    'bac': 's-2',
  };

  SearchEngine({required this.repository});

  List<SearchResult> search(
    String query, {
    String? category,
    int limit = 25,
  }) {
    final cleanQuery = _normalize(query.trim());
    if (cleanQuery.isEmpty) {
      return _getAllItems(category: category, limit: limit);
    }

    final results = <SearchResult>[];

    final aliasTarget = _sancarlistaAliases[cleanQuery];
    if (aliasTarget != null) {
      final building = repository.buildingsById[aliasTarget];
      if (building != null && _matchesCategory(building.category, category)) {
        results.add(
          SearchResult(
            id: building.id,
            title: building.name,
            subtitle: '${building.code} • Edificio USAC',
            category: building.category,
            matchedAlias: query,
            score: 1.0,
            building: building,
          ),
        );
      }
    }

    for (final building in repository.buildings) {
      if (!_matchesCategory(building.category, category)) continue;
      if (results.any((r) => r.id == building.id)) continue;

      final score = _calculateBuildingMatchScore(building, cleanQuery);
      if (score > 0.45) {
        results.add(
          SearchResult(
            id: building.id,
            title: building.name,
            subtitle: '${building.code} • Edificio • ${building.floorsCount} niveles',
            category: building.category,
            score: score,
            building: building,
          ),
        );
      }
    }

    for (final poi in repository.allPois) {
      if (!_matchesCategory(poi.category, category)) continue;
      if (results.any((r) => r.id == poi.id)) continue;

      final score = _calculatePoiMatchScore(poi, cleanQuery);
      if (score > 0.45) {
        final parent = repository.buildingsById[poi.buildingId];
        final subtitle =
            'Nivel ${poi.floorLevel}${parent != null ? ' • ${parent.name}' : ''}';
        results.add(
          SearchResult(
            id: poi.id,
            title: poi.name,
            subtitle: subtitle,
            category: poi.category,
            score: score,
            poi: poi,
            building: parent,
          ),
        );
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  List<SearchResult> _getAllItems({String? category, int limit = 25}) {
    final list = <SearchResult>[];
    for (final b in repository.buildings) {
      if (_matchesCategory(b.category, category)) {
        list.add(
          SearchResult(
            id: b.id,
            title: b.name,
            subtitle: '${b.code} • ${b.floorsCount} niveles',
            category: b.category,
            score: 1.0,
            building: b,
          ),
        );
      }
      if (list.length >= limit) return list;
    }
    return list;
  }

  bool _matchesCategory(String itemCategory, String? filterCategory) {
    if (filterCategory == null || filterCategory.isEmpty) return true;
    return _normalize(itemCategory) == _normalize(filterCategory);
  }

  double _calculateBuildingMatchScore(CampusBuilding building, String query) {
    final cleanName = _normalize(building.name);
    final cleanCode = _normalize(building.code);
    final cleanId = _normalize(building.id);

    if (cleanCode == query || cleanId == query) return 1.0;
    if (cleanName == query) return 0.98;
    if (cleanName.startsWith(query) || cleanCode.startsWith(query)) return 0.90;
    if (cleanName.contains(query)) return 0.82;

    final codeSimilarity = _similarity(cleanCode, query);
    final idSimilarity = _similarity(cleanId, query);
    final nameSimilarity = _wordSimilarity(cleanName, query);

    return math.max(
      codeSimilarity,
      math.max(idSimilarity, nameSimilarity),
    );
  }

  double _calculatePoiMatchScore(CampusPoi poi, String query) {
    final cleanName = _normalize(poi.name);
    final cleanCode = _normalize(poi.code);

    if (cleanCode == query) return 1.0;
    if (cleanName == query) return 0.98;

    for (final alias in poi.aliases) {
      final cleanAlias = _normalize(alias);
      if (cleanAlias == query) return 0.96;
      if (cleanAlias.contains(query)) return 0.85;
      final sim = _similarity(cleanAlias, query);
      if (sim > 0.75) return sim * 0.9;
    }

    if (cleanName.startsWith(query)) return 0.88;
    if (cleanName.contains(query)) return 0.80;

    return _wordSimilarity(cleanName, query);
  }

  double _wordSimilarity(String text, String query) {
    final words = text.split(' ');
    double maxScore = 0.0;
    for (final word in words) {
      final sim = _similarity(word, query);
      if (sim > maxScore) {
        maxScore = sim;
      }
    }
    return maxScore;
  }

  double _similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final dist = levenshteinDistance(s1, s2);
    final maxLen = math.max(s1.length, s2.length);
    return 1.0 - (dist / maxLen);
  }

  static int levenshteinDistance(String a, String b) {
    final m = a.length;
    final n = b.length;

    List<int> prev = List<int>.generate(n + 1, (i) => i);
    List<int> curr = List<int>.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      final aChar = a.codeUnitAt(i - 1);
      for (int j = 1; j <= n; j++) {
        final bChar = b.codeUnitAt(j - 1);
        final cost = (aChar == bChar) ? 0 : 1;
        curr[j] = math.min(
          curr[j - 1] + 1,
          math.min(
            prev[j] + 1,
            prev[j - 1] + 1 * cost,
          ),
        );
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[n];
  }

  static String _normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[ñ]'), 'n');
    return s;
  }
}
