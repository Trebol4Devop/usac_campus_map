import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UsacCampusBoundary {
  static const List<LatLng> campusPerimeter = [
    LatLng(14.579094, -90.559290),
    LatLng(14.578455, -90.559031),
    LatLng(14.578292, -90.558965),
    LatLng(14.577780, -90.558525),
    LatLng(14.577725, -90.558477),
    LatLng(14.577700, -90.558400),
    LatLng(14.577561, -90.557964),
    LatLng(14.577243, -90.556826),
    LatLng(14.576996, -90.555943),
    LatLng(14.576922, -90.555680),
    LatLng(14.577004, -90.555658),
    LatLng(14.577393, -90.555554),
    LatLng(14.577472, -90.555533),
    LatLng(14.578278, -90.555333),
    LatLng(14.578830, -90.554909),
    LatLng(14.579799, -90.554364),
    LatLng(14.581005, -90.553951),
    LatLng(14.581117, -90.554069),
    LatLng(14.581514, -90.554010),
    LatLng(14.581549, -90.554005),
    LatLng(14.581535, -90.553912),
    LatLng(14.581760, -90.553874),
    LatLng(14.581791, -90.553569),
    LatLng(14.581757, -90.553154),
    LatLng(14.581743, -90.552988),
    LatLng(14.582432, -90.552915),
    LatLng(14.582941, -90.552865),
    LatLng(14.583220, -90.552838),
    LatLng(14.583098, -90.551800),
    LatLng(14.585622, -90.551445),
    LatLng(14.585320, -90.549150),
    LatLng(14.585489, -90.549011),
    LatLng(14.585266, -90.547395),
    LatLng(14.585707, -90.547313),
    LatLng(14.586966, -90.547079),
    LatLng(14.586771, -90.545583),
    LatLng(14.588084, -90.545404),
    LatLng(14.588282, -90.545378),
    LatLng(14.588516, -90.545344),
    LatLng(14.588619, -90.545329),
    LatLng(14.588896, -90.547399),
    LatLng(14.589400, -90.551164),
    LatLng(14.589509, -90.551251),
    LatLng(14.589768, -90.551224),
    LatLng(14.589774, -90.551277),
    LatLng(14.589777, -90.551313),
    LatLng(14.589793, -90.551437),
    LatLng(14.589804, -90.551529),
    LatLng(14.589811, -90.551602),
    LatLng(14.589502, -90.551639),
    LatLng(14.589465, -90.551701),
    LatLng(14.589533, -90.552170),
    LatLng(14.589691, -90.553380),
    LatLng(14.589567, -90.553662),
    LatLng(14.589384, -90.553818),
    LatLng(14.589184, -90.553990),
    LatLng(14.588038, -90.554305),
    LatLng(14.587371, -90.554511),
    LatLng(14.586678, -90.554725),
    LatLng(14.585805, -90.554981),
    LatLng(14.585538, -90.556261),
    LatLng(14.585255, -90.556768),
    LatLng(14.584559, -90.557768),
    LatLng(14.584095, -90.558503),
    LatLng(14.583757, -90.558058),
    LatLng(14.583178, -90.558570),
    LatLng(14.583023, -90.558146),
    LatLng(14.581935, -90.558431),
    LatLng(14.581990, -90.559064),
    LatLng(14.581754, -90.559083),
    LatLng(14.581030, -90.559144),
    LatLng(14.580086, -90.559274),
    LatLng(14.579094, -90.559290),
  ];

  static bool isInsideCampus(LatLng point) {
    bool inside = false;
    final nvert = campusPerimeter.length;
    int j = nvert - 1;

    for (int i = 0; i < nvert; i++) {
      final xi = campusPerimeter[i].latitude;
      final yi = campusPerimeter[i].longitude;
      final xj = campusPerimeter[j].latitude;
      final yj = campusPerimeter[j].longitude;

      final intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  static Polygon get defaultPerimeterPolygon {
    return Polygon(
      points: campusPerimeter,
      color: const Color(0x18002B49),
      borderColor: const Color(0xFF002B49),
      borderStrokeWidth: 2.5,
    );
  }

  static Polygon createCampusCutoutMask({
    Color color = Colors.white,
    Color borderColor = const Color(0xFF002B49),
    double borderStrokeWidth = 2.5,
  }) {
    return Polygon(
      points: const [
        LatLng(85.0, -180.0),
        LatLng(85.0, 180.0),
        LatLng(-85.0, 180.0),
        LatLng(-85.0, -180.0),
      ],
      holePointsList: [campusPerimeter],
      color: color,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      disableHolesBorder: false,
    );
  }

  static LatLngBounds get exactCampusBounds {
    return LatLngBounds(
      const LatLng(14.5760, -90.5605),
      const LatLng(14.5905, -90.5445),
    );
  }

  static LatLngBounds get defaultCameraBounds {
    return LatLngBounds(
      const LatLng(14.5760, -90.5605),
      const LatLng(14.5905, -90.5445),
    );
  }
}
