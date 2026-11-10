import '../models/campus_comment.dart';
import '../models/campus_review.dart';
import '../models/rating_classification.dart';

/// Repositorio local en memoria para reseñas, calificaciones y foro comunitario.
/// Permite registrar esquemas de clasificación personalizados por categoría
/// (sanitarios, cafeterías, aulas, bibliotecas, etc.) sin depender de Supabase ni Cloudflare.
class CampusCommunityRepository {
  static final CampusCommunityRepository _singleton =
      CampusCommunityRepository._internal();
  factory CampusCommunityRepository() => _singleton;
  static CampusCommunityRepository get instance => _singleton;

  final Map<String, RatingClassificationConfig> _classifications = {};
  final Map<String, CampusRatingAggregate> _aggregates = {};
  final Map<String, List<CampusReview>> _reviewsByTarget = {};
  final Map<String, List<CampusComment>> _commentsByTarget = {};

  CampusCommunityRepository._internal() {
    _initDefaults();
    _seedMockData();
  }

  /// Constructor para tests o instancias aisladas
  CampusCommunityRepository.isolated() {
    _initDefaults();
    _seedMockData();
  }

  void _initDefaults() {
    registerClassification(RatingClassificationConfig.defaultSanitarios());
    registerClassification(RatingClassificationConfig.defaultGeneral());
  }

  /// Registra o sobrescribe una configuración de clasificación personalizada para una categoría.
  void registerClassification(RatingClassificationConfig config) {
    _classifications[config.category.toLowerCase()] = config;
  }

  /// Obtiene la configuración de clasificación para una categoría (o general por defecto).
  RatingClassificationConfig getClassification(String category) {
    final key = category.toLowerCase();
    if (_classifications.containsKey(key)) {
      return _classifications[key]!;
    }
    return _classifications['general'] ??
        RatingClassificationConfig.defaultGeneral();
  }

