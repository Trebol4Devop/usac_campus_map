import 'package:latlong2/latlong.dart';

class CampusPoi {
  final String id;
  final String buildingId;
  final String name;
  final String code;
  final int floorLevel;
  final String category;
  final List<String> aliases;
  final LatLng? location;

  const CampusPoi({
    required this.id,
    required this.buildingId,
    required this.name,
    required this.code,
    required this.floorLevel,
    required this.category,
    this.aliases = const [],
    this.location,
  });

  factory CampusPoi.fromJson(Map<String, dynamic> json, {String? buildingId}) {
    LatLng? loc;
    if (json.containsKey('lat') && json.containsKey('lng')) {
      loc = LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
    }
    return CampusPoi(
      id: json['id'] as String,
      buildingId: buildingId ?? (json['building_id'] as String? ?? ''),
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      floorLevel: (json['floor_level'] as num?)?.toInt() ?? 1,
      category: json['category'] as String? ?? 'general',
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      location: loc,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'building_id': buildingId,
    'name': name,
    'code': code,
    'floor_level': floorLevel,
    'category': category,
    'aliases': aliases,
    if (location != null) 'lat': location!.latitude,
    if (location != null) 'lng': location!.longitude,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusPoi && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
