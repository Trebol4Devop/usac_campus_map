import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('CategoryFilterChips', () {
    testWidgets('renders all category chips plus default all option', (tester) async {
      tester.view.physicalSize = const Size(2000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryFilterChips(),
          ),
        ),
      );

      expect(find.text('Todos'), findsOneWidget);
      for (final cat in BuildingCategory.values) {
        expect(find.text(cat.label), findsOneWidget);
      }
    });

    testWidgets('triggers onCategorySelected in single select mode', (tester) async {
      tester.view.physicalSize = const Size(2000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      BuildingCategory? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryFilterChips(
              onCategorySelected: (cat) => selected = cat,
            ),
          ),
        ),
      );

      await tester.tap(find.text(BuildingCategory.faculty.label));
      await tester.pump();

      expect(selected, equals(BuildingCategory.faculty));

      await tester.tap(find.text('Todos'));
      await tester.pump();

      expect(selected, isNull);
    });

    testWidgets('triggers onCategoriesChanged in multi select mode', (tester) async {
      tester.view.physicalSize = const Size(2000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Set<BuildingCategory> selectedSet = {};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryFilterChips(
              isMultiSelect: true,
              selectedCategories: selectedSet,
              onCategoriesChanged: (set) => selectedSet = set,
            ),
          ),
        ),
      );

      await tester.tap(find.text(BuildingCategory.sports.label));
      await tester.pump();

      expect(selectedSet, contains(BuildingCategory.sports));
    });
  });
}
