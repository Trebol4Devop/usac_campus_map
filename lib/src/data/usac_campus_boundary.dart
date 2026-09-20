import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UsacCampusBoundary {
  static const List<LatLng> campusPerimeter = [
    // --- SUR Y SUR-PONIENTE: CEDA, campos experimentales y viveros (La Parte Baja) ---
    LatLng(14.5769223, -90.5556800),
    LatLng(14.5769960, -90.5559434),
    LatLng(14.5772428, -90.5568259),
    LatLng(14.5775611, -90.5579639),
    LatLng(14.5777004, -90.5584002),
    LatLng(14.5777249, -90.5584770),
    LatLng(14.5777801, -90.5585246),
    LatLng(14.5782915, -90.5589649),
    LatLng(14.5784553, -90.5590313),
    LatLng(14.5790942, -90.5592901),
    LatLng(14.5800857, -90.5592738),
    LatLng(14.5810300, -90.5591437),
    LatLng(14.5817536, -90.5590833),
    LatLng(14.5819896, -90.5590636),
    LatLng(14.5819351, -90.5584306),
    LatLng(14.5830228, -90.5581462),
    LatLng(14.5831785, -90.5585700),
    LatLng(14.5837574, -90.5580577),
    LatLng(14.5840948, -90.5585030),
    LatLng(14.5845590, -90.5577685),
    LatLng(14.5852551, -90.5567676),
    LatLng(14.5855381, -90.5562607),

    // --- PONIENTE: Contorno oficial del Bosque de las Ardillas (OSM way 835932332) ---
    LatLng(14.5855876, -90.5560884),
    LatLng(14.5855924, -90.5562042),
    LatLng(14.5856902, -90.5562338),
    LatLng(14.5861816, -90.5560539),
    LatLng(14.5862794, -90.5560194),
    LatLng(14.5865561, -90.5560194),
    LatLng(14.5866133, -90.5559430),
    LatLng(14.5866634, -90.5557803),
    LatLng(14.5869473, -90.5554648),
    LatLng(14.5871787, -90.5553859),
    LatLng(14.5873051, -90.5553292),
    LatLng(14.5876295, -90.5552824),
    LatLng(14.5877536, -90.5552873),
    LatLng(14.5878776, -90.5552553),
    LatLng(14.5879492, -90.5552134),
    LatLng(14.5879870, -90.5551829),
    LatLng(14.5880684, -90.5551172),
    LatLng(14.5881376, -90.5549743),
    LatLng(14.5883117, -90.5549496),
    LatLng(14.5884095, -90.5549398),
    LatLng(14.5885861, -90.5549028),
    LatLng(14.5887530, -90.5548091),
    LatLng(14.5888461, -90.5547278),
    LatLng(14.5890011, -90.5546810),
    LatLng(14.5891609, -90.5546958),
    LatLng(14.5894090, -90.5547771),
    LatLng(14.5896142, -90.5547278),
    LatLng(14.5897310, -90.5546095),
    LatLng(14.5898050, -90.5543605),
    LatLng(14.5896913, -90.5533800),

    // --- NORTE: Muro perimetral norte colindante con colonias aledañas ---
    LatLng(14.5895329, -90.5521703),
    LatLng(14.5894654, -90.5517009),
    LatLng(14.5895018, -90.5516392),
    LatLng(14.5898107, -90.5516016),
    LatLng(14.5898038, -90.5515289),
    LatLng(14.5897927, -90.5514372),
    LatLng(14.5897769, -90.5513130),
    LatLng(14.5897735, -90.5512771),
    LatLng(14.5897678, -90.5512235),
    LatLng(14.5895089, -90.5512510),
    LatLng(14.5894005, -90.5511644),

    // --- ORIENTE: Garita Petapa y muro perimetral interno (excluye Avenida Petapa) ---
    LatLng(14.5888963, -90.5473989),
    LatLng(14.5886192, -90.5453293),
    LatLng(14.5885165, -90.5453439),
    LatLng(14.5882824, -90.5453783),
    LatLng(14.5880845, -90.5454044),

    // --- ORIENTE: Escuela de Aplicación Dr. Carlos Martínez Durán (OSM way 344549815) ---
    LatLng(14.5867711, -90.5455828),
    LatLng(14.5864689, -90.5456274),
    LatLng(14.5857576, -90.5457416),
    LatLng(14.5850578, -90.5458476),
    LatLng(14.5852655, -90.5473946),

    // --- SUR-ORIENTE: Retorno interno bordeando CEDA, parcelas e invernaderos de Agronomía ---
    LatLng(14.5854888, -90.5490106),
    LatLng(14.5853200, -90.5491501),
    LatLng(14.5856224, -90.5514447),
    LatLng(14.5830980, -90.5518001),
    LatLng(14.5832197, -90.5528375),
    LatLng(14.5829410, -90.5528650),
    LatLng(14.5824315, -90.5529152),
    LatLng(14.5817430, -90.5529884),
    LatLng(14.5817567, -90.5531541),
    LatLng(14.5817911, -90.5535690),
    LatLng(14.5817597, -90.5538745),
    LatLng(14.5815347, -90.5539125),
    LatLng(14.5815493, -90.5540046),
    LatLng(14.5815145, -90.5540105),
    LatLng(14.5811174, -90.5540693),
    LatLng(14.5810051, -90.5539510),
    LatLng(14.5797988, -90.5543643),
    LatLng(14.5788305, -90.5549088),
    LatLng(14.5782776, -90.5553326),
    LatLng(14.5774718, -90.5555328),
    LatLng(14.5773928, -90.5555540),
    LatLng(14.5770042, -90.5556580),
  ];

  static bool isInsideCampus(LatLng point) {
    return isPointInPolygon(point, campusPerimeter);
  }

  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    final nvert = polygon.length;
    int j = nvert - 1;

    for (int i = 0; i < nvert; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

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
      color: const Color(0x10002B49),
      borderColor: const Color(0x30002B49),
      borderStrokeWidth: 1.5,
    );
  }

  static Polygon createCampusCutoutMask({
    Color color = Colors.white,
    Color borderColor = Colors.transparent,
    double borderStrokeWidth = 0.0,
    bool disableHolesBorder = true,
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
      disableHolesBorder: disableHolesBorder,
    );
  }

  /// Creates a multi-layer soft ambient elevation drop-shadow along the
  /// campus perimeter. This replaces harsh solid border lines with an elegant,
  /// smooth visual transition between the interior university map and the
  /// surrounding background canvas.
  static List<Polyline> createCampusPerimeterShadowPolylines({
    Color shadowColor = const Color(0xFF001B30),
  }) {
    final closedPerimeter = [...campusPerimeter, campusPerimeter.first];
    return [
      // Wide soft ambient halo
      Polyline(
        points: closedPerimeter,
        strokeWidth: 16.0,
        color: shadowColor.withValues(alpha: 0.035),
      ),
      // Medium ambient shadow
      Polyline(
        points: closedPerimeter,
        strokeWidth: 10.0,
        color: shadowColor.withValues(alpha: 0.065),
      ),
      // Body shadow
      Polyline(
        points: closedPerimeter,
        strokeWidth: 5.5,
        color: shadowColor.withValues(alpha: 0.11),
      ),
      // Inner contact shadow
      Polyline(
        points: closedPerimeter,
        strokeWidth: 2.2,
        color: shadowColor.withValues(alpha: 0.16),
      ),
      // Crisp definition line
      Polyline(
        points: closedPerimeter,
        strokeWidth: 1.0,
        color: shadowColor.withValues(alpha: 0.22),
      ),
    ];
  }

  static LatLngBounds get exactCampusBounds {
    return LatLngBounds(
      const LatLng(14.5760, -90.5605),
      const LatLng(14.5908, -90.5445),
    );
  }

  static LatLngBounds get defaultCameraBounds {
    return LatLngBounds(
      const LatLng(14.5760, -90.5605),
      const LatLng(14.5908, -90.5445),
    );
  }
}
