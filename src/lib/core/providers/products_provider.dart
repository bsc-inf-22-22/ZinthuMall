import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../features/home/data/models/product_model.dart';
import '../services/api_service.dart';

// Auth state
final adminAuthProvider  = StateProvider<bool>((ref) => false);
final adminNameProvider  = StateProvider<String>((ref) => '');
final adminEmailProvider = StateProvider<String>((ref) => '');

// API service
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Products provider
final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => ProductsNotifier(ref.read(apiServiceProvider)),
);

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ApiService _api;

  ProductsNotifier(this._api) : super(const AsyncLoading()) {
    // Load mock data IMMEDIATELY so app renders fast
    // Then try real API in background
    _loadWithFallback();
  }

  Future<void> _loadWithFallback() async {
    // Step 1 — show mock data instantly (no waiting)
    state = AsyncData(ProductModel.sampleProducts);

    // Step 2 — try real API with a short timeout
    // If backend not running, gives up quickly (3 seconds)
    try {
      final products = await _api.getProducts()
          .timeout(const Duration(seconds: 3));
      // Backend responded — use real data
      state = AsyncData(products);
    } catch (e) {
      // Backend not running — stick with mock data
      // App already rendered, user sees content immediately
      print('Using mock data: backend not available');
    }
  }

  Future<void> loadProducts() => _loadWithFallback();

  void loadMockData() {
    state = AsyncData(ProductModel.sampleProducts);
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required double price,
    required int    stock,
    int?    discount,
    String? description,
    List<String>? sizes,
    Uint8List? imageBytes,
    String?    imageFileName,
  }) async {
    try {
      final newProduct = await _api.createProduct(
        name:          name,
        category:      category,
        price:         price,
        stock:         stock,
        discount:      discount,
        description:   description,
        sizes:         sizes,
        imageBytes:    imageBytes,
        imageFileName: imageFileName,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, newProduct]);
    } catch (e) {
      // Mock fallback
      final mockProduct = ProductModel(
        id:          DateTime.now().millisecondsSinceEpoch,
        name:        name,
        category:    category,
        price:       price,
        stock:       stock,
        discount:    discount,
        description: description,
        sizes:       sizes ?? [],
        createdAt:   DateTime.now(),
        updatedAt:   DateTime.now(),
      );
      final current = state.value ?? [];
      state = AsyncData([...current, mockProduct]);
    }
  }

  Future<void> deleteProduct(int productId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != productId).toList());
    try {
      await _api.deleteProduct(productId);
    } catch (e) {
      print('Delete API failed: $e');
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> fields) async {
    try {
      final updated = await _api.updateProduct(id, fields);
      final current = state.value ?? [];
      state = AsyncData(current.map((p) => p.id == id ? updated : p).toList());
    } catch (e) {
      print('Update API failed: $e');
    }
  }

  Future<void> refresh() => _loadWithFallback();

  List<ProductModel> get _products => state.value ?? [];
  int get totalProducts   => _products.length;
  int get mensCount       => _products.where((p) => p.category == 'mens_clothing').length;
  int get womensCount     => _products.where((p) => p.category == 'womens_clothing').length;
  int get domesticsCount  => _products.where((p) => p.category == 'domestics_home').length;
  int get outOfStockCount => _products.where((p) => p.stock == 0).length;
  int get lowStockCount   => _products.where((p) => p.stock > 0 && p.stock < 5).length;
}

final productsByCategoryProvider =
    Provider.family<List<ProductModel>, String>((ref, category) {
  final products = ref.watch(productsProvider).value ?? [];
  if (category == 'all') return products;
  return products.where((p) => p.category == category).toList();
});

final inventoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(apiServiceProvider).getInventory();
});

final lowStockProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(apiServiceProvider).getLowStock();
});
