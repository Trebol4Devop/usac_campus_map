import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('CampusSearchBar', () {
    testWidgets('renders search input with default hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CampusSearchBar(),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar edificio, sigla o facultad...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('notifies text changes and shows clear button', (tester) async {
      String changedText = '';
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusSearchBar(
              onChanged: (value) => changedText = value,
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'T-3');
      await tester.pump();

      expect(changedText, equals('T-3'));
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(changedText, equals(''));
      expect(cleared, isTrue);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
