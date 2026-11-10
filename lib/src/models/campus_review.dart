import 'rating_classification.dart';

/// Resumen precomputado de calificaciones para un edificio, aula, o POI/sanitario.
class CampusRatingAggregate {
  final String targetId;
  final double averageRating;
  final int totalReviews;
  final String? classificationCode;
  final Map<String, int> tagsSummary;

  const CampusRatingAggregate({
    required this.targetId,
    required this.averageRating,
    required this.totalReviews,
    this.classificationCode,
    this.tagsSummary = const {},
  });

  /// Alias de compatibilidad
  String? get bathroomClass => classificationCode;

  /// Resuelve el nivel o tier según la configuración de clasificación dada.
  RatingTierItem? resolveTier(RatingClassificationConfig config) {
    if (totalReviews == 0) return null;
    return config.resolveTier(averageRating);
  }

  factory CampusRatingAggregate.fromJson(Map<String, dynamic> json) {
    return CampusRatingAggregate(
      targetId: json['target_id'] as String? ?? '',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      classificationCode: json['classification_code'] as String? ??
          json['bathroom_class'] as String?,
      tagsSummary: (json['tags_summary'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_id': targetId,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'classification_code': classificationCode,
      'tags_summary': tagsSummary,
    };
  }

  CampusRatingAggregate copyWith({
    String? targetId,
    double? averageRating,
    int? totalReviews,
    String? classificationCode,
    Map<String, int>? tagsSummary,
  }) {
    return CampusRatingAggregate(
      targetId: targetId ?? this.targetId,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      classificationCode: classificationCode ?? this.classificationCode,
      tagsSummary: tagsSummary ?? this.tagsSummary,
    );
  }
}

/// Reseña o calificación enviada por un estudiante (con pseudónimo protegido).
class CampusReview {
  final String id;
  final String targetId;
  final String targetType; // 'building' o 'poi'
  final String targetCategory;
  final String userId;
  final String authorAlias;
  final String? authorCarrera;
  final bool authorIsVerified;
  final bool isMyReview;
  final int rating;
  final String? classificationTier;
  final String? comment;
  final Map<String, bool> tags;
  final int likesCount;
  final DateTime createdAt;

  const CampusReview({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.targetCategory,
    required this.userId,
    required this.authorAlias,
    this.authorCarrera,
    this.authorIsVerified = false,
    this.isMyReview = false,
    required this.rating,
    this.classificationTier,
    this.comment,
    this.tags = const {},
    this.likesCount = 0,
    required this.createdAt,
  });

  /// Alias de compatibilidad
  String? get bathroomTier => classificationTier;

  factory CampusReview.fromJson(Map<String, dynamic> json) {
    return CampusReview(
      id: json['id'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      targetType: json['target_type'] as String? ?? 'poi',
      targetCategory: json['target_category'] as String? ?? 'general',
      userId: json['user_id'] as String? ?? '',
      authorAlias: json['author_alias'] as String? ?? 'Estudiante USAC',
      authorCarrera: json['author_carrera'] as String?,
      authorIsVerified: json['author_is_verified'] as bool? ?? false,
      isMyReview: json['is_my_review'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      classificationTier: json['classification_tier'] as String? ??
          json['bathroom_tier'] as String?,
      comment: json['comment'] as String?,
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {},
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_id': targetId,
      'target_type': targetType,
      'target_category': targetCategory,
      'user_id': userId,
      'author_alias': authorAlias,
      'author_carrera': authorCarrera,
      'author_is_verified': authorIsVerified,
      'is_my_review': isMyReview,
      'rating': rating,
      'classification_tier': classificationTier,
      'comment': comment,
      'tags': tags,
      'likes_count': likesCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CampusReview copyWith({
    String? id,
    String? targetId,
    String? targetType,
    String? targetCategory,
    String? userId,
    String? authorAlias,
    String? authorCarrera,
    bool? authorIsVerified,
    bool? isMyReview,
    int? rating,
    String? classificationTier,
    String? comment,
    Map<String, bool>? tags,
    int? likesCount,
    DateTime? createdAt,
  }) {
    return CampusReview(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      targetCategory: targetCategory ?? this.targetCategory,
      userId: userId ?? this.userId,
      authorAlias: authorAlias ?? this.authorAlias,
      authorCarrera: authorCarrera ?? this.authorCarrera,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      isMyReview: isMyReview ?? this.isMyReview,
      rating: rating ?? this.rating,
      classificationTier: classificationTier ?? this.classificationTier,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
