import 'package:latlong2/latlong.dart';

class CampusNode {
  final String id;
  final LatLng location;

  const CampusNode({
    required this.id,
    required this.location,
  });

  factory CampusNode.fromJson(Map<String, dynamic> json) {
    return CampusNode(
      id: json['id'] as String,
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': location.latitude,
    'lng': location.longitude,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
