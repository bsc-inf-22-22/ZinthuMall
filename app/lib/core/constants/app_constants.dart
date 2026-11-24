// =============================================================
// FILE: lib/core/constants/app_constants.dart
// =============================================================

import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Kachipapa Store';
  static const String appTagline = "Malawi's Premier Online Marketplace";
  static const String appVersion = '1.0.0';

  // ----------------------------------------------------------
  // BACKEND URL
  //
  // Set at build time, e.g.
  //   flutter build web --dart-define=API_BASE_URL=https://kachipapa-api.onrender.com/api
  //
  // Without it, development defaults are used:
  //   web / desktop      → http://localhost:3000/api
  //   Android emulator   → http://10.0.2.2:3000/api
  // ----------------------------------------------------------
  static const String _apiBaseUrlFromBuild = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrlFromBuild.isNotEmpty) return _apiBaseUrlFromBuild;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // ----------------------------------------------------------
  // PRODUCT CATEGORIES (must match backend/src/products/categories.ts)
  // ----------------------------------------------------------
  static const String categoryMen = 'mens_clothing';
  static const String categoryWomen = 'womens_clothing';
  static const String categoryDomestic = 'domestics_home';

  static const Map<String, String> categoryLabels = {
    categoryMen: "Men's Clothing",
    categoryWomen: "Women's Clothing",
    categoryDomestic: 'Domestics & Home',
  };

  // ----------------------------------------------------------
  // PAYMENT METHODS (must match backend PAYMENT_METHODS)
  // ----------------------------------------------------------
  static const String paymentAirtel = 'airtel_money';
  static const String paymentMpamba = 'tnm_mpamba';
  static const String paymentCash = 'cash';

  // Currency
  static const String currencySymbol = 'MK';
  static const String currencyCode = 'MWK';

  // ----------------------------------------------------------
  // SHARED PREFERENCES KEYS
  // ----------------------------------------------------------
  static const String prefAdminToken = 'auth_token';
  static const String prefCustomerToken = 'customer_token';
  static const String prefCustomerJson = 'customer_json';

  // Business rules (the server's store settings are authoritative)
  static const double freeDeliveryThreshold = 5000.0;
  static const int lowStockThreshold = 5;
}
