import 'campus_poi.dart';

class IndoorFloor {
  final int level;
  final String name;
  final List<CampusPoi> pois;

  const IndoorFloor({
    required this.level,
    required this.name,
    this.pois = const [],
  });

  factory IndoorFloor.fromJson(Map<String, dynamic> json, {String buildingId = ''}) {
    final rawPois = json['pois'] as List<dynamic>? ?? [];
    return IndoorFloor(
      level: (json['level'] as num).toInt(),
      name: json['name'] as String? ?? 'Nivel ${json['level']}',
      pois: rawPois
          .map((p) => CampusPoi.fromJson(p as Map<String, dynamic>, buildingId: buildingId))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'name': name,
    'pois': pois.map((p) => p.toJson()).toList(),
  };

  IndoorFloor copyWith({
    int? level,
    String? name,
    List<CampusPoi>? pois,
  }) {
    return IndoorFloor(
      level: level ?? this.level,
      name: name ?? this.name,
      pois: pois ?? this.pois,
    );
  }
}
