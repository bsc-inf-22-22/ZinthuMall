// =============================================================
// FILE: lib/features/category/presentation/screens/mens_category_screen.dart
//
// FIXED: Updated all imports to match our project structure:
//   - Uses ProductModel (not Product)
//   - Uses our ApiService (not friend's custom one)
//   - Uses our ProductCard which takes a ProductModel object
//   - Removed ApiConfig (we use AppConstants instead)
// =============================================================

import 'package:flutter/material.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../features/home/data/models/product_model.dart';
import '../../../../features/home/presentation/widgets/product_card.dart';

class MensCategoryScreen extends StatefulWidget {
  const MensCategoryScreen({super.key});

  @override
  State<MensCategoryScreen> createState() => _MensCategoryScreenState();
}

class _MensCategoryScreenState extends State<MensCategoryScreen> {
  final _api = ApiService();

  // ── Page state ─────────────────────────────────────────────────
  bool              _loading  = false;
  String?           _error;
  int               _total    = 6;
  List<ProductModel> _products = _mockProducts;

  // ── Filter state ───────────────────────────────────────────────
  bool   shirts   = false;
  bool   trousers = false;
  bool   jackets  = false;
  bool   suits    = false;
  bool   tshirts  = false;
  bool   shorts   = false;
  String condition = 'All';
  int    minRating = 0;
  String sortBy    = 'Most Popular';

  // ── Price range ────────────────────────────────────────────────
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();
  String? _priceError;

  // ── Search ─────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Mobile drawer key ──────────────────────────────────────────
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ═══════════════════════════════════════════════════════════════
  //  MOCK DATA — used when backend is unreachable
  // ═══════════════════════════════════════════════════════════════
  static final List<ProductModel> _mockProducts = [
    ProductModel(
      id: 1, name: 'Classic Oxford Shirt', category: "Men's Clothing",
      price: 4500, stock: 42, discount: 35,
      sellerName: 'FashionHub MW', rating: 5.0, reviewCount: 128,
      createdAt: DateTime(2025, 1, 10), updatedAt: DateTime(2025, 1, 10),
    ),
    ProductModel(
      id: 2, name: "Men's Bomber Jacket", category: "Men's Clothing",
      price: 18000, stock: 20, discount: 15,
      sellerName: 'UrbanThread', rating: 4.0, reviewCount: 52,
      createdAt: DateTime(2025, 1, 10), updatedAt: DateTime(2025, 1, 10),
    ),
    ProductModel(
      id: 3, name: 'Slim Fit Chinos', category: "Men's Clothing",
      price: 9000, stock: 25,
      sellerName: 'TrendyMW', rating: 5.0, reviewCount: 87,
      createdAt: DateTime(2025, 1, 10), updatedAt: DateTime(2025, 1, 10),
    ),
    ProductModel(
      id: 4, name: 'Premium Polo Shirt', category: "Men's Clothing",
      price: 5200, stock: 30, discount: 25,
      sellerName: 'PoleStyle', rating: 4.0, reviewCount: 63,
      createdAt: DateTime(2025, 1, 10), updatedAt: DateTime(2025, 1, 10),
    ),
    ProductModel(
      id: 5, name: 'Business Suit Set', category: "Men's Clothing",
      price: 45000, stock: 10,
      sellerName: 'SuitUp MW', rating: 5.0, reviewCount: 29,
      createdAt: DateTime(2025, 1, 10), updatedAt: DateTime(2025, 1, 10),
    ),
    ProductModel(
      id: 6, name: 'Graphic Tee Bundle', category: "Men's Clothing",
      price: 6800, stock: 50, discount: 20,
      sellerName: 'StreetWear MW', rating: 4.0, reviewCount: 145,
      createdAt: DateTime(2025, 1, 10), updatedAt: DateTime(2025, 1, 10),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════
  //  API CALL — GET /api/products/category/Men's Clothing
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchProducts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await _api.getProductsByCategory("Men's Clothing");

      // Apply local filters
      var filtered = results;

      // Search filter
      final kw = _searchCtrl.text.trim().toLowerCase();
      if (kw.isNotEmpty) {
        filtered = filtered
            .where((p) => p.name.toLowerCase().contains(kw))
            .toList();
      }

      // Price filter
      final minTxt = _minPriceCtrl.text.trim();
      final maxTxt = _maxPriceCtrl.text.trim();
      if (minTxt.isNotEmpty) {
        final min = double.tryParse(minTxt);
        if (min != null) filtered = filtered.where((p) => p.price >= min).toList();
      }
      if (maxTxt.isNotEmpty) {
        final max = double.tryParse(maxTxt);
        if (max != null) filtered = filtered.where((p) => p.price <= max).toList();
      }

      // Sort
      switch (sortBy) {
        case 'Price: Low to High':
          filtered.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price: High to Low':
          filtered.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Newest First':
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Top Rated':
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
          break;
      }

      setState(() {
        _products = filtered;
        _total    = filtered.length;
        _loading  = false;
      });
    } catch (_) {
      // Fall back to mock data silently
      setState(() {
        _products = _mockProducts;
        _total    = _mockProducts.length;
        _loading  = false;
      });
    }
  }

