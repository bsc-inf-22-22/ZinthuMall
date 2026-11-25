// =============================================================
// FILE: lib/core/providers/products_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/models/product_model.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

// Admin session state (admin dashboard)
final adminAuthProvider = StateProvider<bool>((ref) => false);
final adminNameProvider = StateProvider<String>((ref) => '');
final adminEmailProvider = StateProvider<String>((ref) => '');

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// All products from the API. Shows a loading state first and an
/// error state (with retry) if the server can't be reached.
final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => ProductsNotifier(ref.read(apiServiceProvider)),
);

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ApiService _api;

  ProductsNotifier(this._api) : super(const AsyncLoading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    if (state.value == null) state = const AsyncLoading();
    state = await AsyncValue.guard(_api.getProducts);
  }

  Future<void> refresh() => loadProducts();

  // ── Admin actions: errors are rethrown so the screen can show them ──

  Future<ProductModel> addProduct({
    required String name,
    required String category,
    required double price,
    required int stock,
    int? discount,
    String? description,
    List<String>? sizes,
    List<ImageUpload> images = const [],
  }) async {
    final created = await _api.createProduct(
      name: name,
      category: category,
      price: price,
      stock: stock,
      discount: discount,
      description: description,
      sizes: sizes,
      images: images,
    );
    state = AsyncData([created, ..._products]);
    return created;
  }

  Future<void> updateProduct(
    int id,
    Map<String, dynamic> fields, {
    List<ImageUpload> images = const [],
    List<String> removeImageUrls = const [],
  }) async {
    final updated = await _api.updateProduct(id, fields,
        images: images, removeImageUrls: removeImageUrls);
    state = AsyncData(_products.map((p) => p.id == id ? updated : p).toList());
  }

  Future<void> deleteProduct(int id) async {
    await _api.deleteProduct(id);
    state = AsyncData(_products.where((p) => p.id != id).toList());
  }

  List<ProductModel> get _products => state.value ?? [];
  int get totalProducts => _products.length;
  int get mensCount => _products.where((p) => p.category == AppConstants.categoryMen).length;
  int get womensCount => _products.where((p) => p.category == AppConstants.categoryWomen).length;
  int get domesticsCount => _products.where((p) => p.category == AppConstants.categoryDomestic).length;
  int get outOfStockCount => _products.where((p) => p.stock == 0).length;
  int get lowStockCount =>
      _products.where((p) => p.stock > 0 && p.stock < AppConstants.lowStockThreshold).length;
}

final productsByCategoryProvider = Provider.family<List<ProductModel>, String>((ref, category) {
  final products = ref.watch(productsProvider).value ?? [];
  if (category == 'all') return products;
  return products.where((p) => p.category == category).toList();
});

final inventoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
    (ref) => ref.read(apiServiceProvider).getInventory());

final lowStockProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
    (ref) => ref.read(apiServiceProvider).getLowStock());

/// Public store settings (delivery fee, free-delivery threshold, contacts).
final storeSettingsProvider = FutureProvider<Map<String, dynamic>>(
    (ref) => ref.read(apiServiceProvider).getStoreSettings());
