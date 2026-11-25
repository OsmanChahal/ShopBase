import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

/// Selected category tab on the POS screen (null = All Items).
final posCategoryProvider = StateProvider<String?>((ref) => null);

/// Number of products per category, using trimmed category names and
/// skipping products without one.
Map<String, int> productCountsByCategory(List<Product> products) {
  final counts = <String, int>{};
  for (final p in products) {
    final c = p.category?.trim();
    if (c != null && c.isNotEmpty) counts[c] = (counts[c] ?? 0) + 1;
  }
  return counts;
}

/// [products] whose trimmed category equals [category]; all of them when
/// [category] is null.
List<Product> filterByCategory(List<Product> products, String? category) {
  return category == null
      ? products
      : products.where((p) => p.category?.trim() == category).toList();
}
