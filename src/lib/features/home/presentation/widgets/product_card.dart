// =============================================================
// FILE: lib/features/home/presentation/widgets/product_card.dart
// UPDATED: Uses GoogleFonts instead of fontFamily strings
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(product),
            _buildInfoSection(product),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ProductModel product) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusMD),
            topRight: Radius.circular(AppTheme.radiusMD),
          ),
          child: Container(
            height: 180,
            width: double.infinity,
            color: _getCategoryColor(product.category),
            child: Center(child: Text(_getCategoryEmoji(product.category), style: const TextStyle(fontSize: 64))),
          ),
        ),
        if (product.hasDiscount)
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(40)),
              child: Text('-${product.discount}%',
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
        Positioned(
          top: 6, right: 6,
          child: GestureDetector(
            onTap: () => setState(() => _isWishlisted = !_isWishlisted),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
              ),
              child: Icon(
                _isWishlisted ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: _isWishlisted ? AppTheme.primaryRed : AppTheme.textHint,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('by ${product.sellerName}',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textHint)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(product.formattedPrice,
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
              if (product.hasDiscount) ...[
                const SizedBox(width: 6),
                Text('MK ${product.originalPrice!.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textHint, decoration: TextDecoration.lineThrough)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 13, color: Color(0xFFFFA500)),
              const SizedBox(width: 2),
              Text(product.rating.toStringAsFixed(1),
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text('(${product.reviewCount})',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textHint)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onAddToCart,
              icon: const Icon(Icons.shopping_cart_outlined, size: 15),
              label: Text('Add to Cart', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'mens_clothing':    return const Color(0xFFFFF3E8);
      case 'womens_clothing':  return const Color(0xFFFFF0F5);
      case 'domestics_home':   return const Color(0xFFEEF5FF);
      default:                 return const Color(0xFFF4F4F2);
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'mens_clothing':    return '👔';
      case 'womens_clothing':  return '👗';
      case 'domestics_home':   return '🏠';
      default:                 return '📦';
    }
  }
}
