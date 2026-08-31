import 'product.dart';

/// Represents one item in the shopping cart.
/// Supports price override (discount) — if overridePrice is set, it's used
/// instead of the product's sell price.
class CartItem {
  final String productId;
  final String productName;
  final double unitPriceUsd;
  final double costPriceUsd;
  final int quantity;
  final int availableStock;
  final double? overridePrice; // null = use unitPriceUsd

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPriceUsd,
    required this.costPriceUsd,
    required this.quantity,
    required this.availableStock,
    this.overridePrice,
  });

  /// The effective price used for this item (override or original).
  double get effectivePrice => overridePrice ?? unitPriceUsd;

  /// Whether the effective price is below cost — triggers a red warning.
  bool get isBelowCost => effectivePrice < costPriceUsd;

  /// Whether a custom price has been set.
  bool get hasDiscount => overridePrice != null && overridePrice != unitPriceUsd;

  /// Line subtotal using the effective price.
  double get subtotalUsd => effectivePrice * quantity;

  /// Create a CartItem from a Product (first add to cart).
  factory CartItem.fromProduct(Product product) {
    return CartItem(
      productId: product.id!,
      productName: product.name,
      unitPriceUsd: product.sellPriceUsd,
      costPriceUsd: product.costPriceUsd,
      quantity: 1,
      availableStock: product.quantity,
    );
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    double? unitPriceUsd,
    double? costPriceUsd,
    int? quantity,
    int? availableStock,
    double? Function()? overridePrice,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPriceUsd: unitPriceUsd ?? this.unitPriceUsd,
      costPriceUsd: costPriceUsd ?? this.costPriceUsd,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
      overridePrice: overridePrice != null ? overridePrice() : this.overridePrice,
    );
  }
}
