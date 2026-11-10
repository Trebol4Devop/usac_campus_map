import 'package:flutter/material.dart';

/// Elemento o nivel individual de calificación para una categoría.
class RatingTierItem {
  final String code;
  final String label;
  final String emoji;
  final int colorHex;
  final String description;
  final double minRating;

  const RatingTierItem({
    required this.code,
    required this.label,
    required this.emoji,
    required this.colorHex,
    required this.description,
    required this.minRating,
  });

  Color get color => Color(colorHex);

  factory RatingTierItem.fromJson(Map<String, dynamic> json) {
    return RatingTierItem(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '⭐',
      colorHex: (json['color_hex'] as num?)?.toInt() ?? 0xFF3B82F6,
      description: json['description'] as String? ?? '',
      minRating: (json['min_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'emoji': emoji,
      'color_hex': colorHex,
      'description': description,
      'min_rating': minRating,
    };
  }
}

/// Configuración personalizable de clasificación y etiquetas de evaluación para
/// cualquier categoría de lugar o servicio del campus (sanitarios, aulas, cafeterías, etc.).
class RatingClassificationConfig {
  final String category;
  final String title;
  final List<RatingTierItem> tiers;
  final List<String> availableTags;
  final Map<String, String> tagLabels;

  const RatingClassificationConfig({
    required this.category,
    this.title = '',
    required this.tiers,
    this.availableTags = const [],
    this.tagLabels = const {},
  });

  /// Resuelve el nivel o tier correspondiente según el promedio de calificación.
  RatingTierItem? resolveTier(double avgRating) {
    if (tiers.isEmpty) return null;
    for (final tier in tiers) {
      if (avgRating >= tier.minRating) {
        return tier;
      }
    }
    return tiers.last;
  }

  /// Retorna la etiqueta formateada para un tag particular.
  String getTagLabel(String tagKey) {
    return tagLabels[tagKey] ?? tagKey;
  }

  /// Configuración predeterminada limpia y profesional para sanitarios.
  static RatingClassificationConfig defaultSanitarios() {
    return const RatingClassificationConfig(
      category: 'sanitarios',
      title: 'Clasificación de Sanitarios',
      tiers: [
        RatingTierItem(
          code: 'excelente',
          label: 'Excelente',
          emoji: '✨',
          colorHex: 0xFF10B981, // Esmeralda
          description:
              'Instalaciones impecables, agua constante, jabón y papel disponibles.',
          minRating: 4.5,
        ),
        RatingTierItem(
          code: 'muy_bueno',
          label: 'Muy Bueno',
          emoji: '👍',
          colorHex: 0xFF3B82F6, // Azul
          description:
              'Muy buen estado higiénico, agua disponible y pestillos funcionales.',
          minRating: 3.8,
        ),
        RatingTierItem(
          code: 'aceptable',
          label: 'Aceptable',
          emoji: '👌',
          colorHex: 0xFF84CC16, // Lima
          description: 'Higiene básica y servicio de agua disponible.',
          minRating: 3.0,
        ),
        RatingTierItem(
          code: 'regular',
          label: 'Regular',
          emoji: '⚠️',
          colorHex: 0xFFEA580C, // Naranja
          description: 'Requiere atención: puede faltar agua, jabón o papel.',
          minRating: 2.0,
        ),
        RatingTierItem(
          code: 'deficiente',
          label: 'Deficiente',
          emoji: '⛔',
          colorHex: 0xFFDC2626, // Rojo
          description:
              'Higiene o suministros deficientes. Requiere mantenimiento urgente.',
          minRating: 0.0,
        ),
      ],
      availableTags: [
        'has_water',
        'has_paper',
        'has_soap',
        'door_locks',
        'is_clean',
      ],
      tagLabels: {
        'has_water': '💧 Agua corriente',
        'has_paper': '🧻 Papel higiénico',
        'has_soap': '🧼 Jabón de manos',
        'door_locks': '🔒 Pestillo seguro',
        'is_clean': '✨ Limpio',
      },
    );
  }

  /// Configuración predeterminada para edificios y facultades en general.
  static RatingClassificationConfig defaultGeneral() {
    return const RatingClassificationConfig(
      category: 'general',
      title: 'Evaluación de Instalaciones',
      tiers: [
        RatingTierItem(
          code: 'excelente',
          label: 'Excelente',
          emoji: '⭐',
          colorHex: 0xFFF59E0B, // Ámbar
          description:
              'Instalaciones de alto nivel, excelente iluminación y conectividad.',
          minRating: 4.5,
        ),
        RatingTierItem(
          code: 'muy_bueno',
          label: 'Muy Bueno',
          emoji: '👍',
          colorHex: 0xFF10B981,
          description: 'Ambiente agradable y adecuado para el estudio.',
          minRating: 3.5,
        ),
        RatingTierItem(
          code: 'aceptable',
          label: 'Aceptable',
          emoji: '👌',
          colorHex: 0xFF3B82F6,
          description: 'Cumple los requerimientos básicos.',
          minRating: 2.5,
        ),
        RatingTierItem(
          code: 'por_mejorar',
          label: 'Por Mejorar',
          emoji: '⚠️',
          colorHex: 0xFFEA580C,
          description: 'Requiere mejoras en infraestructura o servicios.',
          minRating: 0.0,
        ),
      ],
      availableTags: [
        'has_wifi',
        'has_power_outlets',
        'good_lighting',
        'quiet_area',
        'accessible',
      ],
      tagLabels: {
        'has_wifi': '📶 Buen WiFi',
        'has_power_outlets': '🔌 Tomacorrientes',
        'good_lighting': '💡 Buena iluminación',
        'quiet_area': '🤫 Área silenciosa',
        'accessible': '♿ Accesible',
      },
    );
  }
}
