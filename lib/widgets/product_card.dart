import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import 'stat_badge.dart';

enum ProductCardLayout { grid, list }

/// Reusable product card supporting both 2-column POS grid and compact Inventory row layouts.
class ProductCard extends StatelessWidget {
  final Product product;
  final double currencyRate;
  final ProductCardLayout layout;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int inCartCount;

  const ProductCard({
    super.key,
    required this.product,
    required this.currencyRate,
    this.layout = ProductCardLayout.grid,
    required this.onTap,
    this.onLongPress,
    this.inCartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.quantity <= 0;
    final isLowStock = product.isLowStock && !isOutOfStock;
    final lbpPrice = product.sellPriceUsd * currencyRate;

    if (layout == ProductCardLayout.list) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryPurple,
              size: 22,
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                '\$${product.sellPriceUsd.toStringAsFixed(2)} · LBP ${_formatLbp(lbpPrice)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: isOutOfStock
              ? StatBadge.error(label: 'Out of Stock')
              : isLowStock
                  ? StatBadge.warning(label: 'Low (${product.quantity})')
                  : StatBadge.success(label: 'High (${product.quantity})'),
        ),
      );
    }

    // Grid layout for POS
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isOutOfStock ? AppColors.screenBackground : AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: inCartCount > 0 ? AppColors.primaryPurple : AppColors.borderLight,
          width: inCartCount > 0 ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name & Category
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isOutOfStock ? AppColors.textSecondary : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.category != null && product.category!.isNotEmpty) ...[
                const SizedBox(height: 4),
                StatBadge.purple(label: product.category!),
              ],

              const Spacer(),

              // Price
              Text(
                '\$${product.sellPriceUsd.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primaryPurple,
                ),
              ),
              if (currencyRate > 0)
                Text(
                  'LBP ${_formatLbp(lbpPrice)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

              const SizedBox(height: 8),

              // Stock Status & Cart Count Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isOutOfStock
                      ? StatBadge.error(label: 'Out')
                      : isLowStock
                          ? StatBadge.warning(label: '${product.quantity} left')
                          : StatBadge.success(label: '${product.quantity} left'),
                  if (inCartCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '×$inCartCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLbp(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
