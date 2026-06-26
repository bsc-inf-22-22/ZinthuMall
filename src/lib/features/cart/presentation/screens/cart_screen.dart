// =============================================================
// FILE: lib/features/cart/presentation/screens/cart_screen.dart
//
// Shows all items in the cart with quantity controls,
// order summary, and a proceed to checkout button.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    return s.length > 3
        ? 'MK ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
        : 'MK $s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cart      = ref.read(cartProvider.notifier);
    final isMobile  = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Cart (${cart.itemCount})',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text('Clear All',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _emptyCart(context)
          : LayoutBuilder(
              builder: (ctx, constraints) {
                final isDesktop = constraints.maxWidth > 700;
                return isDesktop
                    ? _desktopLayout(context, ref, cartItems, cart)
                    : _mobileLayout(context, ref, cartItems, cart);
              },
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMPTY CART
  // ═══════════════════════════════════════════════════════════════
  Widget _emptyCart(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🛒', style: TextStyle(fontSize: 80)),
      const SizedBox(height: 16),
      Text('Your cart is empty',
        style: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      Text('Add some products to get started!',
        style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 14)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context, '/home', (route) => false),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Text('Continue Shopping',
          style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    ]),
  );

  // ═══════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _mobileLayout(BuildContext context, WidgetRef ref,
      List<CartItem> cartItems, CartNotifier cart) =>
    Column(children: [
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cartItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _cartItemCard(context, ref, cartItems[i], cart),
        ),
      ),
      _orderSummary(context, cart),
    ]);

  // ═══════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _desktopLayout(BuildContext context, WidgetRef ref,
      List<CartItem> cartItems, CartNotifier cart) =>
    Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left — cart items
            Expanded(
              flex: 6,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _cartItemCard(context, ref, cartItems[i], cart),
              ),
            ),
            const SizedBox(width: 24),
            // Right — order summary
            SizedBox(width: 320, child: _orderSummary(context, cart)),
          ]),
        ),
      ),
    );

  // ═══════════════════════════════════════════════════════════════
  //  CART ITEM CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _cartItemCard(BuildContext context, WidgetRef ref,
      CartItem item, CartNotifier cart) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Product image/emoji
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F2),
            borderRadius: BorderRadius.circular(8)),
          child: Center(child: item.product.imageUrl != null &&
              item.product.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item.product.imageUrl!,
                    fit: BoxFit.cover, width: 80, height: 80,
                    errorBuilder: (_, __, ___) =>
                        Text(_getEmoji(item.product.category),
                          style: const TextStyle(fontSize: 36))))
              : Text(_getEmoji(item.product.category),
                  style: const TextStyle(fontSize: 36))),
        ),
        const SizedBox(width: 12),
        // Product info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 14,
                color: AppTheme.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('by ${item.product.sellerName}',
              style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textHint)),
            if (item.selectedSize != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F2),
                  borderRadius: BorderRadius.circular(4)),
                child: Text('Size: ${item.selectedSize}',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Text(_fmt(item.product.price),
                style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppTheme.primaryRed)),
              const Spacer(),
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: () => cart.decreaseQuantity(
                        item.product.id, item.selectedSize),
                    child: Container(
                      width: 30, height: 30,
                      alignment: Alignment.center,
                      child: const Icon(Icons.remove, size: 16)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.quantity}',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  GestureDetector(
                    onTap: () => cart.increaseQuantity(
                        item.product.id, item.selectedSize),
                    child: Container(
                      width: 30, height: 30,
                      alignment: Alignment.center,
                      child: const Icon(Icons.add, size: 16)),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Total: ${_fmt(item.totalPrice)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        // Remove button
        GestureDetector(
          onTap: () => cart.removeItem(item.product.id, item.selectedSize),
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.close, size: 18, color: AppTheme.textHint)),
        ),
      ]),
    );

  // ═══════════════════════════════════════════════════════════════
  //  ORDER SUMMARY
  // ═══════════════════════════════════════════════════════════════
  Widget _orderSummary(BuildContext context, CartNotifier cart) =>
    Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Summary',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        _summaryRow('Subtotal', _fmt(cart.subtotal)),
        const SizedBox(height: 8),
        _summaryRow('Delivery Fee', _fmt(cart.deliveryFee)),
        const Divider(height: 24),
        _summaryRow('Total', _fmt(cart.total), isTotal: true),
        const SizedBox(height: 16),
        // Promo code
        Row(children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Promo code',
                hintStyle: GoogleFonts.dmSans(fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300))),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
            child: Text('Apply',
              style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        // Checkout button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/checkout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            child: Text('Proceed to Checkout',
              style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
        // Payment methods
        Center(
          child: Text('Airtel Money · TNM Mpamba · Cash on Delivery',
            style: GoogleFonts.dmSans(
              fontSize: 11, color: AppTheme.textHint)),
        ),
      ]),
    );

  Widget _summaryRow(String label, String value, {bool isTotal = false}) =>
    Row(children: [
      Text(label,
        style: GoogleFonts.dmSans(
          fontSize: isTotal ? 15 : 13,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary)),
      const Spacer(),
      Text(value,
        style: GoogleFonts.dmSans(
          fontSize: isTotal ? 16 : 13,
          fontWeight: FontWeight.w700,
          color: isTotal ? AppTheme.primaryRed : AppTheme.textPrimary)),
    ]);

  String _getEmoji(String category) {
    switch (category) {
      case 'mens_clothing':   return '👔';
      case 'womens_clothing': return '👗';
      case 'domestics_home':  return '🏠';
      default:                return '📦';
    }
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Clear Cart?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('Remove all items from your cart?',
          style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans())),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: Text('Clear', style: GoogleFonts.dmSans(color: Colors.white))),
        ],
      ),
    );
  }
}
