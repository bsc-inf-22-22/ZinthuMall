// =============================================================
// FILE: lib/core/services/api_service.dart
//
// UPDATED: Added proper image upload support using
// http.MultipartRequest which is what the NestJS backend
// expects (FileInterceptor('image', { storage: memoryStorage() }))
//
// HOW IMAGE UPLOAD WORKS:
//   1. Admin picks image → image_picker returns XFile
//   2. We read the bytes from XFile
//   3. We send as multipart/form-data with field name 'image'
//   4. NestJS receives it, uploads to Cloudinary
//   5. Returns product with imageUrl from Cloudinary
// =============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import '../constants/app_constants.dart';
import '../../features/home/data/models/product_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  // ----------------------------------------------------------
  // HEADERS
  // ----------------------------------------------------------
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefAuthToken) ?? '';
    return {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // ----------------------------------------------------------
  // TOKEN MANAGEMENT
  // ----------------------------------------------------------
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefAuthToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefAuthToken);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefAuthToken);
  }

  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ==========================================================
  // AUTH ENDPOINTS
  // ==========================================================

  Future<Map<String, dynamic>> registerAdmin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/admin/auth/register');
    final response = await _client.post(
      url,
      headers: _baseHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<String> loginAdmin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/admin/auth/login');
    final response = await _client.post(
      url,
      headers: _baseHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _handleResponse(response);
    final token = data['access_token'] as String;
    await saveToken(token);
    return token;
  }

  // ==========================================================
  // PRODUCTS ENDPOINTS
  // ==========================================================

  Future<List<ProductModel>> getProducts() async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/products');
    final response = await _client.get(url, headers: _baseHeaders);
    final data = _handleResponse(response);
    return (data as List)
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final url = Uri.parse(
        '${AppConstants.adminBaseUrl}/products/category/$category');
    final response = await _client.get(url, headers: _baseHeaders);
    final data = _handleResponse(response);
    return (data as List)
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final url = Uri.parse(
      '${AppConstants.adminBaseUrl}/products/search?q=${Uri.encodeComponent(query)}',
    );
    final response = await _client.get(url, headers: _baseHeaders);
    final data = _handleResponse(response);
    return (data as List)
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProduct(int id) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/products/$id');
    final response = await _client.get(url, headers: _baseHeaders);
    final data = _handleResponse(response);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/products/:id — returns raw Map for product detail screen
  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.adminBaseUrl}/products/$id'),
      headers: _baseHeaders,
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // ----------------------------------------------------------
  // CREATE PRODUCT WITH IMAGE UPLOAD
  //
  // The backend uses:
  //   @UseInterceptors(FileInterceptor('image', { storage: memoryStorage() }))
  //
  // So we send multipart/form-data where:
  //   - field 'image'  = the image file bytes
  //   - other fields   = product data as form fields
  //
  // imageBytes   = the raw bytes of the image file
  // imageFileName = e.g. "shirt.jpg"
  // ----------------------------------------------------------
  Future<ProductModel> createProduct({
    required String name,
    required String category,
    required double price,
    required int    stock,
    int?    discount,
    String? description,
    List<String>? sizes,
    // Image fields — null if admin didn't pick an image
    Uint8List? imageBytes,
    String?    imageFileName,
  }) async {
    final token = await getToken();
    final url   = Uri.parse('${AppConstants.adminBaseUrl}/products');

    // MultipartRequest handles multipart/form-data
    final request = http.MultipartRequest('POST', url);

    // Add JWT token header
    request.headers['Authorization'] = 'Bearer $token';

    // Add text fields
    request.fields['name']     = name;
    request.fields['category'] = category;
    request.fields['price']    = price.toString();
    request.fields['stock']    = stock.toString();

    if (discount != null)    request.fields['discount']    = discount.toString();
    if (description != null) request.fields['description'] = description;
    if (sizes != null && sizes.isNotEmpty) {
      // Backend expects sizes as array — send each one separately
      // NestJS @IsArray() decorator handles this
      for (int i = 0; i < sizes.length; i++) {
        request.fields['sizes[$i]'] = sizes[i];
      }
    }

    // Add image file if provided
    if (imageBytes != null && imageFileName != null) {
      // Detect MIME type from filename (e.g. "image/jpeg", "image/png")
      final mimeType = lookupMimeType(imageFileName) ?? 'image/jpeg';
      final mimeParts = mimeType.split('/');

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',           // ← must match FileInterceptor('image') in NestJS
          imageBytes,
          filename: imageFileName,
          contentType: http.MediaType(mimeParts[0], mimeParts[1]),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response         = await http.Response.fromStream(streamedResponse);
    final data             = _handleResponse(response);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  // ----------------------------------------------------------
  // UPDATE PRODUCT WITH OPTIONAL NEW IMAGE
  // ----------------------------------------------------------
  Future<ProductModel> updateProduct(
    int id,
    Map<String, dynamic> fields, {
    Uint8List? imageBytes,
    String?    imageFileName,
  }) async {
    final token   = await getToken();
    final url     = Uri.parse('${AppConstants.adminBaseUrl}/products/$id');
    final request = http.MultipartRequest('PATCH', url);

    request.headers['Authorization'] = 'Bearer $token';

    fields.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (imageBytes != null && imageFileName != null) {
      final mimeType = lookupMimeType(imageFileName) ?? 'image/jpeg';
      final mimeParts = mimeType.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName,
          contentType: http.MediaType(mimeParts[0], mimeParts[1]),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response         = await http.Response.fromStream(streamedResponse);
    final data             = _handleResponse(response);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  // ----------------------------------------------------------
  // DELETE PRODUCT
  // ----------------------------------------------------------
  Future<void> deleteProduct(int id) async {
    final headers = await _authHeaders;
    final url     = Uri.parse('${AppConstants.adminBaseUrl}/products/$id');
    final response = await _client.delete(url, headers: headers);
    _handleResponse(response);
  }

  // ==========================================================
  // INVENTORY ENDPOINTS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getInventory() async {
    final url      = Uri.parse('${AppConstants.inventoryBaseUrl}/inventory');
    final response = await _client.get(url, headers: _baseHeaders);
    final data     = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> getLowStock() async {
    final url = Uri.parse(
        '${AppConstants.inventoryBaseUrl}/inventory/low-stock');
    final response = await _client.get(url, headers: _baseHeaders);
    final data     = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<Map<String, dynamic>> addStock({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final url = Uri.parse(
        '${AppConstants.inventoryBaseUrl}/inventory/add-stock');
    final response = await _client.post(
      url,
      headers: _baseHeaders,
      body: jsonEncode({
        'productId': productId,
        'quantity':  quantity,
        if (notes != null) 'notes': notes,
      }),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reduceStock({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final url = Uri.parse(
        '${AppConstants.inventoryBaseUrl}/inventory/reduce-stock');
    final response = await _client.post(
      url,
      headers: _baseHeaders,
      body: jsonEncode({
        'productId': productId,
        'quantity':  quantity,
        if (notes != null) 'notes': notes,
      }),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // ==========================================================
  // RESPONSE HANDLER
  // ==========================================================
  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] ?? 'Something went wrong';

    switch (response.statusCode) {
      case 400: throw ApiException('Validation error: $message');
      case 401: throw ApiException('Authentication failed: $message');
      case 404: throw ApiException('Not found: $message');
      case 409: throw ApiException('Conflict: $message');
      case 500: throw ApiException('Server error. Please try again later.');
      default:  throw ApiException('Error ${response.statusCode}: $message');
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

  // ==========================================================
  // CUSTOMER AUTH ENDPOINTS
  // ==========================================================

  /// POST /api/customer/auth/login
  Future<Map<String, dynamic>> loginCustomer({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/customer/auth/login');
    final response = await _client.post(
      url,
      headers: _baseHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// POST /api/customer/auth/register
  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/customer/auth/register');
    final response = await _client.post(
      url,
      headers: _baseHeaders,
      body: jsonEncode({
        'name':     name,
        'email':    email,
        'password': password,
        'phone':    phone,
      }),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// GET /api/customer/profile (needs customer JWT token)
  Future<Map<String, dynamic>> getCustomerProfile(String token) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/customer/profile');
    final response = await _client.get(
      url,
      headers: {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // ==========================================================
  // ORDERS ENDPOINTS (Friend 1 — Admin-backend)
  // ==========================================================

  /// GET /api/orders-view — all orders (admin only)
  Future<List<Map<String, dynamic>>> getOrders() async {
    final headers = await _authHeaders;
    final url = Uri.parse('\${AppConstants.adminBaseUrl}/orders-view');
    final response = await _client.get(url, headers: headers);
    return List<Map<String, dynamic>>.from(_handleResponse(response) as List);
  }

  /// POST /api/orders-view — place a new order
  Future<Map<String, dynamic>> placeOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String deliveryAddress,
    required String deliveryCity,
    required double totalAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('\${AppConstants.adminBaseUrl}/orders-view');
    final response = await _client.post(
      url,
      headers: _baseHeaders,
      body: jsonEncode({
        'customerName':    customerName,
        'customerEmail':   customerEmail,
        'customerPhone':   customerPhone,
        'deliveryAddress': deliveryAddress,
        'deliveryCity':    deliveryCity,
        'totalAmount':     totalAmount,
        'paymentMethod':   paymentMethod,
        'items':           items,
      }),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // ==========================================================
  // NOTIFICATIONS ENDPOINTS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final headers = await _authHeaders;
    final url = Uri.parse('\${AppConstants.adminBaseUrl}/admin/notifications');
    final response = await _client.get(url, headers: headers);
    return List<Map<String, dynamic>>.from(_handleResponse(response) as List);
  }

  Future<void> markNotificationRead(int id) async {
    final headers = await _authHeaders;
    final url = Uri.parse('\${AppConstants.adminBaseUrl}/admin/notifications/\$id/read');
    await _client.patch(url, headers: headers);
  }

  Future<void> markAllNotificationsRead() async {
    final headers = await _authHeaders;
    final url = Uri.parse('\${AppConstants.adminBaseUrl}/admin/notifications/read-all');
    await _client.patch(url, headers: headers);
  }

  // ==========================================================
  // REVIEWS ENDPOINTS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getReviews() async {
    final headers = await _authHeaders;
    final url = Uri.parse('\${AppConstants.adminBaseUrl}/admin/reviews');
    final response = await _client.get(url, headers: headers);
    return List<Map<String, dynamic>>.from(_handleResponse(response) as List);
  }

  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    final url = Uri.parse('\${AppConstants.adminBaseUrl}/admin/reviews/product/\$productId');
    final response = await _client.get(url, headers: _baseHeaders);
    return List<Map<String, dynamic>>.from(_handleResponse(response) as List);
  }

}
