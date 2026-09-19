import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('BuildingDetailModal', () {
    const testBuilding = CampusBuilding(
      id: 'T-3',
      name: 'Facultad de Ingenieria',
      location: LatLng(14.587794, -90.553240),
      description: 'Edificio central de FIUSAC con aulas y laboratorios.',
      acronym: 'T-3',
      category: BuildingCategory.faculty,
      floors: 4,
    );

    testWidgets('renders building details correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BuildingDetailModal(building: testBuilding),
          ),
        ),
      );

      expect(find.text('Facultad de Ingenieria'), findsOneWidget);
      expect(find.text('T-3'), findsOneWidget);
      expect(find.text('Facultades y Escuelas'), findsOneWidget);
      expect(find.text('Edificio central de FIUSAC con aulas y laboratorios.'), findsOneWidget);
      expect(find.text('Niveles: 4'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    });

    testWidgets('can be opened using static show method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BuildingDetailModal.show(
                  context: context,
                  building: testBuilding,
                ),
                child: const Text('Abrir modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir modal'));
      await tester.pumpAndSettle();

      expect(find.text('Facultad de Ingenieria'), findsOneWidget);
      expect(find.byType(BuildingDetailModal), findsOneWidget);
    });

    testWidgets('shows "En este edificio" when user reference position is very close', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BuildingDetailModal(
              building: testBuilding,
              referencePosition: LatLng(14.587794, -90.553240),
            ),
          ),
        ),
      );

      expect(find.text('En este edificio (< 1 min a pie)'), findsOneWidget);
    });

    testWidgets('shows distance and walking time when user reference position is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BuildingDetailModal(
              building: testBuilding,
              referencePosition: LatLng(14.588146, -90.551704), // ~170m
            ),
          ),
        ),
      );

      expect(find.textContaining('Distancia actual:'), findsOneWidget);
      expect(find.textContaining('a pie'), findsOneWidget);
    });

    testWidgets('shows warning message when reference position is outside campus', (tester) async {
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingDetailModal(
              building: testBuilding,
              referencePosition: const LatLng(14.620000, -90.510000),
              onNavigate: () => navigated = true,
            ),
          ),
        ),
      );

      expect(
        find.text('Tu ubicacion actual se encuentra fuera del Campus Central'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cómo llegar / Trazar Ruta'));
      await tester.pump();

      expect(navigated, isFalse);
      expect(
        find.text('Debes estar dentro del Campus Central para trazar una ruta a pie.'),
        findsOneWidget,
      );
    });
  });
}
