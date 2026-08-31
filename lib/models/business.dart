class Business {
  final String id;
  final String ownerId;
  final String name;
  final double currencyRate;
  final DateTime? currencyRateUpdatedAt;
  final DateTime createdAt;

  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.currencyRate,
    this.currencyRateUpdatedAt,
    required this.createdAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      currencyRate: (json['currency_rate'] as num).toDouble(),
      currencyRateUpdatedAt: json['currency_rate_updated_at'] != null
          ? DateTime.parse(json['currency_rate_updated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'currency_rate': currencyRate,
      'currency_rate_updated_at': currencyRateUpdatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Business copyWith({
    String? id,
    String? ownerId,
    String? name,
    double? currencyRate,
    DateTime? currencyRateUpdatedAt,
    DateTime? createdAt,
  }) {
    return Business(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      currencyRate: currencyRate ?? this.currencyRate,
      currencyRateUpdatedAt: currencyRateUpdatedAt ?? this.currencyRateUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
