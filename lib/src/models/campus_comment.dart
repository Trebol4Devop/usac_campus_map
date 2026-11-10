/// Comentario en el foro de debate del lugar / campus.
class CampusComment {
  final String id;
  final String targetId;
  final String userId;
  final String authorAlias;
  final String content;
  final String? parentId;
  final int moderationStatus;
  final bool isDeleted;
  final int likesCount;
  final DateTime createdAt;
  final List<CampusComment> replies;

  const CampusComment({
    required this.id,
    required this.targetId,
    required this.userId,
    required this.authorAlias,
    required this.content,
    this.parentId,
    this.moderationStatus = 1,
    this.isDeleted = false,
    this.likesCount = 0,
    required this.createdAt,
    this.replies = const [],
  });

  /// Si fue eliminado, se renderiza el texto de tumba según la guía
  String get displayContent {
    if (isDeleted) {
      return 'Este comentario ha sido retirado por infringir las normas de convivencia.';
    }
    return content;
  }

  factory CampusComment.fromJson(Map<String, dynamic> json) {
    return CampusComment(
      id: json['id'] as String? ?? '',
      targetId: json['target_id'] as String? ?? json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      authorAlias: json['author_alias'] as String? ?? 'Estudiante USAC',
      content: json['content'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      moderationStatus: (json['moderation_status'] as num?)?.toInt() ?? 1,
      isDeleted: json['is_deleted'] as bool? ?? false,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => CampusComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_id': targetId,
      'user_id': userId,
      'author_alias': authorAlias,
      'content': content,
      'parent_id': parentId,
      'moderation_status': moderationStatus,
      'is_deleted': isDeleted,
      'likes_count': likesCount,
      'created_at': createdAt.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  CampusComment copyWith({
    String? id,
    String? targetId,
    String? userId,
    String? authorAlias,
    String? content,
    String? parentId,
    int? moderationStatus,
    bool? isDeleted,
    int? likesCount,
    DateTime? createdAt,
    List<CampusComment>? replies,
  }) {
    return CampusComment(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      userId: userId ?? this.userId,
      authorAlias: authorAlias ?? this.authorAlias,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }
}
