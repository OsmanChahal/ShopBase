/// Represents a business-owned tag that can be attached to customers.
class Tag {
  final String id;
  final String businessId;
  final String label;
  final String source; // 'manual' for now — reserved for future AI suggestions
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.businessId,
    required this.label,
    this.source = 'manual',
    required this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      label: json['label'] as String,
      source: json['source'] as String? ?? 'manual',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'label': label,
      'source': source,
    };
  }
}
