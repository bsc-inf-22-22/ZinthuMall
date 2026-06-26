// =============================================================
// FILE: lib/features/category/presentation/screens/womens_category_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/widgets/product_card.dart';

class WomensCategoryScreen extends StatefulWidget {
  const WomensCategoryScreen({super.key});

  @override
  State<WomensCategoryScreen> createState() => _WomensCategoryScreenState();
}

class _WomensCategoryScreenState extends State<WomensCategoryScreen> {
  final _api = ApiService();

  bool               _loading  = false;
  int                _total    = 2180;
  List<ProductModel> _products = _mockProducts;
  String?            _error;

  // ── Filter state ──────────────────────────────────────────────
  // Category (matches design exactly)
  bool dresses   = false;
  bool tops      = false;
  bool skirts    = false;
  bool handbags  = false;
  bool heels     = false;
  bool accessories = false;

  // Size (matches design: XS S M L XL)
  final Set<String> _selectedSizes   = {};
  final List<String> _allSizes       = ['XS', 'S', 'M', 'L', 'XL'];

  // Color (matches design)
  String? _selectedColor;
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Black',  'color': Colors.black},
    {'name': 'White',  'color': Colors.white},
    {'name': 'Red',    'color': Colors.red},
    {'name': 'Pink',   'color': Colors.pink},
    {'name': 'Blue',   'color': Colors.blue},
    {'name': 'Green',  'color': Colors.green},
    {'name': 'Yellow', 'color': Colors.yellow.shade700},
    {'name': 'Brown',  'color': Colors.brown},
  ];

  // Price range
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();
  String? _priceError;

  // Sort & search
  String sortBy = 'Most Popular';
  final TextEditingController _searchCtrl = TextEditingController();

  // Mobile drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Mock data (removed once backend is live) ──────────────────
  static final List<ProductModel> _mockProducts = [
    ProductModel(id: 201, name: 'Floral Wrap Dress',      category: "Women's Clothing",
        price: 7200,  stock: 30, discount: 20, sellerName: 'StyleQueen',
        rating: 4.0, reviewCount: 94,  createdAt: DateTime(2025,2,1), updatedAt: DateTime(2025,2,1)),
    ProductModel(id: 202, name: 'Block Heel Sandals',      category: "Women's Clothing",
        price: 5800,  stock: 25, discount: 40, sellerName: 'SoleStyle',
        rating: 4.0, reviewCount: 67,  createdAt: DateTime(2025,2,3), updatedAt: DateTime(2025,2,3)),
    ProductModel(id: 203, name: 'Summer Straw Hat',        category: "Women's Clothing",
        price: 3200,  stock: 60, discount: 25, sellerName: 'AccessorizeMe',
        rating: 5.0, reviewCount: 76,  createdAt: DateTime(2025,2,5), updatedAt: DateTime(2025,2,5)),
    ProductModel(id: 204, name: 'Leather Tote Bag',        category: "Women's Clothing",
        price: 14500, stock: 12, sellerName: 'BagQueen MW',
        rating: 5.0, reviewCount: 112, createdAt: DateTime(2025,2,7), updatedAt: DateTime(2025,2,7)),
    ProductModel(id: 205, name: 'Fitted Bodysuit',         category: "Women's Clothing",
        price: 4800,  stock: 40, discount: 30, sellerName: 'ChicMW',
        rating: 4.0, reviewCount: 58,  createdAt: DateTime(2025,2,9), updatedAt: DateTime(2025,2,9)),
    ProductModel(id: 206, name: 'Ankara Print Scarf',      category: "Women's Clothing",
        price: 2500,  stock: 80, sellerName: 'AfroStyle',
        rating: 5.0, reviewCount: 203, createdAt: DateTime(2025,2,11), updatedAt: DateTime(2025,2,11)),
    ProductModel(id: 207, name: 'High-Waist Pencil Skirt', category: "Women's Clothing",
        price: 5900,  stock: 22, discount: 15, sellerName: 'UrbanFemme',
        rating: 5.0, reviewCount: 67,  createdAt: DateTime(2025,2,13), updatedAt: DateTime(2025,2,13)),
    ProductModel(id: 208, name: 'Satin Wrap Blouse',       category: "Women's Clothing",
        price: 4200,  stock: 45, sellerName: 'LadyStyle MW',
        rating: 4.0, reviewCount: 89,  createdAt: DateTime(2025,2,15), updatedAt: DateTime(2025,2,15)),
  ];

  // ════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  //  API  —  GET /categories/womens-clothing/products
  //  Query params your backend should support:
  //    ?category=dresses,tops,skirts,handbags,heels,accessories
  //    ?size=XS,S,M
  //    ?color=Pink
  //    ?price_min=1000&price_max=15000
  //    ?sort=popular|price_asc|price_desc|newest
  //    ?q=search+term
  //    ?page=1&per_page=48
  //  Response: { "total": 2180, "products": [ {...} ] }
  // ════════════════════════════════════════════════════════════════

  Future<void> _fetchProducts() async {
    setState(() { _loading = true; _error = null; });
    try {
      var results = await _api.getProductsByCategory("Women's Clothing");

      // Search
      final kw = _searchCtrl.text.trim().toLowerCase();
      if (kw.isNotEmpty) {
        results = results
            .where((p) => p.name.toLowerCase().contains(kw))
            .toList();
      }

      // Category sub-filter
      final activeCats = <String>[
        if (dresses)     'dress',
        if (tops)        'blouse',
        if (skirts)      'skirt',
        if (handbags)    'bag',
        if (heels)       'heel',
        if (accessories) 'scarf',
      ];
      if (activeCats.isNotEmpty) {
        results = results.where((p) {
          final n = p.name.toLowerCase();
          return activeCats.any((c) => n.contains(c));
        }).toList();
      }

      // Price filter
      final min = double.tryParse(_minPriceCtrl.text.trim());
      final max = double.tryParse(_maxPriceCtrl.text.trim());
      if (min != null) results = results.where((p) => p.price >= min).toList();
      if (max != null) results = results.where((p) => p.price <= max).toList();

      // Sort
      switch (sortBy) {
        case 'Price: Low to High': results.sort((a, b) => a.price.compareTo(b.price)); break;
        case 'Price: High to Low': results.sort((a, b) => b.price.compareTo(a.price)); break;
        case 'Newest First':       results.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
        case 'Top Rated':          results.sort((a, b) => b.rating.compareTo(a.rating)); break;
      }

      setState(() {
        _products = results;
        _total    = results.length;
        _loading  = false;
      });
    } catch (_) {
      // Backend not ready — fall back to mock silently
      setState(() {
        _products = _mockProducts;
        _total    = _mockProducts.length;
        _loading  = false;
        _error    = null;
      });
    }
  }

  void _applyFilters() {
    final minTxt = _minPriceCtrl.text.trim();
    final maxTxt = _maxPriceCtrl.text.trim();
    final min    = minTxt.isEmpty ? null : int.tryParse(minTxt);
    final max    = maxTxt.isEmpty ? null : int.tryParse(maxTxt);
    if ((minTxt.isNotEmpty && min == null) || (maxTxt.isNotEmpty && max == null)) {
      setState(() => _priceError = 'Please enter valid numbers.');
      return;
    }
    if (min != null && max != null && min > max) {
      setState(() => _priceError = 'Min must be less than Max.');
      return;
    }
    setState(() => _priceError = null);
    _fetchProducts();
  }

  void _clearFilters() {
    setState(() {
      dresses = tops = skirts = handbags = heels = accessories = false;
      _selectedSizes.clear();
      _selectedColor = null;
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _priceError = null;
    });
    _fetchProducts();
  }

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    return s.length > 3
        ? 'MK ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
        : 'MK $s';
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final screenW  = constraints.maxWidth;
      final isMobile = screenW < 700;
      final isTablet = screenW >= 700 && screenW < 1024;

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xfff2f2f2),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Women's Clothing",
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          // Search in appbar on mobile
          actions: isMobile
              ? [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () => _showSearchDialog(ctx),
                  ),
                  const SizedBox(width: 4),
                ]
              : null,
        ),

        // Mobile filter drawer
        drawer: isMobile
            ? Drawer(
                width: 300,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _filterPanel(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              )
            : null,

        // Mobile bottom bar
        bottomNavigationBar: isMobile ? _mobileBottomBar() : null,

        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pink))
            : RefreshIndicator(
                color: Colors.pink,
                onRefresh: _fetchProducts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Breadcrumb
                          _breadcrumb(),
                          const SizedBox(height: 12),

                          // Banner
                          _banner(isMobile),
                          const SizedBox(height: 20),

                          // Body
                          if (isMobile)
                            _mobileBody()
                          else if (isTablet)
                            _tabletBody()
                          else
                            _desktopBody(),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    });
  }

  // ════════════════════════════════════════════════════════════════
  //  BREADCRUMB
  // ════════════════════════════════════════════════════════════════

  Widget _breadcrumb() => Row(
    children: [
      GestureDetector(
        onTap: () => Navigator.pushNamedAndRemoveUntil(
            context, '/', (_) => false),
        child: const Text('Home',
            style: TextStyle(
                color: Colors.pink,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: Colors.pink)),
      ),
      const Text("  ›  Women's Clothing",
          style: TextStyle(color: Colors.grey, fontSize: 13)),
    ],
  );

  // ════════════════════════════════════════════════════════════════
  //  BANNER
  // ════════════════════════════════════════════════════════════════

  Widget _banner(bool isMobile) {
    const bg = Color(0xfffce4ec); // rose tint — matches women's palette

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Text('👗', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Women's Fashion",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$_total products · Dresses, Tops, Skirts & more',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),

          ],
        ),
      );
    }

    return Container(
      height: 118,
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Text('👗', style: TextStyle(fontSize: 52)),
          const SizedBox(width: 18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Women's Fashion",
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              Text(
                  '$_total products · Dresses, Tops, Skirts, Handbags & more',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          // Quick-filter pill — Under MK 15,000
          GestureDetector(
            onTap: () {
              _maxPriceCtrl.text = '15000';
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Text('Under MK 15,000',
                  style: TextStyle(
                      color: Colors.pink.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ),

        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  LAYOUTS
  // ════════════════════════════════════════════════════════════════

  // Mobile: full-width grid
  Widget _mobileBody() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _resultsBar(),
      const SizedBox(height: 12),
      _productGrid(crossAxisCount: 2, childAspectRatio: 0.58),
    ],
  );

  // Tablet: narrow filter sidebar (200px) + 2-col grid
  Widget _tabletBody() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 200, child: _filterPanel()),
      const SizedBox(width: 16),
      Expanded(
        child: Column(children: [
          _resultsBar(),
          const SizedBox(height: 12),
          _productGrid(crossAxisCount: 2, childAspectRatio: 0.60),
        ]),
      ),
    ],
  );

  // Desktop: 230px filter sidebar + 3-col grid
  Widget _desktopBody() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 230, child: _filterPanel()),
      const SizedBox(width: 20),
      Expanded(
        child: Column(children: [
          _resultsBar(),
          const SizedBox(height: 14),
          _productGrid(crossAxisCount: 3, childAspectRatio: 0.60),
        ]),
      ),
    ],
  );

  Widget _productGrid({required int crossAxisCount, required double childAspectRatio}) {
    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('No products found',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearFilters,
                child: Text('Clear filters',
                    style: TextStyle(color: Colors.pink.shade600)),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisCount == 2 ? 10 : 14,
        mainAxisSpacing: crossAxisCount == 2 ? 10 : 14,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final p = _products[i];
        return ProductCard(
          product: p,
          onTap: () => Navigator.pushNamed(context, '/product', arguments: p),
          onAddToCart: () => _showAddedToCart(p.name),
        );
      },
    );
  }

  void _showAddedToCart(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name added to cart ✓'),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: 'View Cart',
        textColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, '/cart'),
      ),
    ));
  }

  // ════════════════════════════════════════════════════════════════
  //  RESULTS BAR
  // ════════════════════════════════════════════════════════════════

  Widget _resultsBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(8)),
    child: Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                const TextSpan(text: 'Showing '),
                TextSpan(
                  text: '${_products.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' of $_total results'),
              ],
            ),
          ),
        ),
        const Text('Sort: ',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: sortBy,
            isDense: true,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            items: [
              'Most Popular',
              'Price: Low to High',
              'Price: High to Low',
              'Newest First',
              'Top Rated',
            ]
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              setState(() => sortBy = v!);
              _fetchProducts();
            },
          ),
        ),
      ],
    ),
  );

  // ════════════════════════════════════════════════════════════════
  //  FILTER PANEL  — exactly matches site design
  //  Category: Dresses | Tops & Blouses | Skirts | Handbags |
  //            Heels & Shoes | Accessories
  //  Size: XS S M L XL
  //  Price Range (MK) — min/max text fields
  //  Color — colour swatch chips
  //  [Apply Filters] button
  // ════════════════════════════════════════════════════════════════

  Widget _filterPanel() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ─────────────────────────────────────────────
        Row(
          children: [
            const Text('Filters',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
        const Divider(height: 16),

        // ── CATEGORY ───────────────────────────────────────────
        _sLabel('CATEGORY'),
        const SizedBox(height: 6),
        _fCheck('Dresses',         dresses,     (v) => setState(() => dresses     = v!)),
        _fCheck('Tops & Blouses',  tops,        (v) => setState(() => tops        = v!)),
        _fCheck('Skirts',          skirts,      (v) => setState(() => skirts      = v!)),
        _fCheck('Handbags',        handbags,    (v) => setState(() => handbags    = v!)),
        _fCheck('Heels & Shoes',   heels,       (v) => setState(() => heels       = v!)),
        _fCheck('Accessories',     accessories, (v) => setState(() => accessories = v!)),

        const SizedBox(height: 16),

        // ── SIZE ───────────────────────────────────────────────
        _sLabel('SIZE'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _allSizes.map((s) {
            final selected = _selectedSizes.contains(s);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedSizes.remove(s);
                } else {
                  _selectedSizes.add(s);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.pink.shade600 : Colors.white,
                  border: Border.all(
                    color: selected
                        ? Colors.pink.shade600
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // ── PRICE RANGE ────────────────────────────────────────
        _sLabel('PRICE RANGE (MK)'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _priceField(_minPriceCtrl, 'Min')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('—', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: _priceField(_maxPriceCtrl, 'Max')),
          ],
        ),
        if (_priceError != null) ...[
          const SizedBox(height: 4),
          Text(_priceError!,
              style:
                  const TextStyle(color: Colors.red, fontSize: 11)),
        ],

        const SizedBox(height: 16),

        // ── COLOR ──────────────────────────────────────────────
        _sLabel('COLOR'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((c) {
            final isSelected = _selectedColor == c['name'];
            final col        = c['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedColor = isSelected ? null : c['name'] as String;
              }),
              child: Tooltip(
                message: c['name'] as String,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.pink.shade600
                          : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color:
                                    Colors.pink.shade200,
                                blurRadius: 4)
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: col == Colors.white ||
                                  col == Colors.yellow.shade700
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedColor != null) ...[
          const SizedBox(height: 4),
          Text('Color: $_selectedColor',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.pink.shade600,
                  fontWeight: FontWeight.w500)),
        ],

        const SizedBox(height: 20),

        // ── APPLY ──────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _applyFilters,
            child: const Text('Apply Filters',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );

  // ════════════════════════════════════════════════════════════════
  //  MOBILE BOTTOM BAR
  // ════════════════════════════════════════════════════════════════

  Widget _mobileBottomBar() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(
          color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(Icons.tune, size: 18,
                color: Colors.pink.shade600),
            label: Text('Filters',
                style: TextStyle(color: Colors.pink.shade600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.pink.shade600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: sortBy,
                isDense: true,
                isExpanded: true,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87),
                items: [
                  'Most Popular',
                  'Price: Low to High',
                  'Price: High to Low',
                  'Newest First',
                  'Top Rated',
                ]
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() => sortBy = v!);
                  _fetchProducts();
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ════════════════════════════════════════════════════════════════
  //  SEARCH DIALOG  (mobile)
  // ════════════════════════════════════════════════════════════════

  void _showSearchDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text("Search Women's Clothing",
            style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Floral dress, handbag...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade600),
            ),
          ),
          onSubmitted: (_) {
            Navigator.pop(ctx);
            _fetchProducts();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600),
            onPressed: () {
              Navigator.pop(ctx);
              _fetchProducts();
            },
            child: const Text('Search',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SMALL HELPERS
  // ════════════════════════════════════════════════════════════════

  Widget _sLabel(String t) => Text(t,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
          color: Colors.black54));

  Widget _fCheck(
          String label, bool value, void Function(bool?) onChange) =>
      SizedBox(
        height: 34,
        child: CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.pink.shade600,
          value: value,
          onChanged: onChange,
          title: Text(label,
              style: const TextStyle(fontSize: 13)),
        ),
      );

  Widget _priceField(TextEditingController ctrl, String hint) =>
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: Colors.pink.shade400),
          ),
        ),
        style: const TextStyle(fontSize: 12),
        onChanged: (_) => setState(() => _priceError = null),
      );
}