// =============================================================
// FILE: lib/core/services/api_service.dart
//
// Single HTTP client for the Kachipapa Store API (backend/).
// The base URL comes from AppConstants.apiBaseUrl, which is set
// at build time with --dart-define=API_BASE_URL=...
//
// Two separate sessions are stored on the device:
//   - admin token    (store owner, admin dashboard)
//   - customer token (shoppers; see customer_session_provider.dart)
// =============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../../features/home/data/models/product_model.dart';

/// A photo picked on the device, ready to upload.
class ImageUpload {
  final Uint8List bytes;
  final String fileName;
  const ImageUpload(this.bytes, this.fileName);
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${AppConstants.apiBaseUrl}$path').replace(queryParameters: query);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> _headersWith(String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(prefKey);
    return {
      ..._jsonHeaders,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> get _adminHeaders => _headersWith(AppConstants.prefAdminToken);
  Future<Map<String, String>> get _customerHeaders => _headersWith(AppConstants.prefCustomerToken);

  // ----------------------------------------------------------
  // ADMIN TOKEN
  // ----------------------------------------------------------
  Future<void> saveAdminToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefAdminToken, token);
  }

  Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefAdminToken);
  }

  Future<void> clearAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefAdminToken);
  }

  // ==========================================================
  // ADMIN AUTH
  // ==========================================================

  /// Creates the first admin account. [setupKey] must match the
  /// server's ADMIN_SETUP_KEY.
  Future<void> registerAdmin({
    required String email,
    required String password,
    required String setupKey,
  }) async {
    await _send(_client.post(
      _uri('/admin/auth/register'),
      headers: {..._jsonHeaders, 'X-Setup-Key': setupKey},
      body: jsonEncode({'email': email, 'password': password}),
    ));
  }

  Future<String> loginAdmin({required String email, required String password}) async {
    final data = await _send(_client.post(
      _uri('/admin/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    )) as Map<String, dynamic>;
    final token = data['access_token'] as String;
    await saveAdminToken(token);
    return token;
  }

  // ==========================================================
  // PRODUCTS (public)
  // ==========================================================

  List<ProductModel> _products(dynamic data) =>
      (data as List).map((j) => ProductModel.fromJson(j as Map<String, dynamic>)).toList();

  Future<List<ProductModel>> getProducts() async =>
      _products(await _send(_client.get(_uri('/products'), headers: _jsonHeaders)));

  Future<List<ProductModel>> getProductsByCategory(String category) async => _products(
      await _send(_client.get(_uri('/products/category/$category'), headers: _jsonHeaders)));

  Future<List<ProductModel>> searchProducts(String query) async => _products(
      await _send(_client.get(_uri('/products/search', {'q': query}), headers: _jsonHeaders)));

  Future<ProductModel> getProduct(int id) async => ProductModel.fromJson(
      await _send(_client.get(_uri('/products/$id'), headers: _jsonHeaders)) as Map<String, dynamic>);

  // ==========================================================
  // PRODUCTS (admin)
  // ==========================================================

  Future<ProductModel> createProduct({
    required String name,
    required String category,
    required double price,
    required int stock,
    int? discount,
    String? description,
    List<String>? sizes,
    List<ImageUpload> images = const [],
  }) {
    return _sendProductForm('POST', '/products', {
      'name': name,
      'category': category,
      'price': price.toString(),
      'stock': stock.toString(),
      if (discount != null) 'discount': discount.toString(),
      if (description != null && description.isNotEmpty) 'description': description,
      if (sizes != null && sizes.isNotEmpty) 'sizes': sizes.join(','),
    }, images);
  }

  /// [images] are added after the existing photos;
  /// [removeImageUrls] are deleted from the product.
  Future<ProductModel> updateProduct(
    int id,
    Map<String, dynamic> fields, {
    List<ImageUpload> images = const [],
    List<String> removeImageUrls = const [],
  }) {
    final form = fields.map((key, value) =>
        MapEntry(key, value is List ? value.join(',') : value.toString()));
    if (removeImageUrls.isNotEmpty) {
      form['removeImageUrls'] = jsonEncode(removeImageUrls);
    }
    return _sendProductForm('PATCH', '/products/$id', form, images);
  }

  Future<ProductModel> _sendProductForm(
    String method,
    String path,
    Map<String, String> fields,
    List<ImageUpload> images,
  ) async {
    final token = await getAdminToken();
    final request = http.MultipartRequest(method, _uri(path))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);

    for (final image in images) {
      final mime = (lookupMimeType(image.fileName) ?? 'image/jpeg').split('/');
      request.files.add(http.MultipartFile.fromBytes(
        'images',
        image.bytes,
        filename: image.fileName,
        contentType: MediaType(mime[0], mime[1]),
      ));
    }

    final data = await _send(
      request.send().then(http.Response.fromStream),
      // several photos over a slow connection can take a while
      timeout: Duration(seconds: 60 + 30 * images.length),
    );
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    await _send(_client.delete(_uri('/products/$id'), headers: await _adminHeaders));
  }

  // ==========================================================
  // INVENTORY (admin)
  // ==========================================================

  Future<List<Map<String, dynamic>>> getInventory() async => List<Map<String, dynamic>>.from(
      await _send(_client.get(_uri('/inventory'), headers: await _adminHeaders)) as List);

  Future<List<Map<String, dynamic>>> getLowStock() async => List<Map<String, dynamic>>.from(
      await _send(_client.get(_uri('/inventory/low-stock'), headers: await _adminHeaders)) as List);

  Future<Map<String, dynamic>> addStock({required int productId, required int quantity, String? notes}) =>
      _adjustStock('add-stock', productId, quantity, notes);

  Future<Map<String, dynamic>> reduceStock({required int productId, required int quantity, String? notes}) =>
      _adjustStock('reduce-stock', productId, quantity, notes);

  Future<Map<String, dynamic>> _adjustStock(String action, int productId, int quantity, String? notes) async {
    return await _send(_client.post(
      _uri('/inventory/$action'),
      headers: await _adminHeaders,
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    )) as Map<String, dynamic>;
  }

  // ==========================================================
  // ADMIN: ORDERS, NOTIFICATIONS, REVIEWS, ANALYTICS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getAdminOrders({String? status}) async =>
      List<Map<String, dynamic>>.from(await _send(_client.get(
        _uri('/admin/orders', status == null ? null : {'status': status}),
        headers: await _adminHeaders,
      )) as List);

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async =>
      await _send(_client.patch(
        _uri('/admin/orders/$orderId/status'),
        headers: await _adminHeaders,
        body: jsonEncode({'status': status}),
      )) as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateOrderPayment(int orderId, String paymentStatus, {String? transactionId}) async =>
      await _send(_client.patch(
        _uri('/admin/orders/$orderId/payment'),
        headers: await _adminHeaders,
        body: jsonEncode({
          'paymentStatus': paymentStatus,
          if (transactionId != null && transactionId.isNotEmpty) 'transactionId': transactionId,
        }),
      )) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getAdminNotifications() async => List<Map<String, dynamic>>.from(
      await _send(_client.get(_uri('/admin/notifications'), headers: await _adminHeaders)) as List);

  Future<void> markNotificationRead(int id) async {
    await _send(_client.patch(_uri('/admin/notifications/$id/read'), headers: await _adminHeaders));
  }

  Future<void> markAllNotificationsRead() async {
    await _send(_client.patch(_uri('/admin/notifications/read-all'), headers: await _adminHeaders));
  }

  Future<List<Map<String, dynamic>>> getAdminReviews() async => List<Map<String, dynamic>>.from(
      await _send(_client.get(_uri('/admin/reviews'), headers: await _adminHeaders)) as List);

  Future<Map<String, dynamic>> getAnalyticsSummary() async =>
      await _send(_client.get(_uri('/admin/analytics/summary'), headers: await _adminHeaders))
          as Map<String, dynamic>;

  // ==========================================================
  // CUSTOMER AUTH & PROFILE
  // ==========================================================

  /// Returns `{access_token, customer: {id, name, email, phone}}`.
  Future<Map<String, dynamic>> loginCustomer({required String email, required String password}) async {
    return await _send(_client.post(
      _uri('/customer/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    )) as Map<String, dynamic>;
  }

  /// Returns `{access_token, customer: {id, name, email, phone}}`.
  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    return await _send(_client.post(
      _uri('/customer/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    )) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCustomerProfile() async =>
      await _send(_client.get(_uri('/customer/profile'), headers: await _customerHeaders))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateCustomerProfile(Map<String, String> fields) async =>
      await _send(_client.patch(
        _uri('/customer/profile'),
        headers: await _customerHeaders,
        body: jsonEncode(fields),
      )) as Map<String, dynamic>;

  // ==========================================================
  // ORDERS (customer)
  // ==========================================================

  /// Places an order. Prices and totals are calculated by the server;
  /// only product IDs, quantities and sizes are sent.
  Future<Map<String, dynamic>> placeOrder({
    required String customerName,
    String? customerEmail,
    required String customerPhone,
    required String deliveryAddress,
    required String deliveryCity,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    return await _send(_client.post(
      _uri('/orders'),
      headers: await _customerHeaders, // links the order if logged in
      body: jsonEncode({
        'customerName': customerName,
        if (customerEmail != null && customerEmail.isNotEmpty) 'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'deliveryCity': deliveryCity,
        'paymentMethod': paymentMethod,
        'items': items,
      }),
    )) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async => List<Map<String, dynamic>>.from(
      await _send(_client.get(_uri('/orders/mine'), headers: await _customerHeaders)) as List);

  /// Public tracking: needs the order number and the phone used at checkout.
  Future<Map<String, dynamic>> trackOrder(int orderId, String phone) async =>
      await _send(_client.get(_uri('/orders/track/$orderId', {'phone': phone}), headers: _jsonHeaders))
          as Map<String, dynamic>;

  // ==========================================================
  // WISHLIST (customer)
  // ==========================================================

  Future<List<ProductModel>> getWishlist() async =>
      _products(await _send(_client.get(_uri('/wishlist'), headers: await _customerHeaders)));

  Future<void> addToWishlist(int productId) async {
    await _send(_client.post(_uri('/wishlist/$productId'), headers: await _customerHeaders));
  }

  Future<void> removeFromWishlist(int productId) async {
    await _send(_client.delete(_uri('/wishlist/$productId'), headers: await _customerHeaders));
  }

  // ==========================================================
  // REVIEWS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async =>
      List<Map<String, dynamic>>.from(
          await _send(_client.get(_uri('/reviews/product/$productId'), headers: _jsonHeaders)) as List);

  Future<List<Map<String, dynamic>>> getMyReviews() async => List<Map<String, dynamic>>.from(
      await _send(_client.get(_uri('/reviews/mine'), headers: await _customerHeaders)) as List);

  Future<Map<String, dynamic>> createReview({required int productId, required int rating, String? comment}) async =>
      await _send(_client.post(
        _uri('/reviews'),
        headers: await _customerHeaders,
        body: jsonEncode({
          'productId': productId,
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        }),
      )) as Map<String, dynamic>;

  // ==========================================================
  // STORE SETTINGS (public)
  // ==========================================================

  Future<Map<String, dynamic>> getStoreSettings() async =>
      await _send(_client.get(_uri('/settings'), headers: _jsonHeaders)) as Map<String, dynamic>;

  // ==========================================================
  // RESPONSE HANDLING
  // ==========================================================

  /// Awaits a request, applies a timeout and turns errors into
  /// [ApiException]s with a message that can be shown to the user.
  Future<dynamic> _send(Future<http.Response> request, {Duration timeout = _timeout}) async {
    final http.Response response;
    try {
      response = await request.timeout(timeout);
    } on TimeoutException {
      throw const ApiException('The server is taking too long to respond. Please try again.');
    } catch (_) {
      throw const ApiException('Could not connect. Check your internet connection and try again.');
    }

    final dynamic body = response.body.isEmpty ? null : _tryDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    // NestJS errors look like {"message": "..." | ["..."], "statusCode": 400}
    var message = body is Map ? body['message'] : null;
    if (message is List) message = message.join('\n');
    final text = (message is String && message.isNotEmpty) ? message : null;

    switch (response.statusCode) {
      case 401:
        throw ApiException(text ?? 'Please log in again.', statusCode: 401);
      case 403:
        throw ApiException(text ?? 'You do not have access to this.', statusCode: 403);
      case 404:
        throw ApiException(text ?? 'Not found.', statusCode: 404);
      case 429:
        throw const ApiException('Too many attempts. Please wait a minute and try again.', statusCode: 429);
      default:
        if (response.statusCode >= 500) {
          throw ApiException('Something went wrong on our side. Please try again.',
              statusCode: response.statusCode);
        }
        throw ApiException(text ?? 'Request failed (${response.statusCode}).', statusCode: response.statusCode);
    }
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
