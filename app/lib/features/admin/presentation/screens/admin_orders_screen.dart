// =============================================================
// FILE: lib/features/admin/presentation/screens/admin_orders_screen.dart
//
// Store owner's order management:
//   - list orders, filtered by status
//   - move an order through processing → shipped → delivered
//   - cancel an order (stock is returned automatically)
//   - record a mobile-money payment and its transaction ID
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/products_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/async_states.dart';
import '../../../orders/presentation/screens/order_history_screen.dart' show StatusChip;

final _statusFilterProvider = StateProvider.autoDispose<String?>((ref) => 'pending');

final adminOrdersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final status = ref.watch(_statusFilterProvider);
  return ref.read(apiServiceProvider).getAdminOrders(status: status);
});

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  static const _filters = <(String, String?)>[
    ('New', 'pending'),
    ('Processing', 'processing'),
    ('Shipped', 'shipped'),
    ('Delivered', 'delivered'),
    ('Cancelled', 'cancelled'),
    ('All', null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_statusFilterProvider);
    final orders = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Orders', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminOrdersProvider),
          ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final f in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$1),
                    selected: filter == f.$2,
                    selectedColor: AppTheme.primaryRed.withValues(alpha: 0.12),
                    labelStyle: GoogleFonts.dmSans(
                      color: filter == f.$2 ? AppTheme.primaryRed : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => ref.read(_statusFilterProvider.notifier).state = f.$2,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: orders.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(adminOrdersProvider)),
            data: (list) => list.isEmpty
                ? const EmptyView(emoji: '📭', title: 'No orders here')
                : RefreshIndicator(
                    color: AppTheme.primaryRed,
                    onRefresh: () => ref.refresh(adminOrdersProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _AdminOrderTile(order: list[i]),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _AdminOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _AdminOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(order['items'] as List);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _OrderDetailSheet(order: order),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#${order['id']} · ${order['customerName']}',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${order['deliveryCity']} · ${items.length} item${items.length == 1 ? '' : 's'} · ${formatDate(order['createdAt'] as String?)}',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textHint)),
                const SizedBox(height: 2),
                Text('${paymentMethodLabel(order['paymentMethod'] as String?)} · ${statusLabel(order['paymentStatus'] as String)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: order['paymentStatus'] == 'paid' ? AppTheme.successGreen : AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatMK(order['totalAmount'] as num),
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: AppTheme.primaryRed)),
              const SizedBox(height: 6),
              StatusChip(status: order['status'] as String),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _OrderDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  const _OrderDetailSheet({required this.order});

  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  late Map<String, dynamic> _order = widget.order;
  bool _busy = false;

  static const _next = {
    'pending': ('processing', 'Start Processing'),
    'processing': ('shipped', 'Mark as Shipped'),
    'shipped': ('delivered', 'Mark as Delivered'),
  };

  Future<void> _run(Future<Map<String, dynamic>> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      final updated = await action();
      setState(() => _order = updated);
      ref.invalidate(adminOrdersProvider);
      ref.read(productsProvider.notifier).refresh(); // stock may have changed
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordPayment() async {
    final txCtrl = TextEditingController(text: _order['transactionId'] as String? ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment received'),
        content: TextField(
          controller: txCtrl,
          decoration: InputDecoration(
            labelText: _order['paymentMethod'] == 'cash' ? 'Note (optional)' : 'Transaction ID',
            hintText: _order['paymentMethod'] == 'cash' ? 'e.g. Paid to driver' : 'e.g. CI241124.1530.A12345',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark as Paid')),
        ],
      ),
    );
    final transactionId = txCtrl.text.trim();
    txCtrl.dispose();
    if (confirmed != true) return;
    final id = _order['id'] as int;
    await _run(
      () => ref.read(apiServiceProvider).updateOrderPayment(id, 'paid', transactionId: transactionId),
      'Payment recorded',
    );
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('The items will be put back in stock. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep order')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = _order['id'] as int;
    await _run(() => ref.read(apiServiceProvider).updateOrderStatus(id, 'cancelled'), 'Order cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] as String;
    final next = _next[status];
    final items = List<Map<String, dynamic>>.from(_order['items'] as List);
    final paid = _order['paymentStatus'] == 'paid';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(controller: controller, padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Text('Order #${_order['id']}', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          StatusChip(status: status),
        ]),
        Text(formatDate(_order['createdAt'] as String?), style: GoogleFonts.dmSans(color: AppTheme.textHint)),
        const Divider(height: 28),
        _section('Customer'),
        _line(Icons.person_outline, _order['customerName'] as String),
        _line(Icons.phone_outlined, _order['customerPhone'] as String),
        if (_order['customerEmail'] != null) _line(Icons.email_outlined, _order['customerEmail'] as String),
        _line(Icons.location_on_outlined, '${_order['deliveryAddress']}, ${_order['deliveryCity']}'),
        const Divider(height: 28),
        _section('Items'),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(
                child: Text('${item['quantity']} × ${item['productName']}${item['size'] != null ? ' (${item['size']})' : ''}',
                    style: GoogleFonts.dmSans()),
              ),
              Text(formatMK(item['subtotal'] as num), style: GoogleFonts.dmSans()),
            ]),
          ),
        const SizedBox(height: 6),
        _total('Subtotal', _order['subtotal'] as num),
        _total('Delivery', _order['deliveryFee'] as num),
        _total('Total', _order['totalAmount'] as num, bold: true),
        const Divider(height: 28),
        _section('Payment'),
        _line(Icons.payments_outlined,
            '${paymentMethodLabel(_order['paymentMethod'] as String?)} · ${statusLabel(_order['paymentStatus'] as String)}'),
        if ((_order['transactionId'] as String?)?.isNotEmpty ?? false)
          _line(Icons.tag, 'Ref: ${_order['transactionId']}'),
        const SizedBox(height: 20),
        if (_busy) const LoadingView(),
        if (!_busy && status != 'cancelled') ...[
          if (!paid)
            OutlinedButton.icon(
              onPressed: _recordPayment,
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
              label: Text('Record Payment', style: GoogleFonts.dmSans(color: AppTheme.successGreen, fontWeight: FontWeight.w700)),
            ),
          if (next != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _run(
                () => ref.read(apiServiceProvider).updateOrderStatus(_order['id'] as int, next.$1),
                'Order updated',
              ),
              child: Text(next.$2),
            ),
          ],
          if (status != 'delivered') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _cancel,
              child: Text('Cancel Order', style: GoogleFonts.dmSans(color: Colors.red)),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(),
            style: GoogleFonts.dmSans(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppTheme.textHint)),
      );

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(text, style: GoogleFonts.dmSans())),
        ]),
      );

  Widget _total(String label, num value, {bool bold = false}) => Row(children: [
        Text(label, style: GoogleFonts.dmSans(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        const Spacer(),
        Text(formatMK(value),
            style: GoogleFonts.dmSans(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400, color: bold ? AppTheme.primaryRed : null)),
      ]);
}
