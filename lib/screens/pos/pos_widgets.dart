part of '../pos_screen.dart';

// ── widgets ──────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _brand : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: selected ? null : Border.all(color: _slate200),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x33170A2E),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _slate700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? const Color(0x33FFFFFF) : _slate100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosProductCard extends StatelessWidget {
  final Product product;
  final double rate;
  final int inCart;
  final bool canSell;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PosProductCard({
    required this.product,
    required this.rate,
    required this.inCart,
    required this.canSell,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final q = product.quantity;
    final out = product.isOutOfStock;
    final low = product.isLowStock && !out;
    final badgeColor = out ? AppColors.statusError : (low ? _amber : _emerald);
    final badgeText = out
        ? 'Out of stock'
        : (low ? '$q left (Low)' : '$q in stock');
    final cat = product.category?.trim();

    return Opacity(
      opacity: out ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: out ? null : onAdd,
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: inCart > 0 ? _purple600 : _slate100,
                width: inCart > 0 ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xB3FFFBEB), Color(0x66FEF3C7)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // TODO(backend): product photos need an image column
                        // and storage. Placeholder icon for now.
                        const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 44,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (cat != null && cat.isNotEmpty)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            right: 8,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xE6FFFFFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cat.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: _brand,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.sellPriceUsd.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: _brand,
                            ),
                          ),
                          if (rate > 0)
                            Text(
                              'LBP ${formatLbpRounded(product.sellPriceUsd * rate)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _slate400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!out) _control(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _control() {
    if (inCart == 0) {
      return InkWell(
        onTap: onAdd,
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: canSell ? _brand : _slate400,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: Icon(Icons.remove_rounded, size: 14, color: _brand),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$inCart',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _brand,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            customBorder: const CircleBorder(),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: _brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
