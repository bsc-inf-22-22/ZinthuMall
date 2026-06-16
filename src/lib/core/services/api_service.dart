// =============================================================
// FILE: lib/core/services/api_service.dart
//
// PURPOSE:
//   Single place for ALL HTTP calls to the NestJS backend.
//   No screen or widget talks to the API directly —
//   everything goes through this service.
//
//   WHY ONE SERVICE FILE?
//   If the base URL changes or the token header format changes,
//   you fix it in ONE place. Every screen benefits automatically.
//
//   BACKEND URLS:
//   Admin Backend  → http://localhost:3000  (Friend 1)
//   Inventory      → http://localhost:3001  (Friend 2)
//
//   CHANGE THESE when deployed to a real server:
//   e.g. https://api.kachipapa.mw
// =============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../features/home/data/models/product_model.dart';

class ApiService {
  // ----------------------------------------------------------
  // SINGLETON PATTERN
  // Only ONE instance of ApiService exists in the whole app.
  // This prevents creating multiple HTTP clients.
  //
  // How it works:
  //   factory ApiService() → always returns _instance
  //   static final _instance → created once, lives forever
  // ----------------------------------------------------------
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  // ----------------------------------------------------------
  // HEADERS
  // _baseHeaders → for public routes (no auth needed)
  // _authHeaders → for protected routes (needs JWT token)
  // ----------------------------------------------------------
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  // authHeaders fetches the stored JWT token and adds it
  // The backend checks: Authorization: Bearer <token>
  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefAuthToken) ?? '';
    return {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // ----------------------------------------------------------
  // STORE & RETRIEVE AUTH TOKEN
  // After login, we save the JWT token to SharedPreferences.
  // It stays there until the user logs out.
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
  // Base: http://localhost:3000/api/admin/auth
  // ==========================================================

  // ----------------------------------------------------------
  // REGISTER ADMIN
  // POST /api/admin/auth/register
  // Body: { "email": "...", "password": "..." }
  // Response: { "message": "Admin registered successfully" }
  //
  // NOTE: Only works ONCE. Second call returns 409 Conflict.
  // Your friend's code: if (count > 0) throw ConflictException
  // ----------------------------------------------------------
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

  // ----------------------------------------------------------
  // LOGIN ADMIN
  // POST /api/admin/auth/login
  // Body: { "email": "...", "password": "..." }
  // Response: { "access_token": "eyJhbGci..." }
  //
  // After successful login:
  //   1. We get back access_token
  //   2. We save it to SharedPreferences
  //   3. All future protected requests include it in headers
  // ----------------------------------------------------------
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

    // Extract and save the token
    final token = data['access_token'] as String;
    await saveToken(token);
    return token;
  }

  // ==========================================================
  // PRODUCTS ENDPOINTS
  // Base: http://localhost:3000/api/products
  // ==========================================================

  // ----------------------------------------------------------
  // GET ALL PRODUCTS (public — no auth needed)
  // GET /api/products
  // Response: [ { id, name, category, price, stock, ... }, ... ]
  // ----------------------------------------------------------
  Future<List<ProductModel>> getProducts() async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/products');
    final response = await _client.get(url, headers: _baseHeaders);
    final data = _handleResponse(response);

    // The response is a List of product JSON objects
    // We map each one through ProductModel.fromJson()
    return (data as List)
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ----------------------------------------------------------
  // GET PRODUCTS BY CATEGORY (public)
  // GET /api/products/category/:category
  // e.g. GET /api/products/category/mens_clothing
  // ----------------------------------------------------------
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/products/category/$category');
    final response = await _client.get(url, headers: _baseHeaders);
    final data = _handleResponse(response);
    return (data as List)
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ----------------------------------------------------------
  // SEARCH PRODUCTS (public)
  // GET /api/products/search?q=shirt
  // ----------------------------------------------------------
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

  // ----------------------------------------------------------
  // GET SINGLE PRODUCT (public)
  // GET /api/products/:id
  // ----------------------------------------------------------
  Future<ProductModel> getProduct(int id) async {
    final url = Uri.parse('${AppConstants.adminBaseUrl}/products/$id');
    final response = await _client.get(url, headers: _baseHeaders);
    final data = _handleResponse(response);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  // ----------------------------------------------------------
  // CREATE PRODUCT (protected — needs JWT)
  // POST /api/products
  // Body: multipart/form-data (because it includes an image file)
  //
  // NOTE: Your friend used FileInterceptor('image') — this means
  // the image is uploaded as a multipart form field named 'image'.
  // The other fields (name, price, etc.) are also form fields.
  // We use MultipartRequest for this, not regular JSON.
  // ----------------------------------------------------------
  Future<ProductModel> createProduct({
    required String name,
    required String category,
    required double price,
    required int    stock,
    int?    discount,
    String? description,
    List<String>? sizes,
    // imageBytes is the actual file data — null if no image
  }) async {
    final token  = await getToken();
    final url    = Uri.parse('${AppConstants.adminBaseUrl}/products');

    // MultipartRequest for file + data combined
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name']     = name
      ..fields['category'] = category
      ..fields['price']    = price.toString()
      ..fields['stock']    = stock.toString();

    if (discount    != null) request.fields['discount']    = discount.toString();
    if (description != null) request.fields['description'] = description;
    if (sizes != null && sizes.isNotEmpty) {
      // sizes is a simple-array in TypeORM — send as comma-separated
      request.fields['sizes'] = sizes.join(',');
    }

    final streamedResponse = await request.send();
    final response         = await http.Response.fromStream(streamedResponse);
    final data             = _handleResponse(response);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  // ----------------------------------------------------------
  // UPDATE PRODUCT (protected — needs JWT)
  // PATCH /api/products/:id
  // ----------------------------------------------------------
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> fields) async {
    final token   = await getToken();
    final url     = Uri.parse('${AppConstants.adminBaseUrl}/products/$id');
    final request = http.MultipartRequest('PATCH', url)
      ..headers['Authorization'] = 'Bearer $token';

    fields.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    final streamedResponse = await request.send();
    final response         = await http.Response.fromStream(streamedResponse);
    final data             = _handleResponse(response);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  // ----------------------------------------------------------
  // DELETE PRODUCT (protected — needs JWT)
  // DELETE /api/products/:id
  // ----------------------------------------------------------
  Future<void> deleteProduct(int id) async {
    final headers = await _authHeaders;
    final url     = Uri.parse('${AppConstants.adminBaseUrl}/products/$id');
    final response = await _client.delete(url, headers: headers);
    _handleResponse(response);
  }

  // ==========================================================
  // INVENTORY ENDPOINTS
  // Base: http://localhost:3001/inventory  (Friend 2's service)
  // ==========================================================

  // ----------------------------------------------------------
  // GET ALL INVENTORY
  // GET /inventory
  // Returns products with quantityInStock and status
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getInventory() async {
    final url      = Uri.parse('${AppConstants.inventoryBaseUrl}/inventory');
    final response = await _client.get(url, headers: _baseHeaders);
    final data     = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ----------------------------------------------------------
  // GET LOW STOCK (< 5 units)
  // GET /inventory/low-stock
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getLowStock() async {
    final url      = Uri.parse('${AppConstants.inventoryBaseUrl}/inventory/low-stock');
    final response = await _client.get(url, headers: _baseHeaders);
    final data     = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ----------------------------------------------------------
  // GET OUT OF STOCK
  // GET /inventory/out-of-stock
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getOutOfStock() async {
    final url      = Uri.parse('${AppConstants.inventoryBaseUrl}/inventory/out-of-stock');
    final response = await _client.get(url, headers: _baseHeaders);
    final data     = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ----------------------------------------------------------
  // ADD STOCK
  // POST /inventory/add-stock
  // Body: { "productId": 1, "quantity": 50, "notes": "..." }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> addStock({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final url = Uri.parse('${AppConstants.inventoryBaseUrl}/inventory/add-stock');
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

  // ----------------------------------------------------------
  // REDUCE STOCK
  // POST /inventory/reduce-stock
  // Body: { "productId": 1, "quantity": 5, "notes": "SALE" }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> reduceStock({
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final url = Uri.parse('${AppConstants.inventoryBaseUrl}/inventory/reduce-stock');
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

  // ----------------------------------------------------------
  // GET TRANSACTION HISTORY for a product
  // GET /inventory/history/:productId
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getTransactionHistory(int productId) async {
    final url = Uri.parse(
      '${AppConstants.inventoryBaseUrl}/inventory/history/$productId',
    );
    final response = await _client.get(url, headers: _baseHeaders);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // ==========================================================
  // RESPONSE HANDLER
  // Called after every HTTP request.
  // Checks the status code and throws a readable error if
  // something went wrong, otherwise returns parsed JSON.
  //
  // HTTP status codes:
  //   2xx → success
  //   400 → bad request (validation failed)
  //   401 → unauthorized (wrong password or expired token)
  //   404 → not found
  //   409 → conflict (admin already registered)
  //   500 → server error
  // ==========================================================
  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success — return the parsed JSON
      return body;
    }

    // Extract the error message from NestJS error format:
    // { "statusCode": 401, "message": "Invalid credentials", "error": "Unauthorized" }
    final message = body['message'] ?? 'Something went wrong';

    switch (response.statusCode) {
      case 400:
        throw ApiException('Validation error: $message');
      case 401:
        throw ApiException('Authentication failed: $message');
      case 404:
        throw ApiException('Not found: $message');
      case 409:
        throw ApiException('Conflict: $message');
      case 500:
        throw ApiException('Server error. Please try again later.');
      default:
        throw ApiException('Error ${response.statusCode}: $message');
    }
  }
}

// ----------------------------------------------------------
// CUSTOM EXCEPTION CLASS
// We throw this instead of generic Exception so callers can
// catch ApiException specifically and show proper error messages.
//
// Usage in UI:
//   try {
//     await api.loginAdmin(email: ..., password: ...);
//   } on ApiException catch (e) {
//     setState(() => _errorMessage = e.message);
//   }
// ----------------------------------------------------------
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
