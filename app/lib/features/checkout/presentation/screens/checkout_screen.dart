// =============================================================
// FILE: lib/features/checkout/presentation/screens/checkout_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/malawi_cities.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/providers/customer_session_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/format.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Delivery details
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();

  String _paymentMethod = AppConstants.paymentAirtel;
  bool _isLoading = false;
  int _currentStep = 0; // 0=delivery, 1=payment, 2=review

  final List<String> _cities = malawiCities;
  String _selectedCity = 'Lilongwe';

  @override
  void initState() {
    super.initState();
    // Pre-fill delivery details for logged-in customers.
    final customer = ref.read(customerSessionProvider);
    if (customer != null) {
      _nameCtrl.text = customer.name;
      _emailCtrl.text = customer.email;
      _phoneCtrl.text = customer.phone ?? '';
      _addressCtrl.text = customer.address ?? '';
      if (customer.city != null && _cities.contains(customer.city)) {
        _selectedCity = customer.city!;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  String _fmt(double price) => formatMK(price);

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Only IDs, quantities and sizes are sent; the server looks up
      // current prices and works out the total.
      final items = ref.read(cartProvider).map((item) => {
        'productId': item.product.id,
        'quantity':  item.quantity,
        if (item.selectedSize != null) 'size': item.selectedSize,
      }).toList();

      final email = _emailCtrl.text.trim();
      final order = await ApiService().placeOrder(
        customerName:    _nameCtrl.text.trim(),
        customerEmail:   email,
        customerPhone:   _phoneCtrl.text.trim(),
        deliveryAddress: _addressCtrl.text.trim(),
        deliveryCity:    _selectedCity,
        paymentMethod:   _paymentMethod,
        items:           items,
      );

      if (!mounted) return;
      ref.read(cartProvider.notifier).clearCart();
      _showSuccessDialog(
        orderId: order['id'] as int,
        total: (order['totalAmount'] as num).toDouble(),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not place your order: ${e.message}'),
        backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog({required int orderId, required double total}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('Order Placed!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Order #$orderId · ${formatMK(total)}',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryRed,
                fontSize: 16)),
          const SizedBox(height: 4),
          Text(_paymentMethod == AppConstants.paymentCash
              ? 'Your order has been placed. Please have the cash ready on delivery.'
              : 'Your order has been placed. We will contact you on ${_phoneCtrl.text.trim()} to confirm your ${paymentMethodLabel(_paymentMethod)} payment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              final loggedIn = ref.read(customerSessionProvider) != null;
              navigator.popUntil((r) => r.isFirst);
              // Logged-in customers see their order history; guests get
              // the tracking page for this order.
              if (loggedIn) {
                navigator.pushNamed('/orders');
              } else {
                navigator.pushNamed('/tracking', arguments: {
                  'orderId': orderId,
                  'phone': _phoneCtrl.text.trim(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            child: Text('Track My Order',
              style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          // Step indicator
          _stepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                if (_currentStep == 0) _deliveryStep(),
                if (_currentStep == 1) _paymentStep(),
                if (_currentStep == 2) _reviewStep(cartItems, cart),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _bottomBar(cartItems, cart),
    );
  }

  Widget _stepIndicator() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: Row(children: [
      _step(0, 'Delivery'),
      _stepLine(),
      _step(1, 'Payment'),
      _stepLine(),
      _step(2, 'Review'),
    ]),
  );

  Widget _step(int index, String label) => Expanded(
    child: Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentStep >= index ? AppTheme.primaryRed : Colors.grey.shade200),
        child: Center(child: _currentStep > index
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text('${index + 1}',
                style: GoogleFonts.dmSans(
                  color: _currentStep >= index ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w700, fontSize: 13))),
      ),
      const SizedBox(height: 4),
      Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: _currentStep >= index ? AppTheme.primaryRed : Colors.grey,
          fontWeight: _currentStep == index ? FontWeight.w700 : FontWeight.w400)),
    ]),
  );

  Widget _stepLine() => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: _currentStep > 0 ? AppTheme.primaryRed : Colors.grey.shade200),
  );

  // ═══════════════════════════════════════════════
  //  STEP 1 — DELIVERY
  // ═══════════════════════════════════════════════
  Widget _deliveryStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Delivery Details'),
      const SizedBox(height: 16),
      _field(_nameCtrl, 'Full Name', Icons.person_outlined,
        validator: (v) => v!.isEmpty ? 'Enter your full name' : null),
      const SizedBox(height: 12),
      _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter your phone number';
          if (!RegExp(r'^(\+?265|0)\d{8,9}$').hasMatch(v.trim())) {
            return 'Enter a valid Malawi number, e.g. 0881234567';
          }
          return null;
        }),
      const SizedBox(height: 12),
      _field(_emailCtrl, 'Email (optional)', Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (v) => v != null && v.trim().isNotEmpty &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
            ? 'Enter a valid email or leave it empty'
            : null),
      const SizedBox(height: 12),
      _field(_addressCtrl, 'Delivery Address', Icons.location_on_outlined,
        validator: (v) => v!.isEmpty ? 'Enter your address' : null),
      const SizedBox(height: 12),
      // City dropdown
      Text('City', style: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F2),
          borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCity,
            isExpanded: true,
            style: GoogleFonts.dmSans(
              color: AppTheme.textPrimary, fontSize: 14),
            items: _cities.map((c) =>
              DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCity = v!),
          ),
        ),
      ),
    ],
  );

  // ═══════════════════════════════════════════════
  //  STEP 2 — PAYMENT
  // ═══════════════════════════════════════════════
  Widget _paymentStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Payment Method'),
      const SizedBox(height: 16),
      RadioGroup<String>(
        groupValue: _paymentMethod,
        onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
        child: Column(children: [
          for (final item in [
            ('airtel_money', 'Airtel Money', '📱', 'Pay with Airtel Money'),
            ('tnm_mpamba',   'TNM Mpamba',   '📲', 'Pay with TNM Mpamba'),
            ('cash',         'Cash on Delivery', '💵', 'Pay when you receive'),
          ]) _paymentOption(item.$1, item.$2, item.$3, item.$4),
        ]),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200)),
        child: Row(children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'After you place the order, the store confirms your payment and delivery by phone.',
            style: GoogleFonts.dmSans(
              fontSize: 12, color: Colors.blue.shade700))),
        ]),
      ),
    ],
  );

  Widget _paymentOption(String value, String label, String emoji, String desc) =>
    GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _paymentMethod == value
                ? AppTheme.primaryRed : AppTheme.borderColor,
            width: _paymentMethod == value ? 2 : 1)),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 14)),
              Text(desc, style: GoogleFonts.dmSans(
                fontSize: 12, color: AppTheme.textHint)),
            ],
          )),
          Radio<String>(
            value: value,
            activeColor: AppTheme.primaryRed,
          ),
        ]),
      ),
    );

  // ═══════════════════════════════════════════════
  //  STEP 3 — REVIEW
  // ═══════════════════════════════════════════════
  Widget _reviewStep(List<CartItem> cartItems, CartNotifier cart) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('Order Review'),
      const SizedBox(height: 16),

      // Delivery summary
      _summaryCard('Delivery Details', [
        ('Name', _nameCtrl.text),
        ('Phone', _phoneCtrl.text),
        ('Address', _addressCtrl.text),
        ('City', _selectedCity),
      ]),
      const SizedBox(height: 12),

      // Payment summary
      _summaryCard('Payment Method', [
        ('Method', _paymentMethod == 'airtel_money' ? 'Airtel Money'
            : _paymentMethod == 'tnm_mpamba' ? 'TNM Mpamba' : 'Cash on Delivery'),
      ]),
      const SizedBox(height: 12),

      // Items
      _sectionTitle('Items (${cartItems.length})'),
      const SizedBox(height: 8),
      ...cartItems.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor)),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F2),
              borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('📦',
              style: TextStyle(fontSize: 24)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600, fontSize: 13)),
              if (item.selectedSize != null)
                Text('Size: ${item.selectedSize}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppTheme.textHint)),
              Text('Qty: ${item.quantity}',
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppTheme.textHint)),
            ],
          )),
          Text(_fmt(item.totalPrice),
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
        ]),
      )),
      const SizedBox(height: 12),

      // Total
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor)),
        child: Column(children: [
          _totalRow('Subtotal', _fmt(cart.subtotal)),
          const SizedBox(height: 8),
          _totalRow('Delivery', _fmt(cart.deliveryFee)),
          const Divider(height: 16),
          _totalRow('Total', _fmt(cart.total), isTotal: true),
        ]),
      ),
    ],
  );

  Widget _summaryCard(String title, List<(String, String)> items) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.dmSans(
        fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 8),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Text('${item.$1}: ', style: GoogleFonts.dmSans(
            fontSize: 13, color: AppTheme.textHint)),
          Text(item.$2, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      )),
    ]),
  );

  Widget _totalRow(String label, String value, {bool isTotal = false}) =>
    Row(children: [
      Text(label, style: GoogleFonts.dmSans(
        fontSize: isTotal ? 15 : 13,
        fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
        color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary)),
      const Spacer(),
      Text(value, style: GoogleFonts.dmSans(
        fontSize: isTotal ? 16 : 13,
        fontWeight: FontWeight.w700,
        color: isTotal ? AppTheme.primaryRed : AppTheme.textPrimary)),
    ]);

  Widget _bottomBar(List<CartItem> cartItems, CartNotifier cart) => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(
        color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
    child: Row(children: [
      if (_currentStep > 0)
        OutlinedButton(
          onPressed: () => setState(() => _currentStep--),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryRed),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14)),
          child: Text('Back', style: GoogleFonts.dmSans(
            color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
        ),
      if (_currentStep > 0) const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: _isLoading ? null : () {
            if (_currentStep < 2) {
              if (_currentStep == 0) {
                if (_formKey.currentState!.validate()) {
                  setState(() => _currentStep++);
                }
              } else {
                setState(() => _currentStep++);
              }
            } else {
              _placeOrder();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
              : Text(
                  _currentStep == 2 ? 'Place Order' : 'Continue',
                  style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w700,
                    fontSize: 15)),
        ),
      ),
    ]),
  );

  Widget _sectionTitle(String title) => Text(title,
    style: GoogleFonts.playfairDisplay(
      fontSize: 18, fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary));

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textHint),
      filled: true,
      fillColor: const Color(0xFFF4F4F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.primaryRed, width: 1.5))),
    validator: validator,
  );
}