  void _applyFilters() {
    final minTxt = _minPriceCtrl.text.trim();
    final maxTxt = _maxPriceCtrl.text.trim();
    final min    = minTxt.isEmpty ? null : int.tryParse(minTxt);
    final max    = maxTxt.isEmpty ? null : int.tryParse(maxTxt);
    if ((minTxt.isNotEmpty && min == null) ||
        (maxTxt.isNotEmpty && max == null)) {
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
      shirts = trousers = jackets = suits = tshirts = shorts = false;
      condition = 'All';
      minRating = 0;
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

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isMobile = constraints.maxWidth < 700;

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xfff2f2f2),
        drawer: isMobile
            ? Drawer(
                width: 290,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _filterPanel(),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: isMobile ? _mobileBottomBar() : null,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.red))
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _banner(isMobile),
                      const SizedBox(height: 20),
                      isMobile ? _mobileBody() : _desktopBody(),
                    ],
                  ),
                ),
              ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  BANNER
  // ═══════════════════════════════════════════════════════════════

  Widget _banner(bool isMobile) {
    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
            color: const Color(0xfff5dfb8),
            borderRadius: BorderRadius.circular(12)),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Text('👔', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Men's Clothing",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$_total products · Shirts, Trousers & more',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, '/seller/list'),
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: const Text('Add Listing',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 110,
      decoration: BoxDecoration(
          color: const Color(0xfff5dfb8),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Text('👔', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Men's Clothing",
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              Text(
                  '$_total products · Shirts, Trousers, Jackets, Suits & more',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _maxPriceCtrl.text = '20000';
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Text('Under MK 20,000',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () =>
                Navigator.pushNamed(context, '/seller/list'),
            icon:
                const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('Add a Listing',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MOBILE / DESKTOP BODY
  // ═══════════════════════════════════════════════════════════════

  Widget _mobileBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultsBar(),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.58,
            ),
            itemCount: _products.length,
            itemBuilder: (_, i) => _card(_products[i]),
          ),
        ],
      );

  Widget _desktopBody() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 230, child: _filterPanel()),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _resultsBar(),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.60,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (_, i) => _card(_products[i]),
                ),
              ],
            ),
          ),
        ],
      );

  // ═══════════════════════════════════════════════════════════════
  //  PRODUCT CARD — uses our ProductCard with ProductModel
  // ═══════════════════════════════════════════════════════════════

  Widget _card(ProductModel p) => ProductCard(
        product: p,
        onTap: () => Navigator.pushNamed(context, '/product/${p.id}'),
        onAddToCart: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${p.name} added to cart ✓'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ));
        },
      );

  // ═══════════════════════════════════════════════════════════════
  //  RESULTS BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _resultsBar() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      color: Colors.black87, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Showing '),
                    TextSpan(
                      text: '${_products.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' of $_total results'),
                  ],
                ),
              ),
            ),
            const Text('Sort: ',
                style:
                    TextStyle(fontSize: 12, color: Colors.black54)),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortBy,
                isDense: true,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87),
                items: [
                  'Most Popular',
                  'Price: Low to High',
                  'Price: High to Low',
                  'Newest First',
                  'Top Rated',
                ]
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(s)))
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

  // ═══════════════════════════════════════════════════════════════
  //  FILTER PANEL
  // ═══════════════════════════════════════════════════════════════

  Widget _filterPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      style:
                          TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 16),
            _sLabel('Category'),
            const SizedBox(height: 4),
            _fCheck('Shirts & Tops', shirts,
                (v) => setState(() => shirts = v!)),
            _fCheck('Trousers & Jeans', trousers,
                (v) => setState(() => trousers = v!)),
            _fCheck('Jackets & Coats', jackets,
                (v) => setState(() => jackets = v!)),
            _fCheck('Suits & Blazers', suits,
                (v) => setState(() => suits = v!)),
            _fCheck('T-Shirts', tshirts,
                (v) => setState(() => tshirts = v!)),
            _fCheck(
                'Shorts', shorts, (v) => setState(() => shorts = v!)),
            const SizedBox(height: 14),
            _sLabel('Price Range (MK)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _priceField(_minPriceCtrl, 'Min')),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('—',
                      style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                    child: _priceField(_maxPriceCtrl, 'Max')),
              ],
            ),
            if (_priceError != null) ...[
              const SizedBox(height: 4),
              Text(_priceError!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 11)),
            ],
            const SizedBox(height: 14),
            _sLabel('Size'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['S', 'M', 'L', 'XL', 'XXL']
                  .map(_sizeChip)
                  .toList(),
            ),
            const SizedBox(height: 14),
            _sLabel('Condition'),
            const SizedBox(height: 4),
            ...['New', 'Used', 'All'].map((e) =>
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: e,
                  groupValue: condition,
                  onChanged: (v) =>
                      setState(() => condition = v!),
                  title: Text(e,
                      style: const TextStyle(fontSize: 13)),
                )),
            const SizedBox(height: 10),
            _sLabel('Rating'),
            const SizedBox(height: 4),
            ...[
              (5, '★★★★★ 5 stars'),
              (4, '★★★★☆ 4+ stars'),
              (3, '★★★☆☆ 3+ stars'),
            ].map((e) => InkWell(
                  onTap: () =>
                      setState(() => minRating = e.$1),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: e.$1,
                          groupValue: minRating,
                          onChanged: (v) =>
                              setState(() => minRating = v!),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(e.$2,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _applyFilters,
                child: const Text('Apply Filters',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  //  MOBILE BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _mobileBottomBar() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -2))
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.tune,
                    size: 18, color: Colors.red),
                label: const Text('Filters',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: sortBy,
                    isDense: true,
                    isExpanded: true,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87),
                    items: [
                      'Most Popular',
                      'Price: Low to High',
                      'Price: High to Low',
                      'Newest First',
                      'Top Rated',
                    ]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s)))
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

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _sLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black54));

  Widget _fCheck(
          String label, bool value, void Function(bool?) onChange) =>
      SizedBox(
        height: 34,
        child: CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: value,
          onChanged: onChange,
          title:
              Text(label, style: const TextStyle(fontSize: 13)),
        ),
      );

  Widget _priceField(
          TextEditingController ctrl, String hint) =>
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
            borderSide:
                BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide:
                BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide:
                const BorderSide(color: Colors.red),
          ),
        ),
        style: const TextStyle(fontSize: 12),
        onChanged: (_) =>
            setState(() => _priceError = null),
      );

  Widget _sizeChip(String size) => Container(
        width: 36,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child:
            Text(size, style: const TextStyle(fontSize: 12)),
      );
}
