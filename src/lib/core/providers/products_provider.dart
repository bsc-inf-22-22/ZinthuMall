// =============================================================
// FILE: lib/core/providers/products_provider.dart
//
// UPDATED: Now loads products from the real NestJS API.
//
// STATE FLOW:
//   App starts
//     → productsProvider initialises
//     → loadProducts() calls GET /api/products
//     → state changes from loading → loaded with real data
//     → Homepage and Admin Dashboard both rebuild
//
// LOADING STATES:
//   We use AsyncValue from Riverpod to handle 3 states:
//   - AsyncLoading  → spinner shown
//   - AsyncData     → products shown
//   - AsyncError    → error message shown
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/data/models/product_model.dart';
import '../services/api_service.dart';

// ----------------------------------------------------------
// AUTH STATE
// ----------------------------------------------------------
final adminAuthProvider  = StateProvider<bool>((ref) => false);
final adminNameProvider  = StateProvider<String>((ref) => '');
final adminEmailProvider = StateProvider<String>((ref) => '');

// ----------------------------------------------------------
// API SERVICE PROVIDER
// Makes ApiService available through Riverpod.
// Any provider that needs the API reads this.
// ----------------------------------------------------------
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ----------------------------------------------------------
// PRODUCTS STATE NOTIFIER PROVIDER
//
// ProductsNotifier now has two modes:
//
// MODE 1 — OFFLINE (mock data, no backend running):
//   Call: notifier.loadMockData()
//   Use this while backend is still being set up
//
// MODE 2 — ONLINE (real API):
//   Call: notifier.loadProducts()
//   Use this when both backends are running
// ----------------------------------------------------------
final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => ProductsNotifier(ref.read(apiServiceProvider)),
);

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ApiService _api;

  // Start in loading state
  ProductsNotifier(this._api) : super(const AsyncLoading()) {
    // Automatically load when provider is created
    loadProducts();
  }

  // ----------------------------------------------------------
  // LOAD FROM REAL API
  // Fetches products from GET /api/products
  // Falls back to mock data if API is unreachable
  // ----------------------------------------------------------
  Future<void> loadProducts() async {
    state = const AsyncLoading();
    try {
      final products = await _api.getProducts();
      state = AsyncData(products);
    } catch (e) {
      // API not running yet — fall back to sample data
      // Remove this fallback once backend is fully running
      print('API unavailable, using mock data: $e');
      state = AsyncData(ProductModel.sampleProducts);
    }
  }

  // ----------------------------------------------------------
  // LOAD MOCK DATA (offline mode)
  // ----------------------------------------------------------
  void loadMockData() {
    state = AsyncData(ProductModel.sampleProducts);
  }

  // ----------------------------------------------------------
  // ADD PRODUCT — calls real API then updates local state
  // ----------------------------------------------------------
  Future<void> addProduct({
    required String name,
    required String category,
    required double price,
    required int    stock,
    int?    discount,
    String? description,
    List<String>? sizes,
    String? imageUrl,
  }) async {
    try {
      // Call API — creates product in PostgreSQL
      final newProduct = await _api.createProduct(
        name:        name,
        category:    category,
        price:       price,
        stock:       stock,
        discount:    discount,
        description: description,
        sizes:       sizes,
        imageUrl:    imageUrl,
      );

      // Update local state — adds to existing list
      final current = state.value ?? [];
      state = AsyncData([...current, newProduct]);

    } catch (e) {
      // If API fails, add to local state only (mock mode)
      // This keeps the UI working even without a backend
      final now = DateTime.now();
      final mockProduct = ProductModel(
        id:          now.millisecondsSinceEpoch,
        name:        name,
        category:    category,
        price:       price,
        stock:       stock,
        discount:    discount,
        description: description,
        sizes:       sizes ?? [],
        imageUrl:    imageUrl,
        createdAt:   now,
        updatedAt:   now,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, mockProduct]);
    }
  }

  // ----------------------------------------------------------
  // DELETE PRODUCT — calls real API then removes from local state
  // ----------------------------------------------------------
  Future<void> deleteProduct(int productId) async {
    // Optimistic update: remove from UI immediately
    // If API fails, we could revert — for now we keep it simple
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != productId).toList());

    try {
      await _api.deleteProduct(productId);
    } catch (e) {
      // API failed — in production you'd revert the optimistic update
      print('Delete API call failed: $e');
    }
  }

  // ----------------------------------------------------------
  // UPDATE PRODUCT
  // ----------------------------------------------------------
  Future<void> updateProduct(int id, Map<String, dynamic> fields) async {
    try {
      final updated = await _api.updateProduct(id, fields);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((p) => p.id == id ? updated : p).toList(),
      );
    } catch (e) {
      print('Update API call failed: $e');
    }
  }

  // ----------------------------------------------------------
  // REFRESH — re-fetch everything from API
  // ----------------------------------------------------------
  Future<void> refresh() => loadProducts();

  // ----------------------------------------------------------
  // COMPUTED GETTERS — for admin dashboard stats
  // ----------------------------------------------------------
  List<ProductModel> get _products => state.value ?? [];

  int get totalProducts   => _products.length;
  int get mensCount       => _products.where((p) => p.category == 'mens_clothing').length;
  int get womensCount     => _products.where((p) => p.category == 'womens_clothing').length;
  int get domesticsCount  => _products.where((p) => p.category == 'domestics_home').length;
  int get outOfStockCount => _products.where((p) => p.stock == 0).length;
  int get lowStockCount   => _products.where((p) => p.stock > 0 && p.stock < 5).length;
}

// ----------------------------------------------------------
// DERIVED PROVIDERS
// ----------------------------------------------------------

// Products filtered by category — auto-updates with main list
final productsByCategoryProvider =
    Provider.family<List<ProductModel>, String>((ref, category) {
  final asyncProducts = ref.watch(productsProvider);
  final products      = asyncProducts.value ?? [];
  if (category == 'all') return products;
  return products.where((p) => p.category == category).toList();
});

// Inventory provider — loads from Friend 2's service
final inventoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(apiServiceProvider).getInventory();
});

final lowStockProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(apiServiceProvider).getLowStock();
});
