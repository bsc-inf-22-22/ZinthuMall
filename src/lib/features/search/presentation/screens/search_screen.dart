// =============================================================
// FILE: lib/features/search/presentation/screens/search_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();

  List<ProductModel> _results  = [];
  bool _isLoading  = false;
  bool _hasSearched = false;
  String _activeFilter = 'All';

  final List<String> _categories = [
    'All', "Men's Clothing", "Women's Clothing",
    "Domestics & Home", "Electronics", "Food & Groceries",
  ];

  // Recent searches — stored locally
  List<String> _recentSearches = [
    'Oxford Shirt', 'Dress', 'Chitenje', 'Shoes',
  ];

  @override
  void initState() {
    super.initState();
    // Auto focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    // Save to recent searches
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 6) _recentSearches.removeLast();
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      var results = await ApiService().searchProducts(query);

      // Apply category filter locally
      if (_activeFilter != 'All') {
        results = results
            .where((p) => p.category == _activeFilter)
            .toList();
      }

      setState(() {
        _results   = results;
        _isLoading = false;
      });
    } catch (_) {
      // Fallback — filter mock data
      setState(() {
        _results   = [];
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() => _activeFilter = filter);
    if (_hasSearched && _searchCtrl.text.isNotEmpty) {
      _search(_searchCtrl.text);
    }
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
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: GoogleFonts.dmSans(
              color: AppTheme.textHint, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textHint),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                    })
                : null,
          ),
          style: GoogleFonts.dmSans(fontSize: 15),
          onSubmitted: _search,
          onChanged: (v) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_searchCtrl.text),
            child: Text('Search',
              style: GoogleFonts.dmSans(
                color: AppTheme.primaryRed,
                fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(children: [
        // Category filter chips
        _filterChips(),
        // Content
        Expanded(child: _hasSearched ? _searchResults() : _defaultView()),
      ]),
    );
  }

  Widget _filterChips() => Container(
    color: Colors.white,
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final cat = _categories[i];
        final isActive = _activeFilter == cat;
        return GestureDetector(
          onTap: () => _applyFilter(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryRed : const Color(0xFFF4F4F2),
              borderRadius: BorderRadius.circular(20)),
            child: Text(cat,
              style: GoogleFonts.dmSans(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
          ),
        );
      },
    ),
  );

  // ═══════════════════════════════════════════════
  //  DEFAULT VIEW — recent searches + trending
  // ═══════════════════════════════════════════════
  Widget _defaultView() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Recent searches
      if (_recentSearches.isNotEmpty) ...[
        Row(children: [
          Text('Recent Searches',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _recentSearches.clear()),
            child: Text('Clear',
              style: GoogleFonts.dmSans(
                color: AppTheme.primaryRed, fontSize: 12))),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _recentSearches.map((s) => GestureDetector(
            onTap: () {
              _searchCtrl.text = s;
              _search(s);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.history,
                    size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Text(s, style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textPrimary)),
              ]),
            ),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],

      // Trending searches
      Text('Trending in Malawi 🔥',
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 12),
      ...[
        ('👔', 'Men\'s Shirts'),
        ('👗', 'Chitenje Dresses'),
        ('👟', 'Sneakers'),
        ('🏠', 'Home Decor'),
        ('📱', 'Phone Accessories'),
        ('💄', 'Beauty Products'),
      ].asMap().entries.map((e) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F2),
            borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(e.value.$1,
            style: const TextStyle(fontSize: 18)))),
        title: Text(e.value.$2,
          style: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.trending_up,
          size: 16, color: AppTheme.textHint),
        onTap: () {
          _searchCtrl.text = e.value.$2;
          _search(e.value.$2);
        },
      )),
    ]),
  );

  // ═══════════════════════════════════════════════
  //  SEARCH RESULTS
  // ═══════════════════════════════════════════════
  Widget _searchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    if (_results.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No results found',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Try a different search term',
            style: GoogleFonts.dmSans(
              color: AppTheme.textHint, fontSize: 14)),
        ],
      ));
    }

    return Column(children: [
      // Results count
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(children: [
          Text('${_results.length} results for ',
            style: GoogleFonts.dmSans(
              fontSize: 13, color: AppTheme.textSecondary)),
          Text('"${_searchCtrl.text}"',
            style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
        ]),
      ),
      // Grid
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final container = ProviderScope.containerOf(context);
          return ProductCard(
            product: _results[i],
            onAddToCart: () {
              container.read(cartProvider.notifier)
                  .addItem(_results[i]);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${_results[i].name} added to cart ✓'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 2)));
            },
          );
        },
      )),
    ]);
  }
}
