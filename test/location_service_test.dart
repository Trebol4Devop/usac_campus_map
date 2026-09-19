import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('CampusLocationService', () {
    test('instantiates service and provides position stream', () {
      final service = CampusLocationService();
      expect(service, isNotNull);
      expect(service.studentPositionStream, isA<Stream>());
    });

    test('getCurrentPosition returns a Future', () {
      final service = CampusLocationService();
      final future = service.getCurrentPosition();
      expect(future, isA<Future>());
    });

    test('isLocationServiceEnabled returns a Future<bool>', () {
      final service = CampusLocationService();
      final future = service.isLocationServiceEnabled();
      expect(future, isA<Future<bool>>());
    });
  });
}
