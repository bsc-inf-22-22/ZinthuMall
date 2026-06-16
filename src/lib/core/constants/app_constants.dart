// =============================================================
// FILE: lib/core/constants/app_constants.dart
//
// UPDATED: Added real backend URLs matching both services
// ----------------------------------------------------------
// Admin Backend  → port 3000  (Friend 1 — auth + products)
// Inventory      → port 3001  (Friend 2 — stock management)
//
// IMPORTANT: When running the backends locally, your friend
// must change the inventory service to port 3001 because
// both default to 3000 and they will clash.
// In his main.ts change: app.listen(3001)
// =============================================================

class AppConstants {
  AppConstants._();

  // App info
  static const String appName    = 'Kachipapa Store';
  static const String appTagline = "Malawi's Premier Online Marketplace";
  static const String appVersion = '1.0.0';

  // ----------------------------------------------------------
  // BACKEND URLS
  // Development (local machine):
  //   Android emulator  → use 10.0.2.2 instead of localhost
  //   Chrome/Linux      → use localhost
  //
  // Change to your deployed server URL in production.
  // ----------------------------------------------------------
  static const String adminBaseUrl     = 'http://localhost:3000/api';
  static const String inventoryBaseUrl = 'http://localhost:3001';

  // If running on Android emulator, use these instead:
  // static const String adminBaseUrl     = 'http://10.0.2.2:3000/api';
  // static const String inventoryBaseUrl = 'http://10.0.2.2:3001';

  // ----------------------------------------------------------
  // PRODUCT CATEGORIES
  // Must match exactly what the backend stores in the DB
  // ----------------------------------------------------------
  static const String categoryMen      = 'mens_clothing';
  static const String categoryWomen    = 'womens_clothing';
  static const String categoryDomestic = 'domestics_home';

  // ----------------------------------------------------------
  // PACHANGU PAYMENT
  // ----------------------------------------------------------
  static const String pachanguBaseUrl = 'https://api.pachangu.com';
  static const String airtelMoneyCode = 'AIRTEL_MW';
  static const String tnmMpambaCode   = 'TNM_MW';

  // Currency
  static const String currencySymbol = 'MK';
  static const String currencyCode   = 'MWK';

  // ----------------------------------------------------------
  // SHARED PREFERENCES KEYS
  // ----------------------------------------------------------
  static const String prefAuthToken = 'auth_token';
  static const String prefUserId    = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefCartCount = 'cart_count';

  // Business rules
  static const int    defaultPageSize         = 20;
  static const double freeDeliveryThreshold   = 5000.0;
  static const int    lowStockThreshold       = 5; // matches inventory backend
}
