// ─────────────────────────────────────────────────────────────────────────────
//  lib/app_routes.dart
//
//  Paste the `routes` map into your MaterialApp in main.dart like this:
//
//  MaterialApp(
//    initialRoute: '/',
//    routes: AppRoutes.routes,
//    onGenerateRoute: AppRoutes.onGenerateRoute,  ← handles /product/:id
//  );
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// Import every screen below once you create them
import 'screens/mens_category.dart';
// import 'screens/home_screen.dart';
// import 'screens/womens_category.dart';
// import 'screens/domestics_category.dart';
// import 'screens/flash_deals_screen.dart';
// import 'screens/cart_screen.dart';
// import 'screens/wishlist_screen.dart';
// import 'screens/account_screen.dart';
// import 'screens/orders_screen.dart';
// import 'screens/seller_dashboard_screen.dart';
// import 'screens/seller_list_product_screen.dart';
// import 'screens/product_detail_screen.dart';

class AppRoutes {
  // ── Static named routes ───────────────────────────────────────
  static final Map<String, WidgetBuilder> routes = {
    '/':                (ctx) => const MensCategoryScreen(), // swap → HomeScreen
    '/mens':            (ctx) => const MensCategoryScreen(),
    // '/womens':       (ctx) => const WomensCategoryScreen(),
    // '/domestics':    (ctx) => const DomesticsCategoryScreen(),
    // '/deals':        (ctx) => const FlashDealsScreen(),
    // '/cart':         (ctx) => const CartScreen(),
    // '/wishlist':     (ctx) => const WishlistScreen(),
    // '/account':      (ctx) => const AccountScreen(),
    // '/orders':       (ctx) => const OrdersScreen(),
    // '/seller/dashboard': (ctx) => const SellerDashboardScreen(),
    // '/seller/list':  (ctx) => const SellerListProductScreen(),
  };

  // ── Dynamic routes (e.g. /product/42) ─────────────────────────
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';

    // /product/:id
    if (name.startsWith('/product/')) {
      final idStr = name.replaceFirst('/product/', '');
      final id    = int.tryParse(idStr);
      if (id != null) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MensCategoryScreen(), // swap → ProductDetailScreen(id: id)
        );
      }
    }

    // 404 fallback
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('404 – Page not found')),
      ),
    );
  }
}