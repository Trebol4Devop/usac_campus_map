import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('UsacCampusBoundary', () {
    test('verifies points inside campus return true', () {
      expect(UsacCampusBoundary.isInsideCampus(UsacCampusDataset.campusCenter), isTrue);
      expect(UsacCampusBoundary.isInsideCampus(const LatLng(14.588146, -90.551704)), isTrue);
      expect(UsacCampusBoundary.isInsideCampus(const LatLng(14.586838, -90.551859)), isTrue);
      expect(UsacCampusBoundary.isInsideCampus(const LatLng(14.587794, -90.553240)), isTrue);
    });

    test('verifies points outside campus return false', () {
      expect(UsacCampusBoundary.isInsideCampus(const LatLng(14.587883, -90.542938)), isFalse);
      expect(UsacCampusBoundary.isInsideCampus(const LatLng(14.600000, -90.550000)), isFalse);
      expect(UsacCampusBoundary.isInsideCampus(const LatLng(14.570000, -90.550000)), isFalse);
    });

    test('defaultCameraBounds properly contains campus perimeter', () {
      final bounds = UsacCampusBoundary.defaultCameraBounds;
      expect(bounds.southWest.latitude, lessThan(14.5770));
      expect(bounds.northEast.latitude, greaterThan(14.5900));
      expect(bounds.southWest.longitude, lessThan(-90.5600));
      expect(bounds.northEast.longitude, greaterThan(-90.5450));
    });
  });
}
