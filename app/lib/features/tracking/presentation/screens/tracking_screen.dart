// =============================================================
// FILE: lib/features/tracking/presentation/screens/tracking_screen.dart
//
// Public order tracking. Works for guests: the customer enters
// their order number and the phone number used at checkout.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/async_states.dart';
import '../../../orders/presentation/screens/order_history_screen.dart' show StatusChip;

class TrackingScreen extends StatefulWidget {
  final int? orderId;
  final String? phone;
  const TrackingScreen({super.key, this.orderId, this.phone});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _orderCtrl = TextEditingController(text: widget.orderId?.toString() ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.phone ?? '');

  Map<String, dynamic>? _order;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null && (widget.phone ?? '').isNotEmpty) _track();
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final id = int.tryParse(_orderCtrl.text.trim().replaceAll('#', ''));
    if (id == null || _phoneCtrl.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final order = await ApiService().trackOrder(id, _phoneCtrl.text.trim());
      setState(() => _order = order);
    } on ApiException catch (e) {
      setState(() { _order = null; _error = e.message; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Track My Order',
            style: GoogleFonts.dmSans(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _lookupForm(),
            const SizedBox(height: 16),
            if (_loading) const LoadingView(),
            if (_error != null && !_loading)
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: Colors.red)),
            if (_order != null && !_loading) _OrderProgress(order: _order!),
          ]),
        ),
      ),
    );
  }

  Widget _lookupForm() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Enter your order number and the phone number you used at checkout.',
                style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Order number, e.g. 1024', prefixIcon: Icon(Icons.tag)),
              validator: (v) => int.tryParse((v ?? '').replaceAll('#', '').trim()) == null ? 'Enter your order number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your phone number' : null,
              onFieldSubmitted: (_) => _track(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loading ? null : _track, child: const Text('Track Order')),
          ]),
        ),
      );
}

class _OrderProgress extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderProgress({required this.order});

  static const _steps = [
    ('pending', 'Order Placed', 'We have received your order'),
    ('processing', 'Preparing', 'Your items are being packed'),
    ('shipped', 'On the Way', 'Your order is out for delivery'),
    ('delivered', 'Delivered', 'Enjoy your purchase!'),
  ];

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final cancelled = status == 'cancelled';
    final current = _steps.indexWhere((s) => s.$1 == status);
    final items = List<Map<String, dynamic>>.from(order['items'] as List);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Order #${order['id']}', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          StatusChip(status: status),
        ]),
        const SizedBox(height: 4),
        Text('Placed ${formatDate(order['createdAt'] as String?)} · Delivery to ${order['deliveryCity']}',
            style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 12)),
        Text('Payment: ${statusLabel(order['paymentStatus'] as String)} · Total ${formatMK(order['totalAmount'] as num)}',
            style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 12)),
        const SizedBox(height: 20),
        if (cancelled)
          Text('This order was cancelled. If you have questions, please contact us.',
              style: GoogleFonts.dmSans(color: Colors.red))
        else
          for (var i = 0; i < _steps.length; i++)
            _stepRow(_steps[i].$2, _steps[i].$3, done: i <= current, isLast: i == _steps.length - 1),
        const Divider(height: 32),
        for (final item in items)
          Text('${item['quantity']} × ${item['productName']}${item['size'] != null ? ' (${item['size']})' : ''}',
              style: GoogleFonts.dmSans(fontSize: 13)),
      ]),
    );
  }

  Widget _stepRow(String title, String subtitle, {required bool done, required bool isLast}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppTheme.primaryRed : Colors.grey.shade200,
              ),
              child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            if (!isLast) Container(width: 2, height: 36, color: done ? AppTheme.primaryRed : Colors.grey.shade200),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, color: done ? AppTheme.textPrimary : AppTheme.textHint)),
              Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textHint)),
            ]),
          ),
        ],
      );
}
