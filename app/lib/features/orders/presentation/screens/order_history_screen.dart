// =============================================================
// FILE: lib/features/orders/presentation/screens/order_history_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/customer_data_providers.dart';
import '../../../../core/providers/customer_session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/async_states.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  static const _tabs = [
    ('All', null),
    ('Active', ['pending', 'processing', 'shipped']),
    ('Delivered', ['delivered']),
    ('Cancelled', ['cancelled']),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(customerSessionProvider) != null;
    final orders = ref.watch(myOrdersProvider);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('My Orders',
              style: GoogleFonts.dmSans(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
          bottom: loggedIn
              ? TabBar(
                  isScrollable: true,
                  labelColor: AppTheme.primaryRed,
                  unselectedLabelColor: AppTheme.textHint,
                  indicatorColor: AppTheme.primaryRed,
                  labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [for (final t in _tabs) Tab(text: t.$1)],
                )
              : null,
        ),
        body: !loggedIn
            ? const SignInPrompt(message: 'Sign in to see your orders.\nPlaced an order as a guest? Use "Track My Order".')
            : orders.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
                data: (all) => TabBarView(children: [
                  for (final t in _tabs)
                    _OrderList(
                      orders: t.$2 == null ? all : all.where((o) => t.$2!.contains(o['status'])).toList(),
                      onRefresh: () => ref.refresh(myOrdersProvider.future),
                    ),
                ]),
              ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Future<void> Function() onRefresh;
  const _OrderList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyView(
        emoji: '📦',
        title: 'No orders here',
        message: 'Orders you place will appear here.',
        actionLabel: 'Start Shopping',
        onAction: () => Navigator.popUntil(context, (r) => r.isFirst),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final items = List<Map<String, dynamic>>.from(order['items'] as List);
    final itemCount = items.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Order #${order['id']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          StatusChip(status: status),
        ]),
        const SizedBox(height: 4),
        Text('${formatDate(order['createdAt'] as String?)} · $itemCount item${itemCount == 1 ? '' : 's'}',
            style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 12)),
        const Divider(height: 24),
        for (final item in items.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${item['quantity']} × ${item['productName']}${item['size'] != null ? ' (${item['size']})' : ''}',
                  style: GoogleFonts.dmSans(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(formatMK(item['subtotal'] as num), style: GoogleFonts.dmSans(fontSize: 13)),
            ]),
          ),
        if (items.length > 3)
          Text('+ ${items.length - 3} more', style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 12)),
        const Divider(height: 24),
        Row(children: [
          Text(paymentMethodLabel(order['paymentMethod'] as String?),
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 12)),
          Text(' · ${statusLabel(order['paymentStatus'] as String)}',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 12)),
          const Spacer(),
          Text(formatMK(order['totalAmount'] as num),
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: AppTheme.primaryRed, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/tracking',
                  arguments: {'orderId': order['id'], 'phone': order['customerPhone']}),
              icon: const Icon(Icons.local_shipping_outlined, size: 18, color: AppTheme.primaryRed),
              label: Text('Track', style: GoogleFonts.dmSans(color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
            ),
          ),
          if (status == 'delivered') ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/reviews', arguments: items),
                icon: const Icon(Icons.star_border, size: 18, color: AppTheme.primaryRed),
                label: Text('Review', style: GoogleFonts.dmSans(color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'delivered' => AppTheme.successGreen,
      'cancelled' => Colors.red,
      'shipped' => Colors.blue,
      'processing' => AppTheme.accentOrange,
      _ => AppTheme.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(statusLabel(status),
          style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
