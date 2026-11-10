import 'package:flutter/material.dart' hide NavigationMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const buildingA = CampusBuilding(
    id: 't-3',
    name: 'Edificio T-3',
    code: 'T-3',
    category: 'faculty',
    center: LatLng(14.5865, -90.5520),
    polygon: [
      LatLng(14.5864, -90.5521),
      LatLng(14.5866, -90.5521),
      LatLng(14.5866, -90.5519),
      LatLng(14.5864, -90.5519),
    ],
    floorsCount: 3,
  );

  const testPoi = CampusPoi(
    id: 'sanitario-t3-n1',
    buildingId: 't-3',
    name: 'Sanitarios Hombres Nivel 1',
    code: 'BAÑ-T3-1',
    category: 'sanitarios',
    floorLevel: 1,
    location: LatLng(14.5865, -90.5520),
  );

  group('UsacCampusMapController Heading State', () {
    test('Follows user heading state is configurable', () {
      final controller = UsacCampusMapController();
      expect(controller.followUserHeading, isFalse);

      controller.setFollowUserHeading(true);
      expect(controller.followUserHeading, isTrue);

      controller.dispose();
    });
  });

  group('RatingClassificationConfig & Custom Rating Classifications', () {
    test('Resolves default sanitarios classification correctly across thresholds', () {
      final config = RatingClassificationConfig.defaultSanitarios();

      final tier5 = config.resolveTier(4.8);
      expect(tier5?.code, equals('excelente'));
      expect(tier5?.label, equals('Excelente'));
      expect(tier5?.emoji, equals('✨'));

      final tier4 = config.resolveTier(4.0);
      expect(tier4?.code, equals('muy_bueno'));
      expect(tier4?.label, equals('Muy Bueno'));

      final tier3 = config.resolveTier(3.2);
      expect(tier3?.code, equals('aceptable'));

      final tier2 = config.resolveTier(2.5);
      expect(tier2?.code, equals('regular'));

      final tier1 = config.resolveTier(1.2);
      expect(tier1?.code, equals('deficiente'));
    });

    test('Allows registering completely custom classification tiers and tags', () {
      final repo = CampusCommunityRepository.isolated();

      // Cliente define un esquema para 'cafeterias'
      repo.registerClassification(
        const RatingClassificationConfig(
          category: 'cafeterias',
          title: 'Evaluación Gastronómica',
          tiers: [
            RatingTierItem(
              code: 'cinco_estrellas',
              label: 'Exquisito',
              emoji: '🍽️',
              colorHex: 0xFF10B981,
              description: 'Calidad sobresaliente y excelente higiene.',
              minRating: 4.5,
            ),
            RatingTierItem(
              code: 'buen_sabor',
              label: 'Recomendable',
              emoji: '🥪',
              colorHex: 0xFF3B82F6,
              description: 'Buen precio y sabor.',
              minRating: 3.0,
            ),
            RatingTierItem(
              code: 'basico',
              label: 'Económico',
              emoji: '🥤',
              colorHex: 0xFFF59E0B,
              description: 'Para salir de apuros.',
              minRating: 0.0,
            ),
          ],
          availableTags: ['fast_service', 'card_payment', 'cheap_combos'],
          tagLabels: {
            'fast_service': '⚡ Servicio Rápido',
            'card_payment': '💳 Acepta Tarjeta',
            'cheap_combos': '💰 Combos Económicos',
          },
        ),
      );

      final retrieved = repo.getClassification('cafeterias');
      expect(retrieved.title, equals('Evaluación Gastronómica'));
      expect(retrieved.resolveTier(4.8)?.label, equals('Exquisito'));
      expect(retrieved.resolveTier(4.8)?.emoji, equals('🍽️'));
      expect(retrieved.getTagLabel('fast_service'), equals('⚡ Servicio Rápido'));
    });
  });

  group('CampusCommunityRepository In-Memory Logic', () {
    late CampusCommunityRepository repo;

    setUp(() {
      repo = CampusCommunityRepository.isolated();
    });

    test('Retrieves initial mock aggregates and reviews for T-3 and Sanitarios',
        () {
      final t3Aggr = repo.getAggregate('t-3', category: 'faculty');
      expect(t3Aggr.totalReviews, greaterThanOrEqualTo(3));
      expect(t3Aggr.averageRating, greaterThanOrEqualTo(4.0));

      final sanAggr =
          repo.getAggregate('sanitario-t3-n1', category: 'sanitarios');
      expect(sanAggr.totalReviews, greaterThanOrEqualTo(2));
      expect(sanAggr.averageRating, greaterThanOrEqualTo(4.5));
      expect(sanAggr.classificationCode, equals('excelente'));
    });

    test('Submitting a review recalculates aggregate rating and tag summary',
        () {
      final newRev = repo.submitReview(
        targetId: 'sanitario-t3-n1',
        targetType: 'poi',
        targetCategory: 'sanitarios',
        rating: 5,
        comment: 'Excelente limpieza matutina',
        tags: const {
          'has_water': true,
          'has_paper': true,
          'has_soap': true,
          'door_locks': true,
          'is_clean': true,
        },
        authorAlias: 'IngQuimica2026',
      );

      expect(newRev.authorAlias, equals('IngQuimica2026'));
      expect(newRev.rating, equals(5));

      final updatedAggr =
          repo.getAggregate('sanitario-t3-n1', category: 'sanitarios');
      expect(updatedAggr.totalReviews, equals(3));
      expect(updatedAggr.tagsSummary['has_water'], equals(3));
    });

    test('Liking a review increments likes count', () {
      final reviews = repo.getReviews('t-3');
      final firstRev = reviews.first;
      final initialLikes = firstRev.likesCount;

      repo.toggleLikeReview('t-3', firstRev.id);
      final updatedReviews = repo.getReviews('t-3');
      expect(updatedReviews.first.likesCount, equals(initialLikes + 1));
    });

    test('Forum comments support nested replies and tombstone on deleted',
        () {
      final comments = repo.getComments('t-3');
      expect(comments.isNotEmpty, isTrue);

      // Verify tombstone display on deleted comment
      final deletedComment = comments.firstWhere((c) => c.isDeleted);
      expect(deletedComment.displayContent,
          contains('ha sido retirado por infringir las normas de convivencia'));
      expect(deletedComment.replies.isNotEmpty, isTrue);

      // Submit reply
      repo.submitComment(
        targetId: 't-3',
        content: 'Nueva respuesta al hilo',
        parentId: comments.first.id,
        authorAlias: 'SanCarlosTester',
      );

      final updated = repo.getComments('t-3');
      expect(
          updated.first.replies
              .any((r) => r.content == 'Nueva respuesta al hilo'),
          isTrue);
    });
  });

  group('Presentation Widgets (Reviews, Forum & PoiDetailSheet)', () {
    testWidgets('RatingClassificationBadge renders emoji and tags correctly',
        (tester) async {
      final config = RatingClassificationConfig.defaultSanitarios();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingClassificationBadge(
              averageRating: 4.8,
              config: config,
              tagsSummary: const {'has_water': 5, 'has_paper': 4},
            ),
          ),
        ),
      );

      expect(find.text('✨'), findsOneWidget);
      expect(find.text('Excelente'), findsOneWidget);
      expect(find.text('💧 Agua corriente (5)'), findsOneWidget);
      expect(find.text('🧻 Papel higiénico (4)'), findsOneWidget);
    });

    testWidgets('PoiDetailSheet displays tabs and allows switching to reviews and forum',
        (tester) async {
      final repo = CampusCommunityRepository.isolated();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiDetailSheet(
              building: buildingA,
              currentFloor: 1,
              communityRepository: repo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and tabs
      expect(find.text('Edificio T-3'), findsOneWidget);
      expect(find.text('Detalles'), findsOneWidget);
      expect(find.textContaining('Reseñas'), findsOneWidget);
      expect(find.textContaining('Foro'), findsOneWidget);

      // Switch to Reseñas tab
      await tester.tap(find.textContaining('Reseñas'));
      await tester.pumpAndSettle();

      expect(find.text('Calificar Edificio T-3'), findsOneWidget);
      expect(find.text('IngSistemas2025'), findsOneWidget);

      // Switch to Foro tab
      await tester.tap(find.textContaining('Foro'));
      await tester.pumpAndSettle();

      expect(find.text('Foro de Discusión en Tiempo Real'), findsOneWidget);
      expect(find.textContaining('laboratorio de redes'), findsOneWidget);
    });

    testWidgets('PoiDetailSheet renders classification badge when POI has classification',
        (tester) async {
      final repo = CampusCommunityRepository.isolated();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiDetailSheet(
              poi: testPoi,
              currentFloor: 1,
              communityRepository: repo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sanitarios Hombres Nivel 1'), findsOneWidget);
      expect(find.text('✨'), findsOneWidget);
      expect(find.text('Excelente'), findsOneWidget);
    });
  });
}
