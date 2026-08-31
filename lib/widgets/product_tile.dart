import 'package:flutter/material.dart';
import '../models/product.dart';

/// A card widget displaying a product's key info in the list.
/// Shows low-stock warning when quantity is at or below threshold.
class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onStockAdjust;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
    required this.onStockAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = product.isLowStock;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Product info (left side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Category + SKU row
                    Row(
                      children: [
                        if (product.category != null &&
                            product.category!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.category!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (product.sku != null &&
                            product.sku!.isNotEmpty)
                          Text(
                            product.sku!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price column
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product.sellPriceUsd.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'USD',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity + stock adjust button
              Container(
                width: 72,
                decoration: BoxDecoration(
                  color: isLow
                      ? const Color(0xFFFEE2E2) // Red 100
                      : const Color(0xFFF0FDF4), // Green 50
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLow)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        Text(
                          '${product.quantity}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isLow
                                ? theme.colorScheme.error
                                : const Color(0xFF16A34A), // Green 600
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'in stock',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: isLow
                            ? theme.colorScheme.error.withValues(alpha: 0.7)
                            : const Color(0xFF16A34A).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Quick stock adjust button
              IconButton(
                onPressed: onStockAdjust,
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'Adjust stock',
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
