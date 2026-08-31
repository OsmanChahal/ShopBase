/// Represents a completed sale.
class Sale {
  final String id;
  final String businessId;
  final String? customerId;
  final double totalUsd;
  final double totalLbp;
  final double exchangeRateUsed;
  final String paymentType;
  final DateTime createdAt;
  final List<SaleItem>? items; // Loaded separately when viewing details

  const Sale({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.totalUsd,
    required this.totalLbp,
    required this.exchangeRateUsed,
    required this.paymentType,
    required this.createdAt,
    this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String?,
      totalUsd: (json['total_usd'] as num).toDouble(),
      totalLbp: (json['total_lbp'] as num).toDouble(),
      exchangeRateUsed: (json['exchange_rate_used'] as num).toDouble(),
      paymentType: json['payment_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'customer_id': customerId,
      'total_usd': totalUsd,
      'total_lbp': totalLbp,
      'exchange_rate_used': exchangeRateUsed,
      'payment_type': paymentType,
    };
  }

  Sale copyWith({List<SaleItem>? items}) {
    return Sale(
      id: id,
      businessId: businessId,
      customerId: customerId,
      totalUsd: totalUsd,
      totalLbp: totalLbp,
      exchangeRateUsed: exchangeRateUsed,
      paymentType: paymentType,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}

/// Represents one line item within a sale.
class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productNameSnapshot;
  final int quantity;
  final double unitPriceUsd;
  final double subtotalUsd;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unitPriceUsd,
    required this.subtotalUsd,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      productId: json['product_id'] as String,
      productNameSnapshot: json['product_name_snapshot'] as String,
      quantity: json['quantity'] as int,
      unitPriceUsd: (json['unit_price_usd'] as num).toDouble(),
      subtotalUsd: (json['subtotal_usd'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'product_id': productId,
      'product_name_snapshot': productNameSnapshot,
      'quantity': quantity,
      'unit_price_usd': unitPriceUsd,
      'subtotal_usd': subtotalUsd,
    };
  }
}
