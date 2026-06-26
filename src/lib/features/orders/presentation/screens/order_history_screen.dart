// =============================================================
// FILE: lib/features/orders/presentation/screens/order_history_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#KAC001', 'date': 'Jun 15, 2026', 'total': 4500.0,
      'status': 'delivered', 'paymentMethod': 'Airtel Money',
      'items': [
        {'name': 'Classic Oxford Shirt', 'qty': 1, 'price': 4500.0, 'size': 'M'},
      ],
      'deliveryAddress': 'Area 47, Lilongwe',
    },
    {
      'id': '#KAC002', 'date': 'Jun 18, 2026', 'total': 27000.0,
      'status': 'shipped', 'paymentMethod': 'TNM Mpamba',
      'items': [
        {'name': "Men's Bomber Jacket", 'qty': 1, 'price': 18000.0, 'size': 'L'},
        {'name': 'Slim Fit Chinos',     'qty': 1, 'price': 9000.0,  'size': '32'},
      ],
      'deliveryAddress': 'Blantyre CBD',
    },
    {
      'id': '#KAC003', 'date': 'Jun 20, 2026', 'total': 5200.0,
      'status': 'processing', 'paymentMethod': 'Cash on Delivery',
      'items': [
        {'name': 'Premium Polo Shirt', 'qty': 1, 'price': 5200.0, 'size': 'S'},
      ],
      'deliveryAddress': 'Mzuzu City',
    },
    {
      'id': '#KAC004', 'date': 'Jun 22, 2026', 'total': 6800.0,
      'status': 'pending', 'paymentMethod': 'Airtel Money',
      'items': [
        {'name': 'Graphic Tee Bundle', 'qty': 2, 'price': 3400.0, 'size': 'M'},
      ],
      'deliveryAddress': 'Area 18, Lilongwe',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    return s.length > 3
        ? 'MK ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
        : 'MK $s';
  }

  List<Map<String, dynamic>> _filteredOrders(String status) {
    if (status == 'all') return _orders;
    return _orders.where((o) => o['status'] == status).toList();
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
        title: Text('My Orders',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16,
            fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: AppTheme.primaryRed,
          isScrollable: true,
          labelStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Processing'),
            Tab(text: 'Shipped'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _orderList(_filteredOrders('all')),
          _orderList(_filteredOrders('processing')),
          _orderList(_filteredOrders('shipped')),
          _orderList(_filteredOrders('delivered')),
        ],
      ),
    );
  }

  Widget _orderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📦', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No orders here',
            style: GoogleFonts.dmSans(
              fontSize: 16, color: AppTheme.textHint)),
        ],
      ));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _orderCard(orders[i]),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final items = order['items'] as List;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor)),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order['id'],
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(order['date'],
                style: GoogleFonts.dmSans(
                  color: AppTheme.textHint, fontSize: 12)),
            ]),
            const Spacer(),
            _statusBadge(order['status']),
          ]),
        ),
        const Divider(height: 1),

        // Items
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F2),
                borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Text('📦', style: TextStyle(fontSize: 22)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'],
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 13)),
                Text('Size: ${item['size']} · Qty: ${item['qty']}',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textHint, fontSize: 12)),
              ],
            )),
            Text(_fmt(item['price'] * item['qty']),
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryRed)),
          ]),
        )),

        const Divider(height: 1),

        // Footer
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total: ${_fmt(order['total'])}',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800, fontSize: 15,
                  color: AppTheme.textPrimary)),
              Text(order['paymentMethod'],
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textHint)),
            ]),
            const Spacer(),
            if (order['status'] == 'shipped' ||
                order['status'] == 'processing')
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/tracking',
                      arguments: order['id']),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8)),
                child: Text('Track',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 12))),
            if (order['status'] == 'delivered')
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/reviews'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8)),
                child: Text('Review',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12))),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'pending':
        color = Colors.orange; label = 'Pending';
        icon = Icons.hourglass_empty; break;
      case 'processing':
        color = Colors.blue; label = 'Processing';
        icon = Icons.settings; break;
      case 'shipped':
        color = Colors.purple; label = 'Shipped';
        icon = Icons.local_shipping_outlined; break;
      case 'delivered':
        color = Colors.green; label = 'Delivered';
        icon = Icons.check_circle_outline; break;
      default:
        color = Colors.grey; label = status;
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(
          color: color, fontSize: 11,
          fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
