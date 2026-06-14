// ─────────────────────────────────────────────────────────────────────────────
//  lib/widgets/product_card.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String   title;
  final String   seller;
  final String   price;
  final String?  oldPrice;
  final String?  discount;
  final String?  imageUrl;      // remote URL from backend; null = icon fallback
  final double   rating;
  final int      reviews;
  final String?  tag;
  final bool     inWishlist;
  final VoidCallback onAddToCart;
  final VoidCallback onWishlist;

  const ProductCard({
    super.key,
    required this.title,
    required this.seller,
    required this.price,
    this.oldPrice,
    this.discount,
    this.imageUrl,
    required this.rating,
    required this.reviews,
    this.tag,
    this.inWishlist = false,
    required this.onAddToCart,
    required this.onWishlist,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Image area ──────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [

                // Product image or fallback
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackImage(),
                          loadingBuilder: (ctx, child, progress) => progress == null
                              ? child
                              : const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                        )
                      : _fallbackImage(),
                ),

                // Discount badge
                if (discount != null)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.red, borderRadius: BorderRadius.circular(20)),
                      child: Text(discount!,
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),

                // Wishlist heart
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onWishlist,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(
                        inWishlist ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: inWishlist ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Tag pill
                if (tag != null)
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(tag!,
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info area ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Title
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),

                const SizedBox(height: 3),

                // Seller
                Text(seller,
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),

                const SizedBox(height: 5),

                // Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    if (oldPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(oldPrice!,
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 11)),
                    ],
                  ],
                ),

                const SizedBox(height: 5),

                // Stars
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      if (i < rating.floor()) {
                        return const Icon(Icons.star, color: Colors.orange, size: 13);
                      } else if (i < rating) {
                        return const Icon(Icons.star_half, color: Colors.orange, size: 13);
                      } else {
                        return const Icon(Icons.star_border, color: Colors.orange, size: 13);
                      }
                    }),
                    const SizedBox(width: 4),
                    Text('($reviews)',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),

                const SizedBox(height: 8),

                // Add to cart button
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                    ),
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.shopping_cart,
                        color: Colors.white, size: 14),
                    label: const Text('Add to Cart',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // Grey placeholder when no image / image fails to load
  Widget _fallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xfff7f4ea),
      child: const Center(
        child: Icon(Icons.checkroom, size: 72, color: Colors.blue),
      ),
    );
  }
}