class CampusEdge {
  final String source;
  final String target;
  final double weight;
  final String type;

  const CampusEdge({
    required this.source,
    required this.target,
    required this.weight,
    required this.type,
  });

  factory CampusEdge.fromJson(Map<String, dynamic> json) {
    return CampusEdge(
      source: json['source'] as String,
      target: json['target'] as String,
      weight: (json['weight'] as num).toDouble(),
      type: json['type'] as String? ?? 'walkway',
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'target': target,
    'weight': weight,
    'type': type,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusEdge &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          target == other.target &&
          type == other.type;

  @override
  int get hashCode => Object.hash(source, target, type);
}
