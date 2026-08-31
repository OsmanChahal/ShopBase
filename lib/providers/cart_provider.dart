import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'auth_provider.dart';

/// Manages the shopping cart state.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Add a product to the cart, or increment its quantity if already present.
  /// Throws if adding would exceed available stock.
  void addToCart(Product product) {
    final existingIndex = state.indexWhere((c) => c.productId == product.id);

    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      if (existing.quantity >= product.quantity) {
        throw Exception('Only ${product.quantity} left in stock');
      }
      final updated = existing.copyWith(
        quantity: existing.quantity + 1,
        availableStock: product.quantity,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      if (product.quantity <= 0) {
        throw Exception('${product.name} is out of stock');
      }
      state = [...state, CartItem.fromProduct(product)];
    }
  }

  /// Remove a product entirely from the cart.
  void removeFromCart(String productId) {
    state = state.where((c) => c.productId != productId).toList();
  }

  /// Increment quantity by 1, respecting stock limit.
  void incrementQuantity(String productId) {
    state = state.map((c) {
      if (c.productId == productId) {
        if (c.quantity >= c.availableStock) {
          throw Exception('Only ${c.availableStock} left in stock');
        }
        return c.copyWith(quantity: c.quantity + 1);
      }
      return c;
    }).toList();
  }

  /// Decrement quantity by 1; removes the item if quantity reaches 0.
  void decrementQuantity(String productId) {
    final updated = <CartItem>[];
    for (final c in state) {
      if (c.productId == productId) {
        if (c.quantity > 1) {
          updated.add(c.copyWith(quantity: c.quantity - 1));
        }
        // If quantity would be 0, skip it (remove from cart)
      } else {
        updated.add(c);
      }
    }
    state = updated;
  }

  /// Set a custom/override price for an item.
  /// Pass null to clear the override and revert to the original price.
  void setOverridePrice(String productId, double? price) {
    state = state.map((c) {
      if (c.productId == productId) {
        return c.copyWith(overridePrice: () => price);
      }
      return c;
    }).toList();
  }

  /// Update the available stock for a specific cart item (used during checkout validation).
  void updateAvailableStock(String productId, int newStock) {
    state = state.map((c) {
      if (c.productId == productId) {
        return c.copyWith(availableStock: newStock);
      }
      return c;
    }).toList();
  }

  /// Clear the entire cart.
  void clear() {
    state = [];
  }
}

/// The cart state provider.
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

/// Total USD amount of all items in the cart.
final cartTotalUsdProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotalUsd);
});

/// Total LBP amount (USD total × current exchange rate).
final cartTotalLbpProvider = Provider<double>((ref) {
  final totalUsd = ref.watch(cartTotalUsdProvider);
  final business = ref.watch(currentBusinessProvider);
  final rate = business?.currencyRate ?? 0;
  return totalUsd * rate;
});

/// Number of items in the cart (sum of quantities).
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

/// Currency display toggle: 'USD' or 'LBP'.
final currencyDisplayProvider = StateProvider<String>((ref) => 'USD');

/// Payment type toggle: 'cash' or 'card'.
final paymentTypeProvider = StateProvider<String>((ref) => 'cash');

/// Selected customer for linking to sale (optional).
final selectedCustomerIdProvider = StateProvider<String?>((ref) => null);
final selectedCustomerNameProvider = StateProvider<String?>((ref) => null);
