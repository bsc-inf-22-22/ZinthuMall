// =============================================================
// FILE: lib/features/product/presentation/screens/product_detail_screen.dart
// FIXED: createState returns ConsumerState correctly
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../home/data/models/product_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late ProductModel _product;
  bool _isWishlisted = false;
  String? _selectedSize;
  int _quantity = 1;
  bool _addedToCart = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product.sizes.isNotEmpty) _selectedSize = _product.sizes.first;
    _loadFreshData();
  }

  Future<void> _loadFreshData() async {
    try {
      final fresh = await ApiService().getProductById(_product.id.toString());
      final updated = ProductModel.fromJson(fresh);
      if (mounted) setState(() => _product = updated);
    } catch (_) {}
  }

  void _addToCart() {
    if (_product.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a size first'),
            backgroundColor: Colors.orange));
      return;
    }
    ref.read(cartProvider.notifier).addItem(
        _product, size: _selectedSize, quantity: _quantity);
    setState(() => _addedToCart = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${_product.name} added to cart ✓'),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_product.name,
            style: GoogleFonts.dmSans(
                color: Colors.black, fontSize: 15,
                fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: _isWishlisted ? AppTheme.primaryRed : Colors.black54),
            onPressed: () => setState(() => _isWishlisted = !_isWishlisted),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black54),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: isMobile ? _mobileLayout() : _desktopLayout(),
      bottomNavigationBar: isMobile ? _bottomBar() : null,
    );
  }

  Widget _mobileLayout() => SingleChildScrollView(
    child: Column(children: [
      _imageSection(),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _priceRow(),
          const SizedBox(height: 8),
          _titleAndSeller(),
          const SizedBox(height: 12),
          _ratingRow(),
          const SizedBox(height: 16),
          _stockBadge(),
          const SizedBox(height: 16),
          if (_product.sizes.isNotEmpty) ...[_sizeSelector(), const SizedBox(height: 16)],
          _quantitySelector(),
          const SizedBox(height: 16),
          if (_product.description != null && _product.description!.isNotEmpty)
            ...[_descriptionSection(), const SizedBox(height: 16)],
          _deliveryInfo(),
          const SizedBox(height: 100),
        ]),
      ),
    ]),
  );

  Widget _desktopLayout() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: _imageSection()),
          const SizedBox(width: 40),
          Expanded(flex: 6, child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _priceRow(),
              const SizedBox(height: 8),
              _titleAndSeller(),
              const SizedBox(height: 12),
              _ratingRow(),
              const SizedBox(height: 16),
              _stockBadge(),
              const SizedBox(height: 16),
              if (_product.sizes.isNotEmpty)
                ...[_sizeSelector(), const SizedBox(height: 16)],
              _quantitySelector(),
              const SizedBox(height: 24),
              _desktopButtons(),
              const SizedBox(height: 24),
              if (_product.description != null && _product.description!.isNotEmpty)
                ...[_descriptionSection(), const SizedBox(height: 16)],
              _deliveryInfo(),
            ]),
          )),
        ]),
      ),
    ),
  );

  Widget _imageSection() => Container(
    height: 320, width: double.infinity,
    color: _getCategoryColor(_product.category),
    child: Stack(children: [
      Center(
        child: _product.imageUrl != null && _product.imageUrl!.isNotEmpty
            ? Image.network(_product.imageUrl!, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  _getCategoryEmoji(_product.category),
                  style: const TextStyle(fontSize: 120)))
            : Text(_getCategoryEmoji(_product.category),
                style: const TextStyle(fontSize: 120)),
      ),
      if (_product.hasDiscount)
        Positioned(top: 16, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(40)),
            child: Text('-${_product.discount}%',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          )),
    ]),
  );

  Widget _priceRow() => Row(children: [
    Text(_product.formattedPrice,
        style: GoogleFonts.dmSans(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: AppTheme.primaryRed)),
    if (_product.hasDiscount) ...[
      const SizedBox(width: 10),
      Text('MK ${_product.originalPrice!.toStringAsFixed(0)}',
          style: GoogleFonts.dmSans(
              fontSize: 15, color: AppTheme.textHint,
              decoration: TextDecoration.lineThrough)),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200)),
        child: Text('Save MK ${_product.savingsAmount.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
                color: Colors.green.shade700, fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    ],
  ]);

  Widget _titleAndSeller() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_product.name,
          style: GoogleFonts.playfairDisplay(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.storefront_outlined, size: 14, color: AppTheme.textHint),
        const SizedBox(width: 4),
        Text('Sold by ${_product.sellerName}',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textHint)),
      ]),
    ],
  );

  Widget _ratingRow() => Row(children: [
    ...List.generate(5, (i) => Icon(
      i < _product.rating.floor() ? Icons.star : Icons.star_border,
      size: 18, color: const Color(0xFFFFA500))),
    const SizedBox(width: 6),
    Text(_product.rating.toStringAsFixed(1),
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
    const SizedBox(width: 4),
    Text('(${_product.reviewCount} reviews)',
        style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 13)),
  ]);

  Widget _stockBadge() {
    final stock = _product.stock;
    Color color;
    String label;
    if (stock == 0) { color = Colors.red; label = 'Out of Stock'; }
    else if (stock < 5) { color = Colors.orange; label = 'Only $stock left!'; }
    else { color = Colors.green; label = 'In Stock ($stock available)'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.dmSans(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _sizeSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Select Size',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: _product.sizes.map((size) {
          final selected = _selectedSize == size;
          return GestureDetector(
            onTap: () => setState(() => _selectedSize = size),
            child: Container(
              width: 48, height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryRed : Colors.white,
                border: Border.all(
                    color: selected ? AppTheme.primaryRed : AppTheme.borderColor,
                    width: selected ? 2 : 1),
                borderRadius: BorderRadius.circular(8)),
              child: Text(size,
                  style: GoogleFonts.dmSans(
                      color: selected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          );
        }).toList()),
    ],
  );

  Widget _quantitySelector() => Row(children: [
    Text('Quantity',
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
    const SizedBox(width: 16),
    Container(
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
          icon: const Icon(Icons.remove, size: 18),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$_quantity',
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w700))),
        IconButton(
          onPressed: () {
            if (_quantity < _product.stock) setState(() => _quantity++);
          },
          icon: const Icon(Icons.add, size: 18),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints()),
      ]),
    ),
  ]);

  Widget _descriptionSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Description',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor)),
        child: Text(_product.description!,
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
      ),
    ],
  );

  Widget _deliveryInfo() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor)),
    child: Column(children: [
      _infoRow(Icons.local_shipping_outlined, 'Delivery',
          'Lilongwe: 1-2 days · Other regions: 3-5 days'),
      const Divider(height: 16),
      _infoRow(Icons.replay_outlined, 'Returns',
          'Free returns within 7 days'),
      const Divider(height: 16),
      _infoRow(Icons.payment_outlined, 'Payment',
          'Airtel Money · TNM Mpamba · Cash on Delivery'),
    ]),
  );

  Widget _infoRow(IconData icon, String title, String detail) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: AppTheme.primaryRed),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, fontSize: 13)),
        Text(detail, style: GoogleFonts.dmSans(
            fontSize: 12, color: AppTheme.textHint)),
      ])),
    ]);

  Widget _bottomBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(10)),
        child: IconButton(
          icon: Icon(
            _isWishlisted ? Icons.favorite : Icons.favorite_border,
            color: _isWishlisted ? AppTheme.primaryRed : AppTheme.textHint),
          onPressed: () => setState(() => _isWishlisted = !_isWishlisted),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: SizedBox(height: 48, child: ElevatedButton.icon(
        onPressed: _product.stock > 0 ? _addToCart : null,
        icon: Icon(_addedToCart ? Icons.check : Icons.shopping_cart_outlined, size: 18),
        label: Text(
          _addedToCart ? 'Added to Cart!' :
          _product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
            backgroundColor: _addedToCart ? Colors.green : AppTheme.primaryRed,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
      ))),
    ]),
  );

  Widget _desktopButtons() => Row(children: [
    Expanded(child: SizedBox(height: 52, child: ElevatedButton.icon(
      onPressed: _product.stock > 0 ? _addToCart : null,
      icon: Icon(_addedToCart ? Icons.check : Icons.shopping_cart_outlined, size: 20),
      label: Text(
        _addedToCart ? 'Added to Cart!' :
        _product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
      style: ElevatedButton.styleFrom(
          backgroundColor: _addedToCart ? Colors.green : AppTheme.primaryRed,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
    ))),
    const SizedBox(width: 12),
    Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(10)),
      child: IconButton(
        icon: Icon(
          _isWishlisted ? Icons.favorite : Icons.favorite_border,
          color: _isWishlisted ? AppTheme.primaryRed : AppTheme.textHint),
        onPressed: () => setState(() => _isWishlisted = !_isWishlisted),
      ),
    ),
  ]);

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'mens_clothing':   return const Color(0xFFFFF3E8);
      case 'womens_clothing': return const Color(0xFFFFF0F5);
      case 'domestics_home':  return const Color(0xFFEEF5FF);
      default:                return const Color(0xFFF4F4F2);
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'mens_clothing':   return '👔';
      case 'womens_clothing': return '👗';
      case 'domestics_home':  return '🏠';
      default:                return '📦';
    }
  }
}
