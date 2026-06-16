// =============================================================
// FILE: lib/features/category/presentation/screens/home_category_screen.dart
//
// PURPOSE:
//   The Domestics & Home category screen.
//   Shows all products in the 'domestics_home' category with:
//     1. Category hero banner
//     2. Sub-category chips (Cookware, Bedding, Bathroom, etc.)
//     3. Sort + filter bar
//     4. Product grid (from shared productsProvider)
//
//   WHAT YOU LEARN HERE:
//   - Navigating to this screen from the homepage
//   - Reading a FILTERED slice of the shared productsProvider
//   - Local UI state (selected sub-category, sort order)
//     vs shared state (the product list itself)
//   - SliverAppBar with a custom hero banner that collapses
//     as the user scrolls down
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/providers/products_provider.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/widgets/product_card.dart';

class HomeCategoryScreen extends ConsumerStatefulWidget {
  const HomeCategoryScreen({super.key});

  @override
  ConsumerState<HomeCategoryScreen> createState() =>
      _HomeCategoryScreenState();
}

class _HomeCategoryScreenState extends ConsumerState<HomeCategoryScreen> {
  // ----------------------------------------------------------
  // LOCAL STATE
  // These only affect what THIS screen shows.
  // The actual product data lives in productsProvider (shared).
  // ----------------------------------------------------------

  // Which sub-category chip is selected
  String _selectedSubCategory = 'all';

  // Sort order
  String _sortBy = 'popular'; // popular | price_low | price_high | newest

  // Cart count (local — later will be its own provider)
  int _cartCount = 3;

  // ----------------------------------------------------------
  // SUB-CATEGORIES
  // These are UI-only filters — the backend doesn't have
  // sub-categories yet. We filter by product name keywords.
  // When the backend adds a 'subCategory' field, update the
  // filter logic in _applyFilters() below.
  // ----------------------------------------------------------
  final List<Map<String, dynamic>> _subCategories = [
    {'key': 'all',       'label': 'All',        'emoji': '🏠'},
    {'key': 'cookware',  'label': 'Cookware',   'emoji': '🍳'},
    {'key': 'bedding',   'label': 'Bedding',    'emoji': '🛏️'},
    {'key': 'bathroom',  'label': 'Bathroom',   'emoji': '🚿'},
    {'key': 'cleaning',  'label': 'Cleaning',   'emoji': '🧹'},
    {'key': 'furniture', 'label': 'Furniture',  'emoji': '🪑'},
    {'key': 'decor',     'label': 'Decor',      'emoji': '🌿'},
    {'key': 'storage',   'label': 'Storage',    'emoji': '🧺'},
    {'key': 'lighting',  'label': 'Lighting',   'emoji': '💡'},
  ];

