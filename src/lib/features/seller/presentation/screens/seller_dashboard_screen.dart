// =============================================================
// FILE: lib/features/seller/presentation/screens/seller_dashboard_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  // Mock seller data — replace with real API later
  final Map<String, dynamic> _sellerStats = {
    'totalSales':    247000.0,
    'totalOrders':   38,
    'totalProducts': 12,
    'rating':        4.8,
    'pendingOrders': 5,
    'thisMonth':     45000.0,
  };

  final List<Map<String, dynamic>> _myProducts = [
    {'id': 1, 'name': 'Classic Oxford Shirt', 'price': 4500.0, 'stock': 42, 'sales': 128, 'status': 'active'},
    {'id': 2, 'name': "Men's Bomber Jacket",   'price': 18000.0, 'stock': 8,  'sales': 52,  'status': 'active'},
    {'id': 3, 'name': 'Slim Fit Chinos',        'price': 9000.0,  'stock': 0,  'sales': 87,  'status': 'out_of_stock'},
    {'id': 4, 'name': 'Premium Polo Shirt',     'price': 5200.0,  'stock': 30, 'sales': 63,  'status': 'active'},
  ];

  final List<Map<String, dynamic>> _myOrders = [
    {'id': '#ORD001', 'customer': 'Chisomo Banda',    'amount': 4500.0,  'status': 'delivered',  'date': 'Jun 10'},
    {'id': '#ORD002', 'customer': 'Tadala Phiri',     'amount': 18000.0, 'status': 'processing', 'date': 'Jun 12'},
    {'id': '#ORD003', 'customer': 'Kondwani Mwale',   'amount': 9000.0,  'status': 'pending',    'date': 'Jun 14'},
    {'id': '#ORD004', 'customer': 'Mphatso Chirwa',   'amount': 5200.0,  'status': 'shipped',    'date': 'Jun 15'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Seller Dashboard',
          style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryRed,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _overviewTab(),
          _productsTab(),
          _ordersTab(),
        ],
      ),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddProductSheet(),
              backgroundColor: AppTheme.primaryRed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Product',
                style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════
  //  OVERVIEW TAB
  // ═══════════════════════════════════════════════
  Widget _overviewTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Seller profile card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF3D0012)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              shape: BoxShape.circle),
            child: const Center(
              child: Text('🏪', style: TextStyle(fontSize: 28)))),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Store',
                style: GoogleFonts.dmSans(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700)),
              Row(children: [
                const Icon(Icons.star, color: Color(0xFFFFA500), size: 14),
                const SizedBox(width: 4),
                Text('${_sellerStats['rating']} Rating',
                  style: GoogleFonts.dmSans(
                    color: Colors.white70, fontSize: 12)),
              ]),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20)),
            child: Text('Active',
              style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700))),
        ]),
      ),
      const SizedBox(height: 20),

      // Stats grid
      Text('This Month', style: GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _statCard('Total Sales', _fmt(_sellerStats['totalSales']),
              Icons.payments_outlined, Colors.green),
          _statCard('Total Orders', '${_sellerStats['totalOrders']}',
              Icons.shopping_bag_outlined, Colors.blue),
          _statCard('Products', '${_sellerStats['totalProducts']}',
              Icons.inventory_2_outlined, Colors.orange),
          _statCard('Pending', '${_sellerStats['pendingOrders']}',
              Icons.pending_outlined, Colors.red),
        ],
      ),
      const SizedBox(height: 20),

      // Quick actions
      Text('Quick Actions', style: GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _actionButton('Add Product', Icons.add_box_outlined,
            () => _showAddProductSheet())),
        const SizedBox(width: 12),
        Expanded(child: _actionButton('View Orders', Icons.list_alt_outlined,
            () => _tabController.animateTo(2))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _actionButton('Manage Stock', Icons.inventory_outlined,
            () => _tabController.animateTo(1))),
        const SizedBox(width: 12),
        Expanded(child: _actionButton('Analytics', Icons.bar_chart_outlined,
            () {})),
      ]),
    ]),
  );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
          const Spacer(),
        ]),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary)),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 11, color: AppTheme.textHint)),
      ]),
    );

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: AppTheme.primaryRed),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary)),
        ]),
      ),
    );

  // ═══════════════════════════════════════════════
  //  PRODUCTS TAB
  // ═══════════════════════════════════════════════
  Widget _productsTab() => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: _myProducts.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, i) {
      final p = _myProducts[i];
      final isOutOfStock = p['status'] == 'out_of_stock';
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor)),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F2),
              borderRadius: BorderRadius.circular(8)),
            child: const Center(
              child: Text('📦', style: TextStyle(fontSize: 28)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['name'],
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(_fmt(p['price']),
                style: GoogleFonts.dmSans(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 4),
              Row(children: [
                _badge(
                  isOutOfStock ? 'Out of Stock' : 'Stock: ${p['stock']}',
                  isOutOfStock ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                _badge('${p['sales']} sold', Colors.blue),
              ]),
            ],
          )),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textHint),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (v) {
              if (v == 'delete') _confirmDelete(p['name']);
            },
          ),
        ]),
      );
    },
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.dmSans(
      color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  // ═══════════════════════════════════════════════
  //  ORDERS TAB
  // ═══════════════════════════════════════════════
  Widget _ordersTab() => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: _myOrders.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, i) {
      final order = _myOrders[i];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor)),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(order['id'],
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(width: 8),
                _statusBadge(order['status']),
              ]),
              const SizedBox(height: 4),
              Text(order['customer'],
                style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary, fontSize: 13)),
              Text(order['date'],
                style: GoogleFonts.dmSans(
                  color: AppTheme.textHint, fontSize: 12)),
            ],
          )),
          Text(_fmt(order['amount']),
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800, fontSize: 15,
              color: AppTheme.primaryRed)),
        ]),
      );
    },
  );

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':    color = Colors.orange; label = 'Pending'; break;
      case 'processing': color = Colors.blue;   label = 'Processing'; break;
      case 'shipped':    color = Colors.purple; label = 'Shipped'; break;
      case 'delivered':  color = Colors.green;  label = 'Delivered'; break;
      default:           color = Colors.grey;   label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.dmSans(
        color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add New Product',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('Use the Admin Dashboard to add products with full details.',
              style: GoogleFonts.dmSans(
                color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              child: Text('Go to Admin Dashboard',
                style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Product?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('Remove "$name" from your listings?',
          style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete',
              style: GoogleFonts.dmSans(color: Colors.white))),
        ],
      ),
    );
  }
}
