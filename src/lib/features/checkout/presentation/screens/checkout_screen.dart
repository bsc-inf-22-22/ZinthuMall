// =============================================================
// FILE: lib/features/checkout/presentation/screens/checkout_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/cart_provider.dart';

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

  String _paymentMethod = 'airtel_money';
  bool _isLoading = false;
  int _currentStep = 0; // 0=delivery, 1=payment, 2=review

  final List<String> _cities = [
    'Lilongwe', 'Blantyre', 'Mzuzu', 'Zomba',
    'Kasungu', 'Mangochi', 'Karonga', 'Salima',
  ];
  String _selectedCity = 'Lilongwe';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    return s.length > 3
        ? 'MK ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
        : 'MK $s';
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // TODO: Connect to backend POST /api/orders
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      ref.read(cartProvider.notifier).clearCart();
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order failed: $e'),
        backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
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
          Text('Your order has been placed successfully. We will contact you shortly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            child: Text('Back to Home',
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
        validator: (v) => v!.isEmpty ? 'Enter your phone number' : null),
      const SizedBox(height: 12),
      _field(_emailCtrl, 'Email (optional)', Icons.email_outlined,
        keyboardType: TextInputType.emailAddress),
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
      ...[
        ('airtel_money', 'Airtel Money', '📱', 'Pay with Airtel Money'),
        ('tnm_mpamba',   'TNM Mpamba',   '📲', 'Pay with TNM Mpamba'),
        ('cash',         'Cash on Delivery', '💵', 'Pay when you receive'),
      ].map((item) => _paymentOption(item.$1, item.$2, item.$3, item.$4)),
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
            'Your payment details are secure and encrypted.',
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
            groupValue: _paymentMethod,
            activeColor: AppTheme.primaryRed,
            onChanged: (v) => setState(() => _paymentMethod = v!),
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
            child: Center(child: Text('📦',
              style: const TextStyle(fontSize: 24)))),
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
