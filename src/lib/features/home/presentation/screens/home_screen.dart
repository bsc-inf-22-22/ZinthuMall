// =============================================================
// FILE: lib/features/home/presentation/screens/home_screen.dart
//
// UPDATED:
//   - Changed to ConsumerStatefulWidget so it can use Riverpod
//   - Products now come from productsProvider (shared state)
//     instead of ProductModel.sampleProducts (hardcoded)
//   - When admin adds/deletes a product, this screen rebuilds
//     automatically because it WATCHES the same provider
//   - Added hidden admin button (long press on logo)
//
//   THE KEY CHANGE — from this:
//     _allProducts = ProductModel.sampleProducts;  // hardcoded
//   To this:
//     final products = ref.watch(productsProvider); // live shared state
//
//   Now admin panel and homepage are connected!
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/products_provider.dart';
import '../../../category/presentation/screens/home_category_screen.dart';
import '../../data/models/product_model.dart';
import '../widgets/product_card.dart';

// ----------------------------------------------------------
// Changed from StatefulWidget → ConsumerStatefulWidget
// ConsumerStatefulWidget = StatefulWidget + Riverpod ref
// ----------------------------------------------------------
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// ConsumerState gives us access to 'ref' for Riverpod
class _HomeScreenState extends ConsumerState<HomeScreen> {

  int _selectedTabIndex      = 0;
  int _selectedCategoryIndex = 0;
  int _cartCount             = 3;

  // Flash sale countdown
  int _countdownHours   = 4;
  int _countdownMinutes = 37;
  int _countdownSeconds = 19;
  late Timer _countdownTimer;

  // Tab labels
  final List<String> _tabs = [
    'All Products',
    "Men's Clothing",
    "Women's Clothing",
    'Domestic & Home',
    'New Arrivals',
  ];

