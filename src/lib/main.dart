import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/admin/presentation/screens/admin_login_screen.dart';
import 'features/admin/presentation/screens/admin_register_screen.dart';
import 'features/category/presentation/screens/home_category_screen.dart';
import 'features/category/presentation/screens/mens_category_screen.dart';
import 'features/category/presentation/screens/womens_category_screen.dart';
import 'features/cart/presentation/screens/cart_screen.dart';
import 'features/checkout/presentation/screens/checkout_screen.dart';
import 'features/auth/presentation/screens/customer_auth_screen.dart';
import 'features/seller/presentation/screens/seller_dashboard_screen.dart';

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
        '/seller':          (_) => const SellerDashboardScreen(),
      },
    );
  }
}