  void _seedMockData() {
    // 1. Edificio T-3 (Facultad de Ingeniería)
    final t3Reviews = [
      CampusReview(
        id: 'rev_t3_1',
        targetId: 't-3',
        targetType: 'building',
        targetCategory: 'faculty',
        userId: 'usr_mock_1',
        authorAlias: 'IngSistemas2025',
        authorCarrera: 'Ingeniería en Ciencias y Sistemas',
        authorIsVerified: true,
        rating: 5,
        comment:
            'Excelentes laboratorios de computación con aire acondicionado. Muy buena señal de WiFi en los pasillos.',
        tags: const {
          'has_wifi': true,
          'has_power_outlets': true,
          'good_lighting': true,
        },
        likesCount: 14,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      CampusReview(
        id: 'rev_t3_2',
        targetId: 't-3',
        targetType: 'building',
        targetCategory: 'faculty',
        userId: 'usr_mock_2',
        authorAlias: 'Civil_Fiusac',
        authorCarrera: 'Ingeniería Civil',
        authorIsVerified: true,
        rating: 4,
        comment:
            'Aulas amplias y buena iluminación. En horas pico las gradas se congestionan un poco.',
        tags: const {
          'good_lighting': true,
          'has_power_outlets': true,
        },
        likesCount: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      CampusReview(
        id: 'rev_t3_3',
        targetId: 't-3',
        targetType: 'building',
        targetCategory: 'faculty',
        userId: 'usr_mock_3',
        authorAlias: 'MecaSanCarlos',
        authorCarrera: 'Ingeniería Mecánica',
        authorIsVerified: false,
        rating: 5,
        comment:
            'Punto de encuentro icónico de la FIUSAC. Los bancos de afuera son ideales para estudiar en grupo.',
        likesCount: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];
    _reviewsByTarget['t-3'] = t3Reviews;
    _recalculateAggregate('t-3', 'faculty');

    // 2. Sanitarios T-3 Nivel 1 (Excelente ✨)
    final t3SanitariosReviews = [
      CampusReview(
        id: 'rev_san_t3_1',
        targetId: 'sanitario-t3-n1',
        targetType: 'poi',
        targetCategory: 'sanitarios',
        userId: 'usr_mock_4',
        authorAlias: 'QuimicaFiusac',
        authorCarrera: 'Ingeniería Química',
        authorIsVerified: true,
        rating: 5,
        classificationTier: 'excelente',
        comment:
            'Impecable. Siempre hay agua, dispensadores con jabón líquido, papel y espejos limpios.',
        tags: const {
          'has_water': true,
          'has_paper': true,
          'has_soap': true,
          'door_locks': true,
          'is_clean': true,
        },
        likesCount: 22,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CampusReview(
        id: 'rev_san_t3_2',
        targetId: 'sanitario-t3-n1',
        targetType: 'poi',
        targetCategory: 'sanitarios',
        userId: 'usr_mock_5',
        authorAlias: 'IndustrialUsac',
        authorCarrera: 'Ingeniería Industrial',
        authorIsVerified: true,
        rating: 5,
        classificationTier: 'excelente',
        comment: 'Muy limpio, seguro y con buen mantenimiento.',
        tags: const {
          'has_water': true,
          'has_paper': true,
          'has_soap': true,
          'door_locks': true,
          'is_clean': true,
        },
        likesCount: 16,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
    _reviewsByTarget['sanitario-t3-n1'] = t3SanitariosReviews;
    _recalculateAggregate('sanitario-t3-n1', 'sanitarios');

    // 3. Biblioteca Central
    final biblioReviews = [
      CampusReview(
        id: 'rev_biblio_1',
        targetId: 'biblio-central',
        targetType: 'building',
        targetCategory: 'library',
        userId: 'usr_mock_6',
        authorAlias: 'HumanidadesUSAC',
        authorCarrera: 'Facultad de Humanidades',
        authorIsVerified: true,
        rating: 4,
        comment:
            'Muy silencioso y con tomas de corriente en casi todas las mesas individuales.',
        tags: const {
          'quiet_area': true,
          'has_power_outlets': true,
          'has_wifi': true,
        },
        likesCount: 9,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    _reviewsByTarget['biblio-central'] = biblioReviews;
    _recalculateAggregate('biblio-central', 'library');

    // 4. Edificio S-12 Sanitarios (Regular ⚠️)
    final s12Sanitarios = [
      CampusReview(
        id: 'rev_san_s12_1',
        targetId: 'sanitario-s12',
        targetType: 'poi',
        targetCategory: 'sanitarios',
        userId: 'usr_mock_7',
        authorAlias: 'DerechoUsac',
        authorCarrera: 'Ciencias Jurídicas y Sociales',
        authorIsVerified: false,
        rating: 2,
        classificationTier: 'regular',
        comment:
            'Intermitencia en el agua y a veces sin jabón disponible. Requiere atención.',
        tags: const {
          'has_water': false,
          'has_paper': false,
          'has_soap': false,
          'door_locks': true,
          'is_clean': false,
        },
        likesCount: 19,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
    _reviewsByTarget['sanitario-s12'] = s12Sanitarios;
    _recalculateAggregate('sanitario-s12', 'sanitarios');

    // 5. Foro de debate y comentarios
    _commentsByTarget['t-3'] = [
      CampusComment(
        id: 'com_t3_1',
        targetId: 't-3',
        userId: 'usr_c1',
        authorAlias: 'Estudiante_Fiusac',
        content:
            '¿Alguien sabe si el laboratorio de redes en el 3er nivel estará abierto este fin de semana?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likesCount: 4,
        replies: [
          CampusComment(
            id: 'com_t3_1_rep1',
            targetId: 't-3',
            userId: 'usr_c2',
            authorAlias: 'AuxiliarRedes',
            content:
                'Sí, habrá auxiliatura de 9:00 a 13:00 hrs para entrega de prácticas.',
            parentId: 'com_t3_1',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            likesCount: 7,
          ),
        ],
      ),
      CampusComment(
        id: 'com_t3_2',
        targetId: 't-3',
        userId: 'usr_c3',
        authorAlias: 'Mod_Sistemas',
        content: '[Eliminado por moderación]',
        isDeleted: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        replies: [
          CampusComment(
            id: 'com_t3_2_rep1',
            targetId: 't-3',
            userId: 'usr_c4',
            authorAlias: 'SancarlistaCivil',
            content: 'Gracias al moderador por mantener limpio el hilo.',
            parentId: 'com_t3_2',
            createdAt: DateTime.now().subtract(const Duration(hours: 15)),
            likesCount: 3,
          ),
        ],
      ),
      CampusComment(
        id: 'com_t3_3',
        targetId: 't-3',
        userId: 'usr_c5',
        authorAlias: 'Electrica2024',
        content:
            'Dejé olvidada una libreta azul en el salón 214, si alguien la vio favor avisar.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likesCount: 1,
      ),
    ];

    _commentsByTarget['sanitario-t3-n1'] = [
      CampusComment(
        id: 'com_san_1',
        targetId: 'sanitario-t3-n1',
        userId: 'usr_s1',
        authorAlias: 'MecaSistemas',
        content:
            'Confirmado que hoy a las 11am pasaron limpiando y recargaron jabón.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 6,
      ),
    ];
  }

  /// Recalcula el agregado a partir de las reseñas registradas
  void _recalculateAggregate(String targetId, String category) {
    final reviews = _reviewsByTarget[targetId] ?? const [];
    final classification = getClassification(category);

    if (reviews.isEmpty) {
      _aggregates[targetId] = CampusRatingAggregate(
        targetId: targetId,
        averageRating: 0.0,
        totalReviews: 0,
        classificationCode: null,
        tagsSummary: const {},
      );
      return;
    }

    final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    final avg = double.parse((sum / reviews.length).toStringAsFixed(2));

    final tagsMap = <String, int>{};
    for (final r in reviews) {
      r.tags.forEach((k, v) {
        if (v) {
          tagsMap[k] = (tagsMap[k] ?? 0) + 1;
        }
      });
    }

    final tier = classification.resolveTier(avg);

    _aggregates[targetId] = CampusRatingAggregate(
      targetId: targetId,
      averageRating: avg,
      totalReviews: reviews.length,
      classificationCode: tier?.code,
      tagsSummary: tagsMap,
    );
  }

  /// Obtiene el agregado de calificaciones para un lugar o POI
  CampusRatingAggregate getAggregate(String targetId, {String? category}) {
    if (!_aggregates.containsKey(targetId)) {
      _recalculateAggregate(targetId, category ?? 'general');
    }
    return _aggregates[targetId]!;
  }

  /// Obtiene la lista de reseñas para un lugar o POI
  List<CampusReview> getReviews(String targetId) {
    return List.unmodifiable(_reviewsByTarget[targetId] ?? const []);
  }

  /// Envía o actualiza una reseña (simulación local)
  CampusReview submitReview({
    required String targetId,
    required String targetType,
    required String targetCategory,
    required int rating,
    String? comment,
    Map<String, bool>? tags,
    String authorAlias = 'Estudiante Sancarlista',
    String? authorCarrera,
    bool authorIsVerified = true,
  }) {
    final list = _reviewsByTarget.putIfAbsent(targetId, () => []);
    final existingIdx = list.indexWhere((r) => r.isMyReview);

    final classification = getClassification(targetCategory);
    final tier = classification.resolveTier(rating.toDouble());

    final newReview = CampusReview(
      id: existingIdx >= 0
          ? list[existingIdx].id
          : 'rev_${DateTime.now().millisecondsSinceEpoch}',
      targetId: targetId,
      targetType: targetType,
      targetCategory: targetCategory,
      userId: 'my_user_id',
      authorAlias: authorAlias,
      authorCarrera: authorCarrera ?? 'Facultad de Ingeniería',
      authorIsVerified: authorIsVerified,
      isMyReview: true,
      rating: rating.clamp(1, 5),
      classificationTier: tier?.code,
      comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      tags: tags ?? const {},
      likesCount: existingIdx >= 0 ? list[existingIdx].likesCount : 0,
      createdAt: DateTime.now(),
    );

    if (existingIdx >= 0) {
      list[existingIdx] = newReview;
    } else {
      list.insert(0, newReview);
    }

    _recalculateAggregate(targetId, targetCategory);
    return newReview;
  }

  /// Incrementa o decrementa el contador de utilidad de una reseña
  void toggleLikeReview(String targetId, String reviewId) {
    final list = _reviewsByTarget[targetId];
    if (list == null) return;
    final idx = list.indexWhere((r) => r.id == reviewId);
    if (idx >= 0) {
      final current = list[idx];
      list[idx] = current.copyWith(likesCount: current.likesCount + 1);
    }
  }

  /// Obtiene los comentarios del foro del lugar (árbol con respuestas)
  List<CampusComment> getComments(String targetId) {
    return List.unmodifiable(_commentsByTarget[targetId] ?? const []);
  }

  /// Publica un nuevo comentario o respuesta anidada
  CampusComment submitComment({
    required String targetId,
    required String content,
    String? parentId,
    String authorAlias = 'Estudiante USAC',
  }) {
    final list = _commentsByTarget.putIfAbsent(targetId, () => []);

    final newComment = CampusComment(
      id: 'com_${DateTime.now().millisecondsSinceEpoch}',
      targetId: targetId,
      userId: 'my_user_id',
      authorAlias: authorAlias,
      content: content.trim(),
      parentId: parentId,
      createdAt: DateTime.now(),
      likesCount: 0,
    );

    if (parentId != null) {
      final parentIdx = list.indexWhere((c) => c.id == parentId);
      if (parentIdx >= 0) {
        final parent = list[parentIdx];
        final updatedReplies = List<CampusComment>.from(parent.replies)
          ..add(newComment);
        list[parentIdx] = parent.copyWith(replies: updatedReplies);
        return newComment;
      }
    }

    list.insert(0, newComment);
    return newComment;
  }
}