  // Category circles
  final List<Map<String, dynamic>> _categories = [
    {'label': "Men's Clothing",   'emoji': '👔', 'color': const Color(0xFFFFF3E0), 'key': 'mens_clothing'},
    {'label': "Women's Clothing", 'emoji': '👗', 'color': const Color(0xFFFCE4EC), 'key': 'womens_clothing'},
    {'label': 'Home & Kitchen',   'emoji': '🏠', 'color': const Color(0xFFE3F2FD), 'key': 'domestics_home'},
    {'label': 'Bags & Purses',    'emoji': '👜', 'color': const Color(0xFFF3E5F5), 'key': 'bags'},
    {'label': 'Footwear',         'emoji': '👟', 'color': const Color(0xFFE8F5E9), 'key': 'footwear'},
    {'label': 'Accessories',      'emoji': '⌚', 'color': const Color(0xFFFFF8E1), 'key': 'accessories'},
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else if (_countdownMinutes > 0) {
          _countdownSeconds = 59;
          _countdownMinutes--;
        } else if (_countdownHours > 0) {
          _countdownSeconds = 59;
          _countdownMinutes = 59;
          _countdownHours--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // ----------------------------------------------------------
  // Filter products from the shared provider by tab
  // ----------------------------------------------------------
  List<ProductModel> _getFilteredProducts(List<ProductModel> all) {
    switch (_selectedTabIndex) {
      case 1: return all.where((p) => p.category == 'mens_clothing').toList();
      case 2: return all.where((p) => p.category == 'womens_clothing').toList();
      case 3:
        // Also navigate to full category screen
        return all.where((p) => p.category == 'domestics_home').toList();
      case 4:
        final ago = DateTime.now().subtract(const Duration(days: 30));
        return all.where((p) => p.createdAt.isAfter(ago)).toList();
      default: return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // KEY LINE — watch the shared products provider
    // When admin adds/removes a product, this rebuilds automatically
    // ----------------------------------------------------------
    // productsProvider now returns AsyncValue<List<ProductModel>>
    // .value ?? [] safely extracts the list (empty if loading/error)
    final asyncProducts    = ref.watch(productsProvider);
    final allProducts      = asyncProducts.value ?? [];
    final filteredProducts = _getFilteredProducts(allProducts);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildAnnouncementBar()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildHeroBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildTrustBadges(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Shop by Category', 'All Categories', () {}),
                _buildCategoryCircles(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFlashDealsBanner(),
            ),
          ),
          SliverToBoxAdapter(child: _buildProductTabs()),

          // Product count indicator
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '${filteredProducts.length} products',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
            ),
          ),

          // Product grid — now uses live filteredProducts
          filteredProducts.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = filteredProducts[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
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
                                content: Text('${product.name} added to cart!'),
                                backgroundColor: AppTheme.successGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredProducts.length,
                    ),
                  ),
                ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPaymentStrip(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ----------------------------------------------------------
  // SLIVER APP BAR
  // Logo has a long-press gesture → navigate to admin login
  // This is the "hidden" admin entry point
  // ----------------------------------------------------------
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: AppTheme.cardWhite,
      toolbarHeight: 64,
      title: Row(
        children: [
          // Long press logo → admin login (hidden entry point)
          GestureDetector(
            onTap: () {},
            onLongPress: () {
              Navigator.pushNamed(context, '/admin');
            },
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Kachipapa',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  TextSpan(
                    text: 'Store',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F2),
                  borderRadius: BorderRadius.circular(40),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.textHint, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search clothes, homeware…',
                        style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryRed),
                onPressed: () {},
              ),
              if (_cartCount > 0)
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    width: 17, height: 17,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBar() {
    return Container(
      color: AppTheme.primaryRed,
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Center(
        child: Text(
          '🚚 Free delivery on orders over MK 5,000  ·  Airtel Money & TNM Mpamba',
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, letterSpacing: 0.4),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return SizedBox(
      height: 260,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A1A), Color(0xFF3D0012)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(40)),
                    child: Text('NEW COLLECTION 2025',
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  ),
                  const SizedBox(height: 10),
                  Text('Dress Sharp.\nLive Bold.',
                      style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Premium fashion delivered\nanywhere in Malawi',
                      style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12, height: 1.5)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text('Shop Now', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _sideCard("Women's Fashion", 'New Arrivals', '👗',
                    const LinearGradient(colors: [Color(0xFFFFF0F3), Color(0xFFFECDDB)]), () {})),
                const SizedBox(height: 12),
                Expanded(child: _sideCard('Home & Kitchen', 'Domestics', '🏡',
                    const LinearGradient(colors: [Color(0xFFEFF7FF), Color(0xFFC6E0FF)]), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeCategoryScreen()));
                })),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideCard(String label, String title, String emoji, Gradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppTheme.textHint)),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(emoji, style: const TextStyle(fontSize: 28)),
            Row(children: [
              Text('Shop', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
              const Icon(Icons.arrow_forward, size: 13, color: AppTheme.primaryRed),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadges() {
    final badges = [
      {'icon': Icons.local_shipping_outlined, 'title': 'Fast Delivery',    'sub': 'Nationwide'},
      {'icon': Icons.shield_outlined,          'title': 'Buyer Protection', 'sub': '100% Guaranteed'},
      {'icon': Icons.refresh,                  'title': 'Easy Returns',     'sub': '7-day policy'},
      {'icon': Icons.phone_android,            'title': 'Mobile Pay',       'sub': 'Airtel & Mpamba'},
    ];
    return Row(
      children: List.generate(badges.length, (i) {
        final b = badges[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < badges.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.cardWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderColor)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFFFF0F2), borderRadius: BorderRadius.circular(8)),
                child: Icon(b['icon'] as IconData, size: 17, color: AppTheme.primaryRed)),
              const SizedBox(height: 6),
              Text(b['title'] as String, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600)),
              Text(b['sub'] as String, style: GoogleFonts.dmSans(fontSize: 9, color: AppTheme.textHint)),
            ]),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, String linkText, VoidCallback onLink) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: onLink,
            child: Row(children: [
              Text(linkText, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryRed),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCircles() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryIndex = index);
              // Navigate to full category screen for home
              if (cat['key'] == 'domestics_home') {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HomeCategoryScreen()));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: cat['color'] as Color, shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppTheme.primaryRed : Colors.transparent, width: 2.5),
                    boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.2), blurRadius: 8)] : null,
                  ),
                  child: Center(child: Text(cat['emoji'] as String, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 72,
                  child: Text(cat['label'] as String, textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500,
                          color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondary)),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFlashDealsBanner() {
    return Container(
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC8102E), Color(0xFFE63950)]), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        const Text('⚡', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Today's Flash Sale — Up to 60% Off", style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Limited stock · Ends at midnight', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11)),
        ])),
        Row(children: [
          _countdownBox(_countdownHours, 'HRS'),
          const SizedBox(width: 6),
          _countdownBox(_countdownMinutes, 'MIN'),
          const SizedBox(width: 6),
          _countdownBox(_countdownSeconds, 'SEC'),
        ]),
      ]),
    );
  }

  Widget _countdownBox(int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(7)),
      child: Column(children: [
        Text(value.toString().padLeft(2, '0'),
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 8, letterSpacing: 0.6)),
      ]),
    );
  }

  Widget _buildProductTabs() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Text('Featured Products', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isActive = _selectedTabIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryRed : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: isActive ? AppTheme.primaryRed : AppTheme.borderColor),
                ),
                child: Text(_tabs[index],
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : AppTheme.textSecondary)),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(children: [
          const Text('🛍️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No products yet', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('The admin hasn\'t added any products yet.',
              style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildPaymentStrip() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF162040)]),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(text: TextSpan(children: [
          TextSpan(text: 'Secure Checkout via ', style: GoogleFonts.playfairDisplay(fontSize: 16, color: Colors.white)),
          TextSpan(text: 'Pachangu API', style: GoogleFonts.playfairDisplay(fontSize: 16, color: AppTheme.accentOrange, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(height: 14),
        Row(children: [
          _payBadge(Icons.phone_android, 'Airtel Money', 'Instant · Secure'),
          const SizedBox(width: 10),
          _payBadge(Icons.phone_iphone, 'TNM Mpamba', 'Instant · Secure'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppTheme.accentOrange, borderRadius: BorderRadius.circular(40)),
            child: Text('Powered by Pachangu', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }

  Widget _payBadge(IconData icon, String name, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(sub, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryRed,
      unselectedItemColor: AppTheme.textHint,
      currentIndex: 0,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 10),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Wishlist'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}
