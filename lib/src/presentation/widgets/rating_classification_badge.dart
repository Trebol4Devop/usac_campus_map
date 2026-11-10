import 'package:flutter/material.dart';
import '../../models/rating_classification.dart';

/// Badge visual para mostrar la clasificación y etiquetas de evaluación
/// personalizadas según la categoría del lugar (sanitarios, aulas, cafeterías, etc.).
class RatingClassificationBadge extends StatelessWidget {
  final double averageRating;
  final RatingClassificationConfig config;
  final bool showDescription;
  final bool compact;
  final Map<String, int>? tagsSummary;

  const RatingClassificationBadge({
    super.key,
    required this.averageRating,
    required this.config,
    this.showDescription = true,
    this.compact = false,
    this.tagsSummary,
  });

  @override
  Widget build(BuildContext context) {
    final tier = config.resolveTier(averageRating);
    if (tier == null) return const SizedBox.shrink();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: tier.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: tier.color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tier.emoji, style: const TextStyle(fontSize: 14.0)),
            const SizedBox(width: 4.0),
            Text(
              tier.label,
              style: TextStyle(
                color: tier.color,
                fontWeight: FontWeight.bold,
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: tier.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  tier.emoji,
                  style: const TextStyle(fontSize: 22.0),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tier.label,
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: tier.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: tier.color,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            averageRating > 0
                                ? averageRating.toStringAsFixed(1)
                                : 'S/C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showDescription && tier.description.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        tier.description,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (tagsSummary != null && tagsSummary!.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: tagsSummary!.entries
                  .where((e) => e.value > 0)
                  .map((e) {
                final label = config.getTagLabel(e.key);
                return _tagChip('$label (${e.value})', tier.color);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
