// =============================================================
// FILE: lib/features/wishlist/presentation/screens/wishlist_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../home/data/models/product_model.dart';
import '../../../product/presentation/screens/product_detail_screen.dart';

// Wishlist provider
final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<ProductModel>>(
  (ref) => WishlistNotifier());

class WishlistNotifier extends StateNotifier<List<ProductModel>> {
  WishlistNotifier() : super([]);

  void toggle(ProductModel product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
  }

  bool contains(int id) => state.any((p) => p.id == id);
  void remove(int id) => state = state.where((p) => p.id != id).toList();
  void clear() => state = [];
}

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    return s.length > 3
        ? 'MK ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
        : 'MK $s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Wishlist (${wishlist.length})',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16,
            fontWeight: FontWeight.w700)),
        actions: [
          if (wishlist.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(wishlistProvider.notifier).clear(),
              child: Text('Clear All',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w600))),
        ],
      ),
      body: wishlist.isEmpty ? _emptyWishlist(context) : _wishlistGrid(context, ref, wishlist),
    );
  }

  Widget _emptyWishlist(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🤍', style: TextStyle(fontSize: 80)),
      const SizedBox(height: 16),
      Text('Your wishlist is empty',
        style: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Save products you love for later',
        style: GoogleFonts.dmSans(
          color: AppTheme.textHint, fontSize: 14)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context, '/home', (r) => false),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          padding: const EdgeInsets.symmetric(
            horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10))),
        child: Text('Browse Products',
          style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700,
            fontSize: 15)),
      ),
    ]),
  );

  Widget _wishlistGrid(BuildContext context, WidgetRef ref,
      List<ProductModel> wishlist) =>
    GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: wishlist.length,
      itemBuilder: (_, i) {
        final product = wishlist[i];
        return GestureDetector(
          onTap: () {
            final container = ProviderScope.containerOf(context);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => UncontrolledProviderScope(
                container: container,
                child: ProductDetailScreen(product: product))));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                    child: Container(
                      height: 150, width: double.infinity,
                      color: const Color(0xFFF4F4F2),
                      child: Center(child: Text('📦',
                        style: const TextStyle(fontSize: 50)))),
                  ),
                  Positioned(top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => ref.read(wishlistProvider.notifier)
                          .remove(product.id),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4)]),
                        child: const Icon(Icons.favorite,
                          size: 16, color: AppTheme.primaryRed)))),
                ]),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(_fmt(product.price),
                        style: GoogleFonts.dmSans(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier)
                                .addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart ✓'),
                                backgroundColor: Colors.green.shade700,
                                duration: const Duration(seconds: 2)));
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                          child: Text('Add to Cart',
                            style: GoogleFonts.dmSans(
                              fontSize: 12, fontWeight: FontWeight.w600)))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
}
