class Product {
  final String? id;
  final String businessId;
  final String name;
  final String? sku;
  final String? category;
  final double costPriceUsd;
  final double sellPriceUsd;
  final int quantity;
  final int lowStockThreshold;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    required this.businessId,
    required this.name,
    this.sku,
    this.category,
    required this.costPriceUsd,
    required this.sellPriceUsd,
    required this.quantity,
    this.lowStockThreshold = 5,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether the product is at or below its low stock threshold.
  bool get isLowStock => quantity <= lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      category: json['category'] as String?,
      costPriceUsd: (json['cost_price_usd'] as num).toDouble(),
      sellPriceUsd: (json['sell_price_usd'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lowStockThreshold: (json['low_stock_threshold'] as int?) ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'business_id': businessId,
      'name': name,
      'sku': sku,
      'category': category,
      'cost_price_usd': costPriceUsd,
      'sell_price_usd': sellPriceUsd,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      // created_at and updated_at are managed by the database
    };
  }

  Product copyWith({
    String? id,
    String? businessId,
    String? name,
    String? sku,
    String? category,
    double? costPriceUsd,
    double? sellPriceUsd,
    int? quantity,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      costPriceUsd: costPriceUsd ?? this.costPriceUsd,
      sellPriceUsd: sellPriceUsd ?? this.sellPriceUsd,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
