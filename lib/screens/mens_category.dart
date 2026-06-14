import 'package:flutter/material.dart';
import '../widgets/product_card.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class MensCategoryScreen extends StatefulWidget {
  const MensCategoryScreen({super.key});

  @override
  State<MensCategoryScreen> createState() => _MensCategoryScreenState();
}

class _MensCategoryScreenState extends State<MensCategoryScreen> {

  final _api = ApiService();

  // ── Page state ─────────────────────────────────────────────────
  bool          _loading  = false; // false = show mock data immediately
  String?       _error;
  int           _total    = 6;
  List<Product> _products = _mockProducts; // starts with mock data

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

  // ── Mobile drawer key ─────────────────────────────────────────
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ═══════════════════════════════════════════════════════════════
  //  MOCK DATA  — remove once backend is live
  // ═══════════════════════════════════════════════════════════════
  static final List<Product> _mockProducts = [
    const Product(id: 1, title: 'Classic Oxford Shirt',  seller: 'FashionHub MW',  category: 'shirts',   price: 4500,  oldPrice: 6900,  discountLabel: '-35%', rating: 5.0, reviews: 128, tag: 'Under MK 20,000', condition: 'New'),
    const Product(id: 2, title: "Men's Bomber Jacket",   seller: 'UrbanThread',     category: 'jackets',  price: 18000, oldPrice: 21200, discountLabel: '-15%', rating: 4.0, reviews: 52,  tag: 'Under MK 20,000', condition: 'New'),
    const Product(id: 3, title: 'Slim Fit Chinos',       seller: 'TrendyMW',        category: 'trousers', price: 9000,  oldPrice: null,  discountLabel: null,   rating: 5.0, reviews: 87,  tag: 'Under MK 20,000', condition: 'New'),
    const Product(id: 4, title: 'Premium Polo Shirt',    seller: 'PoleStyle',       category: 'shirts',   price: 5200,  oldPrice: 6900,  discountLabel: '-25%', rating: 4.0, reviews: 63,  tag: 'Under MK 20,000', condition: 'New'),
    const Product(id: 5, title: 'Business Suit Set',     seller: 'SuitUp MW',       category: 'suits',    price: 45000, oldPrice: null,  discountLabel: null,   rating: 5.0, reviews: 29,  tag: null,               condition: 'New'),
    const Product(id: 6, title: 'Graphic Tee Bundle',    seller: 'StreetWear MW',   category: 'tshirts',  price: 6800,  oldPrice: 8500,  discountLabel: '-20%', rating: 4.0, reviews: 145, tag: 'Under MK 20,000', condition: 'New'),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // tries the real API; falls back to mock on failure
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  API CALLS
  // ═══════════════════════════════════════════════════════════════

  Map<String, String> _buildQuery() {
    final q = <String, String>{};
    final cats = [
      if (shirts)   'shirts',
      if (trousers) 'trousers',
      if (jackets)  'jackets',
      if (suits)    'suits',
      if (tshirts)  'tshirts',
      if (shorts)   'shorts',
    ];
    if (cats.isNotEmpty) q['category'] = cats.join(',');
    final minTxt = _minPriceCtrl.text.trim();
    final maxTxt = _maxPriceCtrl.text.trim();
    if (minTxt.isNotEmpty) q['price_min'] = minTxt;
    if (maxTxt.isNotEmpty) q['price_max'] = maxTxt;
    if (condition != 'All') q['condition'] = condition.toLowerCase();
    if (minRating > 0)      q['min_rating'] = minRating.toString();
    const sortMap = {
      'Most Popular':       'popular',
      'Price: Low to High': 'price_asc',
      'Price: High to Low': 'price_desc',
      'Newest First':       'newest',
      'Top Rated':          'top_rated',
    };
    q['sort'] = sortMap[sortBy] ?? 'popular';
    final kw = _searchCtrl.text.trim();
    if (kw.isNotEmpty) q['q'] = kw;
    return q;
  }

  // GET /categories/mens-clothing/products
  // Response: { "total": 1240, "products": [ {...} ] }
  Future<void> _fetchProducts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.get(
        ApiConfig.categoryProducts('mens-clothing'),
        query: _buildQuery(),
      );
      setState(() {
        _total    = (data['total'] as num?)?.toInt() ?? 0;
        _products = (data['products'] as List)
            .map((j) => Product.fromJson(j as Map<String, dynamic>))
            .toList();
        _loading  = false;
      });
    } catch (_) {
      // Backend not ready yet — silently fall back to mock data
      setState(() {
        _products = _mockProducts;
        _total    = _mockProducts.length;
        _loading  = false;
        _error    = null; // hide error, show mock UI instead
      });
    }
  }

  // POST /cart  body: { "product_id": 5, "quantity": 1 }
  Future<void> _addToCart(Product p) async {
    try {
      await _api.post(ApiConfig.cartAdd, {'product_id': p.id, 'quantity': 1});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${p.title} added to cart ✓'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not add to cart: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // POST /wishlist  body: { "product_id": 5 }
  // DELETE /wishlist/items/5
  Future<void> _toggleWishlist(Product p) async {
    try {
      if (p.inWishlist) {
        await _api.delete(ApiConfig.wishlistItem(p.id));
      } else {
        await _api.post(ApiConfig.wishlistAdd, {'product_id': p.id});
      }
      await _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Wishlist error: $e'),
        backgroundColor: Colors.red,
      ));
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

        // Mobile filter drawer
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

        // Mobile bottom bar
        bottomNavigationBar: isMobile ? _mobileBottomBar() : null,

        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
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

                      // ── Banner ───────────────────────────────
                      _banner(isMobile),
                      const SizedBox(height: 20),

                      // ── Body ─────────────────────────────────
                      isMobile ? _mobileBody() : _desktopBody(),
                    ],
                  ),
                ),
              ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  BANNER  — "Men's Clothing" heading + product count + Add listing
  // ═══════════════════════════════════════════════════════════════

  Widget _banner(bool isMobile) {
    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
            color: const Color(0xfff5dfb8),
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Text('👔', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Men\'s Clothing',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pushNamed(context, '/seller/list'),
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: const Text('Add Listing',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    // Desktop banner
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
              const Text('Men\'s Clothing',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              Text(
                  '$_total products · Shirts, Trousers, Jackets, Suits & more',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          // "Under MK 20,000" quick-filter pill
          GestureDetector(
            onTap: () {
              _maxPriceCtrl.text = '20000';
              _applyFilters();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
          // Add listing button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pushNamed(context, '/seller/list'),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('Add a Listing',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MOBILE BODY
  // ═══════════════════════════════════════════════════════════════

  Widget _mobileBody() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _resultsBar(),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

  // ═══════════════════════════════════════════════════════════════
  //  DESKTOP BODY
  // ═══════════════════════════════════════════════════════════════

  Widget _desktopBody() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Filter sidebar
      SizedBox(width: 230, child: _filterPanel()),
      const SizedBox(width: 20),
      // Products
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
  //  PRODUCT CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _card(Product p) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/product/${p.id}'),
    child: ProductCard(
      title:       p.title,
      seller:      p.seller,
      price:       _fmt(p.price),
      oldPrice:    p.oldPrice != null ? _fmt(p.oldPrice!) : null,
      imageUrl:    p.imageUrl,
      discount:    p.discountLabel,
      rating:      p.rating,
      reviews:     p.reviews,
      tag:         p.tag,
      inWishlist:  p.inWishlist,
      onAddToCart: () => _addToCart(p),
      onWishlist:  () => _toggleWishlist(p),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  RESULTS BAR
  // ═══════════════════════════════════════════════════════════════

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
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s)))
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
        color: Colors.white, borderRadius: BorderRadius.circular(10)),
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
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
        const Divider(height: 16),

        // CATEGORY
        _sLabel('Category'),
        const SizedBox(height: 4),
        _fCheck('Shirts & Tops',    shirts,   (v) => setState(() => shirts   = v!)),
        _fCheck('Trousers & Jeans', trousers, (v) => setState(() => trousers = v!)),
        _fCheck('Jackets & Coats',  jackets,  (v) => setState(() => jackets  = v!)),
        _fCheck('Suits & Blazers',  suits,    (v) => setState(() => suits    = v!)),
        _fCheck('T-Shirts',         tshirts,  (v) => setState(() => tshirts  = v!)),
        _fCheck('Shorts',           shorts,   (v) => setState(() => shorts   = v!)),

        const SizedBox(height: 14),

        // PRICE RANGE
        _sLabel('Price Range (MK)'),
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
              style: const TextStyle(color: Colors.red, fontSize: 11)),
        ],

        const SizedBox(height: 14),

        // SIZE
        _sLabel('Size'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              ['S', 'M', 'L', 'XL', 'XXL'].map(_sizeChip).toList(),
        ),

        const SizedBox(height: 14),

        // CONDITION
        _sLabel('Condition'),
        const SizedBox(height: 4),
        ...['New', 'Used', 'All'].map((e) => RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: e,
              groupValue: condition,
              onChanged: (v) => setState(() => condition = v!),
              title: Text(e, style: const TextStyle(fontSize: 13)),
            )),

        const SizedBox(height: 10),

        // RATING
        _sLabel('Rating'),
        const SizedBox(height: 4),
        ...[
          (5, '★★★★★ 5 stars'),
          (4, '★★★★☆ 4+ stars'),
          (3, '★★★☆☆ 3+ stars'),
        ].map((e) => InkWell(
              onTap: () => setState(() => minRating = e.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
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
                            fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ),
            )),

        const SizedBox(height: 16),

        // APPLY
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.tune, size: 18, color: Colors.red),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
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
  //  SMALL HELPERS
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
          title: Text(label, style: const TextStyle(fontSize: 13)),
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
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        style: const TextStyle(fontSize: 12),
        onChanged: (_) => setState(() => _priceError = null),
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
    child: Text(size, style: const TextStyle(fontSize: 12)),
  );
}