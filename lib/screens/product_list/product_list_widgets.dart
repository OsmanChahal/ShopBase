part of '../product_list_screen.dart';

// ── widgets ──────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool accent;
  final bool enabled;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    this.selected = false,
    this.accent = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = selected
        ? Colors.white
        : accent
        ? const Color(0xFF7E22CE)
        : InvDesign.slate600;
    final decoration = BoxDecoration(
      gradient: selected ? InvDesign.brandGradient : null,
      color: selected
          ? null
          : accent
          ? const Color(0xFFFAF5FF)
          : Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: selected
          ? null
          : Border.all(
              color: accent ? const Color(0xFFE9D5FF) : InvDesign.slate200,
            ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Tooltip(
          message: enabled ? '' : 'Coming soon',
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 16 : 14,
                vertical: 6,
              ),
              decoration: decoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final bool selecting;
  final bool selected;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onAction;

  const _ProductRow({
    required this.product,
    required this.selecting,
    required this.selected,
    required this.canEdit,
    required this.onTap,
    required this.onLongPress,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final out = product.isOutOfStock;
    final low = product.isLowStock && !out;
    final restock = low || out;
    final sub = out
        ? 'Out of stock'
        : low
        ? 'Threshold reached (≤ ${product.lowStockThreshold})'
        : ((product.category?.isNotEmpty ?? false)
              ? product.category!
              : (product.sku ?? ''));
    // TODO(backend): shelf/aisle location ("Aisle 2 • Shelf A") and inbound
    // units ("5 units inbound") need new columns / in-transit transfers.

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: (low || out)
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white, Color(0x4DFFFBEB)],
                  )
                : null,
            color: (low || out) ? null : Colors.white,
            border: Border.all(
              color: selected
                  ? const Color(0xFF9333EA)
                  : ((low || out)
                        ? const Color(0xB3FEF3C7)
                        : InvDesign.slate100),
              width: selected ? 2 : 1,
            ),
            boxShadow: InvDesign.cardShadow,
          ),
          child: Row(
            children: [
              // Thumbnail (no image column yet: placeholder icon)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xCCFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Icon(
                  selecting && selected
                      ? Icons.check_circle_rounded
                      : Icons.inventory_2_outlined,
                  color: selecting && selected
                      ? const Color(0xFF9333EA)
                      : InvDesign.amber600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: InvDesign.slate900,
                            ),
                          ),
                        ),
                        if (restock) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${product.sellPriceUsd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: InvDesign.slate500,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: restock
                              ? InvDesign.amber600
                              : InvDesign.slate400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: out
                          ? AppColors.statusError
                          : (low ? InvDesign.orange : InvDesign.green),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      out
                          ? 'Out of Stock'
                          : '${low ? 'Low' : 'High'} (${product.quantity})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (canEdit && !selecting) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onAction,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            restock ? 'Restock' : 'Transfer',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            restock
                                ? Icons.add_rounded
                                : Icons.arrow_forward_rounded,
                            size: 11,
                            color: const Color(0xFF9333EA),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: InvDesign.fabGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73B833C4),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}