  // ----------------------------------------------------------
  // FILTER + SORT LOGIC
  // Takes all domestics products → applies sub-category filter
  // → applies sort order → returns final list for the grid
  // ----------------------------------------------------------
  List<ProductModel> _applyFilters(List<ProductModel> all) {
    // Step 1: only domestics_home products
    var filtered = all
        .where((p) => p.category == 'domestics_home')
        .toList();

    // Step 2: sub-category filter (keyword match on product name)
    // LATER: replace with p.subCategory == _selectedSubCategory
    if (_selectedSubCategory != 'all') {
      final keywords = {
        'cookware':  ['cook', 'pan', 'pot', 'kitchen', 'wok', 'fry'],
        'bedding':   ['bed', 'sheet', 'pillow', 'duvet', 'blanket'],
        'bathroom':  ['bath', 'towel', 'soap', 'shower', 'toilet'],
        'cleaning':  ['clean', 'mop', 'broom', 'wash', 'brush'],
        'furniture': ['chair', 'table', 'sofa', 'desk', 'shelf'],
        'decor':     ['decor', 'plant', 'vase', 'candle', 'frame'],
        'storage':   ['storage', 'basket', 'box', 'rack', 'organiser'],
        'lighting':  ['light', 'lamp', 'bulb', 'lantern'],
      };
      final keys = keywords[_selectedSubCategory] ?? [];
      filtered = filtered.where((p) {
        final name = p.name.toLowerCase();
        return keys.any((k) => name.contains(k));
      }).toList();
    }

    // Step 3: sort
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popular':
      default:
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Watch shared provider — updates when admin adds/removes products
    final asyncProducts = ref.watch(productsProvider);
    final allProducts   = asyncProducts.value ?? [];
    final products      = _applyFilters(allProducts);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ------------------------------------------------
          // COLLAPSIBLE HERO APP BAR
          // expandedHeight: how tall it is when fully open
          // pinned: true → the toolbar stays visible when scrolled
          // ------------------------------------------------
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppTheme.cardWhite,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Cart icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                  if (_cartCount > 0)
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        width: 17, height: 17,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$_cartCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // FlexibleSpaceBar is the part that collapses
            flexibleSpace: FlexibleSpaceBar(
              // title shows in toolbar when collapsed
              title: Text(
                'Domestics & Home',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              // Background of the expanded hero section
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background emoji pattern
                    Positioned(
                      right: -20, top: -20,
                      child: Text('🏠',
                          style: TextStyle(
                              fontSize: 140,
                              color: Colors.white.withOpacity(0.08))),
                    ),
                    // Content
                    Positioned(
                      left: 20, bottom: 50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🏠  DOMESTICS & HOME',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${allProducts.where((p) => p.category == 'domestics_home').length} products',
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // SUB-CATEGORY CHIPS
          // ------------------------------------------------
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.cardWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _subCategories.map((sub) {
                    final isSelected = _selectedSubCategory == sub['key'];
                    return GestureDetector(
                      onTap: () => setState(
                          () => _selectedSubCategory = sub['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0D47A1)
                              : AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0D47A1)
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(sub['emoji'] as String,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              sub['label'] as String,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // SORT + RESULTS COUNT BAR
          // ------------------------------------------------
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Results count
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${products.length} ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'products found',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sort dropdown
                  GestureDetector(
                    onTap: () => _showSortSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sort,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _sortLabel(),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 16, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------
          // PRODUCT GRID or EMPTY STATE
          // ------------------------------------------------
          products.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            // TODO: Navigate to product detail screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening ${product.name}...'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          onAddToCart: () {
                            setState(() => _cartCount++);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${product.name} added to cart!'),
                                backgroundColor: AppTheme.successGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),

          // ------------------------------------------------
          // LOADING STATE overlay
          // ------------------------------------------------
          if (asyncProducts.isLoading)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF0D47A1)),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SORT BOTTOM SHEET
  // ----------------------------------------------------------
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Sort By',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...[
              ('popular',    'Most Popular',       Icons.star_outline),
              ('price_low',  'Price: Low to High', Icons.arrow_upward),
              ('price_high', 'Price: High to Low', Icons.arrow_downward),
              ('newest',     'Newest First',       Icons.new_releases_outlined),
            ].map((option) {
              final isSelected = _sortBy == option.$1;
              return ListTile(
                leading: Icon(option.$3,
                    color: isSelected
                        ? const Color(0xFF0D47A1)
                        : AppTheme.textHint),
                title: Text(option.$2,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF0D47A1)
                          : AppTheme.textPrimary,
                    )),
                trailing: isSelected
                    ? const Icon(Icons.check,
                        color: Color(0xFF0D47A1))
                    : null,
                onTap: () {
                  setState(() => _sortBy = option.$1);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // EMPTY STATE
  // ----------------------------------------------------------
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text('🏠', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            _selectedSubCategory == 'all'
                ? 'No home products yet'
                : 'No ${_selectedSubCategory} products',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedSubCategory == 'all'
                ? 'The admin hasn\'t added any home products yet'
                : 'Try selecting a different sub-category',
            style: GoogleFonts.dmSans(
                color: AppTheme.textHint, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (_selectedSubCategory != 'all') ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: () =>
                  setState(() => _selectedSubCategory = 'all'),
              child: Text('Show all home products',
                  style: GoogleFonts.dmSans(
                      color: const Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------
  String _sortLabel() {
    switch (_sortBy) {
      case 'price_low':  return 'Price ↑';
      case 'price_high': return 'Price ↓';
      case 'newest':     return 'Newest';
      default:           return 'Popular';
    }
  }
}
