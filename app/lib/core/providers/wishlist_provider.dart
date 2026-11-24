// =============================================================
// FILE: lib/core/providers/wishlist_provider.dart
//
// Guests keep a wishlist on the device for the current visit.
// Logged-in customers' wishlists are saved on the server, so they
// follow the customer across devices.
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/models/product_model.dart';
import '../services/api_service.dart';
import 'customer_session_provider.dart';

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<ProductModel>>((ref) {
  final notifier = WishlistNotifier(ApiService());
  ref.listen<Customer?>(customerSessionProvider, (previous, next) {
    if (next != null && previous?.id != next.id) {
      notifier.syncAfterLogin();
    } else if (next == null && previous != null) {
      notifier.clearLocal();
    }
  }, fireImmediately: true);
  return notifier;
});

class WishlistNotifier extends StateNotifier<List<ProductModel>> {
  WishlistNotifier(this._api) : super([]);

  final ApiService _api;
  bool _loggedIn = false;

  bool contains(int id) => state.any((p) => p.id == id);

  /// Uploads anything saved as a guest, then loads the server wishlist.
  Future<void> syncAfterLogin() async {
    _loggedIn = true;
    try {
      for (final product in state) {
        await _api.addToWishlist(product.id);
      }
      state = await _api.getWishlist();
    } on ApiException {
      // Keep the local list; it will sync on the next change.
    }
  }

  void clearLocal() {
    _loggedIn = false;
    state = [];
  }

  /// Adds or removes [product]. Updates the screen immediately and
  /// rolls back if the server rejects the change.
  Future<void> toggle(ProductModel product) async {
    final previous = state;
    final adding = !contains(product.id);
    state = adding ? [product, ...state] : state.where((p) => p.id != product.id).toList();
    if (!_loggedIn) return;
    try {
      if (adding) {
        await _api.addToWishlist(product.id);
      } else {
        await _api.removeFromWishlist(product.id);
      }
    } on ApiException {
      state = previous;
      rethrow;
    }
  }

  Future<void> remove(int id) async {
    final product = state.where((p) => p.id == id).firstOrNull;
    if (product != null) await toggle(product);
  }

  Future<void> clear() async {
    final items = [...state];
    state = [];
    if (!_loggedIn) return;
    for (final p in items) {
      await _api.removeFromWishlist(p.id).catchError((_) {});
    }
  }
}
