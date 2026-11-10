import 'package:flutter/material.dart';
import '../../engine/campus_community_repository.dart';
import '../../models/campus_review.dart';
import '../../models/rating_classification.dart';
import '../themes/usac_map_theme.dart';
import 'rating_classification_badge.dart';

/// Vista de reseñas y calificaciones con esquema de clasificación y tags personalizables.
class CommunityReviewsView extends StatefulWidget {
  final String targetId;
  final String targetName;
  final String targetType; // 'building' o 'poi'
  final String targetCategory;
  final UsacMapTheme theme;
  final CampusCommunityRepository? repository;
  final RatingClassificationConfig? classificationConfig;

  const CommunityReviewsView({
    super.key,
    required this.targetId,
    required this.targetName,
    this.targetType = 'building',
    this.targetCategory = 'general',
    this.theme = const UsacMapTheme(),
    this.repository,
    this.classificationConfig,
  });

  @override
  State<CommunityReviewsView> createState() => _CommunityReviewsViewState();
}

class _CommunityReviewsViewState extends State<CommunityReviewsView> {
  late CampusCommunityRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? CampusCommunityRepository.instance;
  }

  RatingClassificationConfig get _classification =>
      widget.classificationConfig ??
      _repo.getClassification(widget.targetCategory);

  void _openReviewModal() {
    int selectedRating = 5;
    final aliasController =
        TextEditingController(text: 'Sancarlista_${DateTime.now().millisecond}');
    final careerController =
        TextEditingController(text: 'Facultad de Ingeniería');
    final commentController = TextEditingController();

    final availableTags = _classification.availableTags;
    final tags = <String, bool>{
      for (final t in availableTags) t: true,
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
              ),
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.0,
                        height: 4.0,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    Text(
                      'Calificar ${widget.targetName}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    // Selector de estrellas
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return IconButton(
                            iconSize: 36.0,
                            icon: Icon(
                              star <= selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber.shade700,
                            ),
                            onPressed: () {
                              setModalState(() => selectedRating = star);
                            },
                          );
                        }),
                      ),
                    ),
                    if (availableTags.isNotEmpty) ...[
                      const SizedBox(height: 10.0),
                      Text(
                        _classification.title.isNotEmpty
                            ? _classification.title
                            : 'Condiciones observadas:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.0,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: availableTags.map((tagKey) {
                          final label = _classification.getTagLabel(tagKey);
                          final active = tags[tagKey] ?? false;
                          return FilterChip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 12.0)),
                            selected: active,
                            selectedColor: widget.theme.accentColor
                                .withValues(alpha: 0.25),
                            onSelected: (v) {
                              setModalState(() => tags[tagKey] = v);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14.0),
                    TextField(
                      controller: aliasController,
                      decoration: const InputDecoration(
                        labelText: 'Pseudónimo (Protege tu identidad)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.person_pin),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextField(
                      controller: careerController,
                      decoration: const InputDecoration(
                        labelText: 'Carrera o Facultad',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Comentario u observaciones (opcional)',
                        hintText: 'Describe el estado general...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      onPressed: () {
                        _repo.submitReview(
                          targetId: widget.targetId,
                          targetType: widget.targetType,
                          targetCategory: widget.targetCategory,
                          rating: selectedRating,
                          comment: commentController.text,
                          tags: tags,
                          authorAlias: aliasController.text.trim().isNotEmpty
                              ? aliasController.text.trim()
                              : 'Estudiante USAC',
                          authorCarrera:
                              careerController.text.trim().isNotEmpty
                                  ? careerController.text.trim()
                                  : null,
                          authorIsVerified: true,
                        );
                        Navigator.of(modalCtx).pop();
                        setState(() {});
                      },
                      child: const Text(
                        'Publicar Calificación',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final aggregate = _repo.getAggregate(
      widget.targetId,
      category: widget.targetCategory,
    );
    final reviews = _repo.getReviews(widget.targetId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Badge de Clasificación Personalizada
        if (_classification.tiers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: RatingClassificationBadge(
              averageRating: aggregate.averageRating,
              config: _classification,
              tagsSummary: aggregate.tagsSummary,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      aggregate.averageRating > 0
                          ? aggregate.averageRating.toStringAsFixed(1)
                          : 'S/C',
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.primaryColor,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < aggregate.averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16.0,
                          color: Colors.amber.shade700,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${aggregate.totalReviews} ${aggregate.totalReviews == 1 ? "evaluación" : "evaluaciones de estudiantes"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Calificaciones públicas con pseudónimo protegido.',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Botón Calificar
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.theme.primaryColor,
            side: BorderSide(color: widget.theme.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          icon: const Icon(Icons.rate_review_outlined, size: 18.0),
          label: Text(
            'Calificar ${widget.targetName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _openReviewModal,
        ),
        const SizedBox(height: 14.0),

        // Lista de Reseñas
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'Aún no hay calificaciones para este lugar.\n¡Sé el primero en calificarlo!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.0),
              ),
            ),
          )
        else
          ...reviews.map((rev) => _buildReviewCard(rev)),
      ],
    );
  }

  Widget _buildReviewCard(CampusReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.0,
                backgroundColor:
                    widget.theme.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  review.authorAlias.isNotEmpty
                      ? review.authorAlias[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.authorAlias,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                        if (review.authorIsVerified) ...[
                          const SizedBox(width: 4.0),
                          const Icon(
                            Icons.verified,
                            size: 14.0,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                    if (review.authorCarrera != null)
                      Text(
                        review.authorCarrera!,
                        style: TextStyle(
                          fontSize: 11.0,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 15.0,
                    color: Colors.amber.shade700,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 13.0, height: 1.3),
            ),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: review.tags.entries.where((e) => e.value).map((e) {
                final label = _classification.getTagLabel(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: TextStyle(fontSize: 11.0, color: Colors.grey.shade500),
              ),
              InkWell(
                onTap: () {
                  _repo.toggleLikeReview(widget.targetId, review.id);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 13.0,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${review.likesCount}',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
