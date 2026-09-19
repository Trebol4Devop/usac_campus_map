import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  testWidgets('UsacCampusMapExampleApp smoke test', (tester) async {
    await tester.pumpWidget(const UsacCampusMapExampleApp());
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Campus Central USAC'), findsOneWidget);
    expect(find.byType(CampusSearchBar), findsOneWidget);
    expect(find.byType(CategoryFilterChips), findsOneWidget);
    expect(find.byType(UsacCampusMap), findsOneWidget);
  });
}
