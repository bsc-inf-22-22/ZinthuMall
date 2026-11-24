import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/data/models/product_model.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/admin/presentation/screens/admin_login_screen.dart';
import 'features/admin/presentation/screens/admin_register_screen.dart';
import 'features/category/presentation/screens/home_category_screen.dart';
import 'features/category/presentation/screens/mens_category_screen.dart';
import 'features/category/presentation/screens/womens_category_screen.dart';
import 'features/cart/presentation/screens/cart_screen.dart';
import 'features/checkout/presentation/screens/checkout_screen.dart';
import 'features/auth/presentation/screens/customer_auth_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/wishlist/presentation/screens/wishlist_screen.dart';
import 'features/orders/presentation/screens/order_history_screen.dart';
import 'features/reviews/presentation/screens/reviews_screen.dart';
import 'features/addresses/presentation/screens/addresses_screen.dart';
import 'features/tracking/presentation/screens/tracking_screen.dart';
import 'features/product/presentation/screens/product_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown]);
  runApp(const ProviderScope(child: KachipapaStoreApp()));
}

class KachipapaStoreApp extends StatelessWidget {
  const KachipapaStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kachipapa Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      // Routes that need arguments.
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/product':
            final product = settings.arguments;
            if (product is ProductModel) {
              return MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product), settings: settings);
            }
            break;
          case '/tracking':
            final args = settings.arguments;
            final map = args is Map ? args : const {};
            return MaterialPageRoute(
              builder: (_) => TrackingScreen(orderId: map['orderId'] as int?, phone: map['phone'] as String?),
              settings: settings,
            );
          case '/reviews':
            final args = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => ReviewsScreen(
                toReview: args is List ? List<Map<String, dynamic>>.from(args) : const [],
              ),
              settings: settings,
            );
        }
        return null;
      },
      // Unknown links (e.g. an old bookmark) go to the home page.
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const HomeScreen()),
      routes: {
        '/home':            (_) => const HomeScreen(),
        '/admin':           (_) => const AdminLoginScreen(),
        '/admin/register':  (_) => const AdminRegisterScreen(),
        '/category/home':   (_) => const HomeCategoryScreen(),
        '/category/mens':   (_) => const MensCategoryScreen(),
        '/category/womens': (_) => const WomensCategoryScreen(),
        '/cart':            (_) => const CartScreen(),
        '/checkout':        (_) => const CheckoutScreen(),
        '/login':           (_) => const CustomerAuthScreen(),
        '/register':        (_) => const CustomerAuthScreen(startOnRegister: true),
        '/seller':          (_) => const AdminLoginScreen(),
        '/search':          (_) => const SearchScreen(),
        '/profile':         (_) => const ProfileScreen(),
        '/wishlist':        (_) => const WishlistScreen(),
        '/orders':          (_) => const OrderHistoryScreen(),
        '/addresses':       (_) => const AddressesScreen(),
      },
    );
  }
}
