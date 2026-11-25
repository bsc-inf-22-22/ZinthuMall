// =============================================================
// FILE: lib/features/admin/presentation/screens/admin_dashboard_screen.dart
//
// UPDATED:
//   - Uses AsyncValue to handle loading/error/data states
//   - product.stock instead of product.stockQty
//   - product.discount instead of product.isFlashDeal
//   - addProduct() now calls real API through provider
//   - deleteProduct() now calls real API through provider
//   - Inventory section (stock levels from /api/inventory)
//   - Orders button opens AdminOrdersScreen
//   - Added refresh button to reload from API
// =============================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/products_provider.dart';
import '../../../../core/services/api_service.dart' show ImageUpload;
import '../../../../features/home/data/models/product_model.dart';
import 'admin_login_screen.dart';
import 'admin_orders_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue has 3 states: loading, data, error
    // .when() handles all 3 cleanly
    final asyncProducts = ref.watch(productsProvider);
    final adminName     = ref.watch(adminNameProvider);
    final adminEmail    = ref.watch(adminEmailProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(context, ref, adminName, asyncProducts),
      floatingActionButton: _buildAddButton(context, ref),
      body: asyncProducts.when(
        // --------------------------------------------------
        // LOADING STATE — show spinner while API responds
        // --------------------------------------------------
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryRed),
              SizedBox(height: 16),
              Text('Loading products from server...'),
            ],
          ),
        ),

        // --------------------------------------------------
        // ERROR STATE — show error with retry button
        // --------------------------------------------------
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Could not load products',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.dmSans(
                  color: AppTheme.textHint, fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(productsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),

        // --------------------------------------------------
        // DATA STATE — show the full dashboard
        // --------------------------------------------------
        data: (products) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(adminName, adminEmail, products.length),
              const SizedBox(height: 20),
              _buildStatsRow(products),
              const SizedBox(height: 24),
              _buildInventoryAlert(context, ref, products),
              const SizedBox(height: 20),
              _buildProductListHeader(context, ref, products.length),
              const SizedBox(height: 14),
              products.isEmpty
                  ? _buildEmptyState(context, ref)
                  : _buildProductList(context, ref, products),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // APP BAR
  // ----------------------------------------------------------
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String adminName,
    AsyncValue asyncProducts,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.cardWhite,
      elevation: 0,
      title: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Kachipapa',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppTheme.primaryRed,
                  ),
                ),
                TextSpan(
                  text: 'Store',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppTheme.accentOrange,
                  ),
                ),
                TextSpan(
                  text: '  Admin',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Refresh button — reloads products from API
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'Refresh from server',
            onPressed: () {
              ref.read(productsProvider.notifier).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing products from server...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // Admin avatar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryRed,
                  child: Text('A',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text(
                  adminName.isEmpty ? 'Admin' : adminName,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Orders
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary),
            tooltip: 'Orders',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
            ),
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // GREETING BANNER
  // ----------------------------------------------------------
  Widget _buildGreeting(String name, String email, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF3D0012)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good day, ${name.isEmpty ? 'Admin' : name} 👋',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isNotEmpty ? email : '',
                  style: GoogleFonts.dmSans(
                      color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count products listed on the store',
                  style: GoogleFonts.dmSans(
                      color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          const Text('🏪', style: TextStyle(fontSize: 40)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // STATS ROW
  // ----------------------------------------------------------
  Widget _buildStatsRow(List<ProductModel> products) {
    final mens      = products.where((p) => p.category == 'mens_clothing').length;
    final womens    = products.where((p) => p.category == 'womens_clothing').length;
    final home      = products.where((p) => p.category == 'domestics_home').length;
    final outStock  = products.where((p) => p.stock == 0).length;
    final lowStock  = products.where((p) => p.stock > 0 && p.stock < 5).length;

    final stats = [
      {'label': 'Total',      'value': '${products.length}', 'color': AppTheme.primaryRed,         'emoji': '📦'},
      {'label': "Men's",      'value': '$mens',              'color': const Color(0xFF1565C0),      'emoji': '👔'},
      {'label': "Women's",    'value': '$womens',            'color': const Color(0xFF880E4F),      'emoji': '👗'},
      {'label': 'Home',       'value': '$home',              'color': const Color(0xFF1B5E20),      'emoji': '🏠'},
      {'label': 'Low Stock',  'value': '$lowStock',          'color': AppTheme.accentOrange,        'emoji': '⚠️'},
      {'label': 'Out Stock',  'value': '$outStock',          'color': AppTheme.primaryRed,          'emoji': '❌'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats.map((s) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['emoji'] as String,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  s['value'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: s['color'] as Color,
                  ),
                ),
                Text(
                  s['label'] as String,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppTheme.textHint),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------------
  // INVENTORY ALERT BANNER
  // Shows warning if any products are low/out of stock
  // Connects to Friend 2's inventory data
  // ----------------------------------------------------------
  Widget _buildInventoryAlert(
    BuildContext context,
    WidgetRef ref,
    List<ProductModel> products,
  ) {
    final outOfStock = products.where((p) => p.stock == 0).toList();
    final lowStock   = products.where((p) => p.stock > 0 && p.stock < 5).toList();

    if (outOfStock.isEmpty && lowStock.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: outOfStock.isNotEmpty
            ? const Color(0xFFFFF0F2)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outOfStock.isNotEmpty
              ? AppTheme.primaryRed.withValues(alpha: 0.3)
              : AppTheme.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: outOfStock.isNotEmpty
                    ? AppTheme.primaryRed
                    : AppTheme.accentOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                outOfStock.isNotEmpty
                    ? '${outOfStock.length} product(s) out of stock!'
                    : '${lowStock.length} product(s) running low',
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: outOfStock.isNotEmpty
                      ? AppTheme.primaryRed
                      : AppTheme.accentOrange,
                ),
              ),
            ],
          ),
          if (outOfStock.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...outOfStock.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${p.name} — 0 units left',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppTheme.primaryRed),
                  ),
                )),
          ],
          if (lowStock.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...lowStock.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${p.name} — only ${p.stock} units left',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppTheme.accentOrange),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // PRODUCT LIST HEADER
  // ----------------------------------------------------------
  Widget _buildProductListHeader(
      BuildContext context, WidgetRef ref, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Products ($count)',
          style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontWeight: FontWeight.w700),
        ),
        TextButton.icon(
          onPressed: () => _showAddProductSheet(context, ref),
          icon: const Icon(Icons.add,
              color: AppTheme.primaryRed, size: 18),
          label: Text(
            'Add New',
            style: GoogleFonts.dmSans(
                color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // PRODUCT LIST
  // ----------------------------------------------------------
  Widget _buildProductList(
      BuildContext context, WidgetRef ref, List<ProductModel> products) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductListTile(
          product: product,
          onDelete: () => _confirmDelete(context, ref, product),
          onAddStock: () => _showAddStockDialog(context, ref, product),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // EMPTY STATE
  // ----------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('📦', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No products yet',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tap the + button to add your first product',
              style: GoogleFonts.dmSans(
                  color: AppTheme.textHint, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddProductSheet(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add First Product'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // FLOATING ADD BUTTON
  // ----------------------------------------------------------
  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddProductSheet(context, ref),
      backgroundColor: AppTheme.primaryRed,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text('Add Product',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  // ----------------------------------------------------------
  // ADD PRODUCT BOTTOM SHEET
  // ----------------------------------------------------------
  void _showAddProductSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProductSheet(ref: ref),
    );
  }

  // ----------------------------------------------------------
  // ADD STOCK DIALOG — connects to Friend 2's inventory API
  // POST /inventory/add-stock
  // ----------------------------------------------------------
  void _showAddStockDialog(
      BuildContext context, WidgetRef ref, ProductModel product) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Stock',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Current stock: ${product.stock} units',
                style: GoogleFonts.dmSans(
                    color: AppTheme.textHint, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Units to add',
                hintText: 'e.g. 50',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryRed, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppTheme.textHint)),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text);
              if (qty == null || qty <= 0) return;
              Navigator.pop(ctx);

              try {
                // POST /api/inventory/add-stock (logged in stock history)
                await ref.read(apiServiceProvider).addStock(
                  productId: product.id,
                  quantity:  qty,
                  notes:     'Admin restock',
                );
                await ref.read(productsProvider.notifier).refresh();
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Added $qty units to ${product.name}'),
                  backgroundColor: AppTheme.successGreen,
                ));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Stock update failed: $e'),
                  backgroundColor: AppTheme.primaryRed,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen),
            child: Text('Add Stock',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // CONFIRM DELETE
  // ----------------------------------------------------------
  void _confirmDelete(
      BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Product?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${product.name}" from the store?\n\nThis also removes it from the homepage.',
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppTheme.textHint)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(productsProvider.notifier)
                    .deleteProduct(product.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${product.name} removed from store'),
                  backgroundColor: AppTheme.primaryRed,
                ));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Could not delete: $e'),
                  backgroundColor: AppTheme.primaryRed,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed),
            child: Text('Delete',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // CONFIRM LOGOUT
  // ----------------------------------------------------------
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppTheme.textHint)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(apiServiceProvider).clearAdminToken();
              if (!context.mounted || !ctx.mounted) return;
              ref.read(adminAuthProvider.notifier).state  = false;
              ref.read(adminNameProvider.notifier).state  = '';
              ref.read(adminEmailProvider.notifier).state = '';
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminLoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed),
            child: Text('Logout',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// PRODUCT LIST TILE
// ===========================================================
class _ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onDelete;
  final VoidCallback onAddStock;

  const _ProductListTile({
    required this.product,
    required this.onDelete,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.stock == 0
              ? AppTheme.primaryRed.withValues(alpha: 0.3)
              : product.stock < 5
                  ? AppTheme.accentOrange.withValues(alpha: 0.3)
                  : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Product image/emoji
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _categoryColor(product.category),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(_categoryEmoji(product.category),
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(_categoryLabel(product.category),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Row(children: [
                  // Price
                  Text(product.formattedPrice,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppTheme.primaryRed)),

                  // Discount badge
                  if (product.hasDiscount) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('-${product.discount}%',
                          style: GoogleFonts.dmSans(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppTheme.primaryRed)),
                    ),
                  ],

                  const SizedBox(width: 6),

                  // Stock status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.stock == 0
                          ? const Color(0xFFFFF0F2)
                          : product.stock < 5
                              ? const Color(0xFFFFF8F0)
                              : const Color(0xFFE8F8EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.stock == 0
                          ? 'Out of stock'
                          : product.stock < 5
                              ? '⚠️ ${product.stock} left'
                              : '${product.stock} in stock',
                      style: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: product.stock == 0
                            ? AppTheme.primaryRed
                            : product.stock < 5
                                ? AppTheme.accentOrange
                                : AppTheme.successGreen,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // Action buttons
          Column(
            children: [
              // Add stock button — calls inventory API
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppTheme.successGreen, size: 22),
                tooltip: 'Add Stock',
                onPressed: onAddStock,
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.primaryRed, size: 22),
                tooltip: 'Delete Product',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'mens_clothing':   return const Color(0xFFFFF3E8);
      case 'womens_clothing': return const Color(0xFFFFF0F5);
      case 'domestics_home':  return const Color(0xFFEEF5FF);
      default:                return const Color(0xFFF4F4F2);
    }
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'mens_clothing':   return '👔';
      case 'womens_clothing': return '👗';
      case 'domestics_home':  return '🏠';
      default:                return '📦';
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'mens_clothing':   return "Men's Clothing";
      case 'womens_clothing': return "Women's Clothing";
      case 'domestics_home':  return 'Domestics & Home';
      default:                return 'Uncategorized';
    }
  }
}

// ===========================================================
// ADD PRODUCT BOTTOM SHEET
// ===========================================================
class _AddProductSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddProductSheet({required this.ref});

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _formKey             = GlobalKey<FormState>();
  final _nameController      = TextEditingController();
  final _priceController     = TextEditingController();
  final _discountController  = TextEditingController();
  final _stockController     = TextEditingController();
  final _descController      = TextEditingController();

  String       _category = 'mens_clothing';
  final List<String> _selectedSizes = [];
  bool         _isSaving  = false;

  // Picked photos (bytes are read straight away so they work on web
  // and mobile). The first photo is the cover shown on product cards.
  static const int _maxPhotos = 8; // same limit as the API
  final List<ImageUpload> _photos = [];
  final _picker = ImagePicker();

  final List<String> _allSizes = ['XS','S','M','L','XL','XXL','28','30','32','34','36','37','38','39','40'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // PICK PHOTOS FROM DEVICE
  // On web: opens a file dialog (hold Ctrl/Shift to choose several)
  // On mobile: opens the gallery with multi-select
  // ----------------------------------------------------------
  Future<void> _pickImages() async {
    final room = _maxPhotos - _photos.length;
    if (room <= 0) return;
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth:  1200,  // resize to reduce upload size
        maxHeight: 1200,
        imageQuality: 85, // slight compression
      );
      if (picked.isEmpty) return; // user cancelled

      final chosen = picked.take(room).toList();
      final uploads = <ImageUpload>[];
      for (final file in chosen) {
        uploads.add(ImageUpload(await file.readAsBytes(), file.name));
      }
      if (!mounted) return;
      setState(() => _photos.addAll(uploads));

      if (picked.length > room) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Only $_maxPhotos photos per product. '
              'The first $room were added.'),
          backgroundColor: AppTheme.accentOrange,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not pick image: $e'),
        backgroundColor: AppTheme.primaryRed,
      ));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // POST /api/products (multipart, with the picked image)
      await ref.read(productsProvider.notifier).addProduct(
        name:          _nameController.text.trim(),
        category:      _category,
        price:         double.parse(_priceController.text),
        stock:         int.parse(_stockController.text),
        discount:      _discountController.text.isNotEmpty
                         ? int.tryParse(_discountController.text)
                         : null,
        description:   _descController.text.trim().isNotEmpty
                         ? _descController.text.trim()
                         : null,
        sizes:         _selectedSizes.isNotEmpty ? _selectedSizes : null,
        images:        _photos,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_nameController.text} added to store!'),
        backgroundColor: AppTheme.successGreen,
      ));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e'),
        backgroundColor: AppTheme.primaryRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add New Product',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        _lbl('Product Name *'),
                        TextFormField(
                          controller: _nameController,
                          decoration: _dec('e.g. Classic Oxford Shirt'),
                          validator: (v) =>
                              v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Category
                        _lbl('Category *'),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: _dec(''),
                          items: const [
                            DropdownMenuItem(value: 'mens_clothing',   child: Text("👔 Men's Clothing")),
                            DropdownMenuItem(value: 'womens_clothing', child: Text("👗 Women's Clothing")),
                            DropdownMenuItem(value: 'domestics_home',  child: Text("🏠 Domestics & Home")),
                          ],
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                        const SizedBox(height: 16),

                        // Price + Discount row
                        Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _lbl('Price (MK) *'),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: _dec('e.g. 4500'),
                                validator: (v) {
                                  if (v!.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ],
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _lbl('Discount % (optional)'),
                              TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                decoration: _dec('e.g. 20'),
                              ),
                            ],
                          )),
                        ]),
                        const SizedBox(height: 16),

                        // Stock
                        _lbl('Stock Quantity *'),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: _dec('e.g. 50'),
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (int.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        _lbl('Description (optional)'),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: _dec('Describe the product...'),
                        ),
                        const SizedBox(height: 16),

                        // Product photos (uploaded to Cloudinary by the API)
                        _lbl('Product Photos (optional, up to $_maxPhotos)'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var i = 0; i < _photos.length; i++)
                              _photoThumb(i),
                            if (_photos.length < _maxPhotos)
                              _addPhotoTile(),
                          ],
                        ),
                        if (_photos.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'The first photo is the cover. Tap a photo to make it the cover.',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppTheme.textHint)),
                          ),
                        const SizedBox(height: 16),

                        _lbl('Available Sizes (optional)'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSizes.map((size) {
                            final selected = _selectedSizes.contains(size);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedSizes.remove(size);
                                } else {
                                  _selectedSizes.add(size);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.primaryRed
                                      : AppTheme.cardWhite,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? AppTheme.primaryRed
                                        : AppTheme.borderColor,
                                  ),
                                ),
                                child: Text(size,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check),
                            label: Text(
                              _isSaving ? 'Publishing...' : 'Publish Product',
                              style: GoogleFonts.dmSans(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // One picked photo: tap to make it the cover, X to remove it.
  Widget _photoThumb(int i) {
    final isCover = i == 0;
    return GestureDetector(
      onTap: isCover
          ? null
          : () => setState(() => _photos.insert(0, _photos.removeAt(i))),
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isCover ? AppTheme.primaryRed : AppTheme.borderColor,
                width: isCover ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.memory(_photos[i].bytes,
                width: 76, height: 76, fit: BoxFit.cover),
          ),
        ),
        if (isCover)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: const BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text('Cover', textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        Positioned(
          top: 2, right: 2,
          child: InkWell(
            onTap: () => setState(() => _photos.removeAt(i)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _addPhotoTile() => InkWell(
    onTap: _pickImages,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 76, height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: AppTheme.primaryRed),
          const SizedBox(height: 4),
          Text(_photos.isEmpty ? 'Add photos' : 'Add more',
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary)),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true, fillColor: const Color(0xFFF4F4F2),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryRed.withValues(alpha: 0.5))),
  );
}
