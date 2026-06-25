// =============================================================
// FILE: lib/core/providers/cart_provider.dart
//
// Manages cart state using Riverpod.
// Stores CartItem list — each item has a product + quantity + size.
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/data/models/product_model.dart';

// ── Cart Item ─────────────────────────────────────────────────
class CartItem {
  final ProductModel product;
  final int quantity;
  final String? selectedSize;

  const CartItem({
    required this.product,
    required this.quantity,
    this.selectedSize,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({int? quantity, String? selectedSize}) => CartItem(
    product:      product,
    quantity:     quantity ?? this.quantity,
    selectedSize: selectedSize ?? this.selectedSize,
  );
}

// ── Cart Notifier ─────────────────────────────────────────────
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // Add product to cart — if already in cart, increase quantity
  void addItem(ProductModel product, {String? size, int quantity = 1}) {
    final index = state.indexWhere(
      (item) => item.product.id == product.id && item.selectedSize == size);

    if (index >= 0) {
      // Already in cart — increase quantity
      final updated = List<CartItem>.from(state);
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + quantity);
      state = updated;
    } else {
      // New item
      state = [...state, CartItem(product: product, quantity: quantity, selectedSize: size)];
    }
  }

  // Remove item completely
  void removeItem(int productId, String? size) {
    state = state.where(
      (item) => !(item.product.id == productId && item.selectedSize == size)).toList();
  }

  // Increase quantity
  void increaseQuantity(int productId, String? size) {
    state = state.map((item) {
      if (item.product.id == productId && item.selectedSize == size) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
  }

  // Decrease quantity — removes if reaches 0
  void decreaseQuantity(int productId, String? size) {
    state = state.map((item) {
      if (item.product.id == productId && item.selectedSize == size) {
        return item.copyWith(quantity: item.quantity - 1);
      }
      return item;
    }).toList().where((item) => item.quantity > 0).toList();
  }

  // Clear entire cart
  void clearCart() => state = [];

  // Computed getters
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => state.fold(0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => state.isEmpty ? 0 : 1500;
  double get total => subtotal + deliveryFee;

  bool containsProduct(int productId) =>
      state.any((item) => item.product.id == productId);
}

// ── Provider ──────────────────────────────────────────────────
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

// Derived — total item count for badge
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.notifier).itemCount;
});

// Derived — cart total
final cartTotalProvider = Provider<double>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).total;
});
