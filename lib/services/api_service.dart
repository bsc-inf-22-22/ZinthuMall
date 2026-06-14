// ─────────────────────────────────────────────────────────────────────────────
//  lib/services/api_service.dart
//
//  HOW TO USE:
//  1. Change ApiConfig.baseUrl to your friend's server address.
//  2. All endpoints are listed in ApiConfig — share this file with your friend
//     so he builds the backend to match these exact URLs.
//  3. After a user logs in, call ApiService().setToken(token) once.
//     Every request after that will automatically send the auth header.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;


// ═════════════════════════════════════════════════════════════════════════════
//  CONFIG  ←  Your friend only needs the baseUrl below
// ═════════════════════════════════════════════════════════════════════════════
class ApiConfig {
  // ▼▼▼  Change this once the backend server is live  ▼▼▼
  static const String baseUrl = 'https://api.kachipapa.mw/v1';
  // ▲▲▲  e.g. 'http://192.168.1.5:8000/api/v1' for local testing  ▲▲▲

  // ── Auth ─────────────────────────────────────────────────────────────────
  // POST   /auth/register        body: { name, email, phone, password }
  static const String register       = '/auth/register';

  // POST   /auth/login           body: { email, password }
  //        response: { token, user: {...} }
  static const String login          = '/auth/login';

  // POST   /auth/logout          header: Bearer token
  static const String logout         = '/auth/logout';

  // GET    /auth/me              header: Bearer token
  //        response: { id, name, email, phone, ... }
  static const String me             = '/auth/me';

  // ── Products ─────────────────────────────────────────────────────────────
  // GET    /products             query params below
  //        ?category=shirts,jackets   comma-separated slugs
  //        ?price_min=1000
  //        ?price_max=20000
  //        ?condition=new|used
  //        ?min_rating=4
  //        ?sort=popular|price_asc|price_desc|newest|top_rated
  //        ?q=search+term
  //        ?page=1&per_page=20
  //        response: { total, page, per_page, products: [ Product, ... ] }
  static const String products       = '/products';

  // GET    /products/:id
  //        response: Product object
  static String productById(int id)  => '/products/$id';

  // GET    /products/search      ?q=term  (shorthand for /products?q=)
  static const String search         = '/products/search';

  // ── Categories ───────────────────────────────────────────────────────────
  // GET    /categories
  //        response: [ { id, name, slug, image_url }, ... ]
  static const String categories     = '/categories';

  // GET    /categories/:slug/products   same query params as /products
  //        response: { total, page, per_page, products: [ Product, ... ] }
  static String categoryProducts(String slug) => '/categories/$slug/products';

  // ── Cart ─────────────────────────────────────────────────────────────────
  // GET    /cart                 response: { item_count, total_price, items: [ CartItem, ... ] }
  static const String cart           = '/cart';

  // POST   /cart                 body: { product_id, quantity }
  //        response: updated cart
  static const String cartAdd        = '/cart';

  // PUT    /cart/items/:id       body: { quantity }
  //        response: updated cart item
  static String cartItem(int id)     => '/cart/items/$id';

  // DELETE /cart/items/:id
  static String cartItemDelete(int id) => '/cart/items/$id';

  // DELETE /cart                 clears entire cart
  static const String cartClear      = '/cart';

  // ── Wishlist ──────────────────────────────────────────────────────────────
  // GET    /wishlist             response: { items: [ Product, ... ] }
  static const String wishlist       = '/wishlist';

  // POST   /wishlist             body: { product_id }
  static const String wishlistAdd    = '/wishlist';

  // DELETE /wishlist/items/:id
  static String wishlistItem(int id) => '/wishlist/items/$id';

  // ── Orders ────────────────────────────────────────────────────────────────
  // GET    /orders               response: [ Order, ... ]
  static const String orders         = '/orders';

  // POST   /orders               body: { payment_method, delivery_address }
  //        (creates order from current cart)
  static const String orderCreate    = '/orders';

  // GET    /orders/:id
  static String orderById(int id)    => '/orders/$id';

  // ── Seller ────────────────────────────────────────────────────────────────
  // GET    /seller/products      response: seller's own listings
  static const String sellerProducts = '/seller/products';

  // POST   /seller/products      body: { title, price, category, ... }
  static const String sellerList     = '/seller/products';

  // PUT    /seller/products/:id
  static String sellerProduct(int id) => '/seller/products/$id';

  // DELETE /seller/products/:id
  static String sellerDelete(int id)  => '/seller/products/$id';

  // ── Payments ──────────────────────────────────────────────────────────────
  // POST   /payments/airtel      body: { order_id, phone }
  static const String payAirtel      = '/payments/airtel';

  // POST   /payments/mpamba      body: { order_id, phone }
  static const String payMpamba      = '/payments/mpamba';

  // ── Helper: build full URI with optional query params ─────────────────────
  static Uri uri(String endpoint, {Map<String, String>? query}) =>
      Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: query);
}

// ═════════════════════════════════════════════════════════════════════════════
//  SERVICE  (singleton)
// ═════════════════════════════════════════════════════════════════════════════
class ApiService {
  static final ApiService _instance = ApiService._();
  ApiService._();
  factory ApiService() => _instance;

  String? _token;

  void setToken(String token) => _token = token;
  void clearToken()           => _token = null;
  bool get isLoggedIn         => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<dynamic> get(String endpoint, {Map<String, String>? query}) async {
    final res = await http.get(ApiConfig.uri(endpoint, query: query),
        headers: _headers);
    return _handle(res);
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<dynamic> post(String endpoint, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      ApiConfig.uri(endpoint),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  // ── PUT ───────────────────────────────────────────────────────────────────
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final res = await http.put(
      ApiConfig.uri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<dynamic> delete(String endpoint) async {
    final res = await http.delete(ApiConfig.uri(endpoint), headers: _headers);
    return _handle(res);
  }

  // ── Response handler ──────────────────────────────────────────────────────
  dynamic _handle(http.Response res) {
    if (res.body.isEmpty) return null;
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map)
        ? (body['message'] ?? body['error'] ?? 'Error ${res.statusCode}')
        : 'Error ${res.statusCode}';
    throw ApiException(res.statusCode, msg.toString());
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  EXCEPTION
// ═════════════════════════════════════════════════════════════════════════════
class ApiException implements Exception {
  final int    statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}