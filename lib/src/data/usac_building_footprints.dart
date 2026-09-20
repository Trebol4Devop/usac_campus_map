import 'package:latlong2/latlong.dart';

class UsacBuildingFootprints {
  static List<LatLng> _generateRectangularFootprint(
      LatLng center, double widthMeters, double heightMeters) {
    // Aproximacion: 1 grado de latitud son ~111,320 metros
    // 1 grado de longitud en el ecuador es ~111,320 metros, pero ajustamos por el coseno de la latitud.
    // Usac esta a latitud ~14.58. cos(14.58) = ~0.967
    const double latToMeters = 111320.0;
    const double lngToMeters = 111320.0 * 0.967;

    final double halfWidthLat = (heightMeters / 2) / latToMeters;
    final double halfWidthLng = (widthMeters / 2) / lngToMeters;

    final List<LatLng> basePoints = [
      LatLng(center.latitude + halfWidthLat, center.longitude - halfWidthLng),
      LatLng(center.latitude + halfWidthLat, center.longitude + halfWidthLng),
      LatLng(center.latitude - halfWidthLat, center.longitude + halfWidthLng),
      LatLng(center.latitude - halfWidthLat, center.longitude - halfWidthLng),
    ];

    // Aqui se podria aplicar rotacion si fuera necesario, para simplificar
    // usaremos los rectangulos orientados N-S / E-W por ahora.
    return basePoints;
  }

  // T-3: Edificio de Ingenieria
  static List<LatLng> get t3 => _generateRectangularFootprint(
        const LatLng(14.587794, -90.553240),
        60.0,
        30.0,
      );

  // S-2: Ciencias Juridicas
  static List<LatLng> get s2 => _generateRectangularFootprint(
        const LatLng(14.587044, -90.550059),
        50.0,
        25.0,
      );

  // Rectoria
  static List<LatLng> get rectoria => _generateRectangularFootprint(
        const LatLng(14.588146, -90.551704),
        40.0,
        40.0,
      );

  // Biblioteca Central
  static List<LatLng> get biblioteca => _generateRectangularFootprint(
        const LatLng(14.586838, -90.551859),
        50.0,
        60.0,
      );

  // Estadio Revolucion
  static List<LatLng> get estadio => _generateRectangularFootprint(
        const LatLng(14.586582, -90.547836),
        105.0, // Largo de cancha
        68.0, // Ancho de cancha
      );
}
