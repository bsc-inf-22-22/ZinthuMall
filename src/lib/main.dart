// =============================================================
// FILE: lib/main.dart
//
// UPDATED:
//   1. Wrapped app in ProviderScope — REQUIRED by Riverpod.
//      Without this, any ref.watch() or ref.read() will crash.
//      ProviderScope is the container that holds ALL providers.
//
//   2. Added /admin route so the homepage can have a hidden
//      button to navigate to the admin login screen.
//
//   HOW ADMIN + HOMEPAGE SHARE STATE:
//   Both screens live inside the same ProviderScope.
//   That means they share the same productsProvider instance.
//   Admin adds a product → productsProvider updates →
//   homepage rebuilds automatically. No extra wiring needed.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // NEW
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/admin/presentation/screens/admin_login_screen.dart';
import 'features/admin/presentation/screens/admin_register_screen.dart';
import 'features/category/presentation/screens/home_category_screen.dart';
import 'features/category/presentation/screens/mens_category_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    // ProviderScope MUST wrap your entire app.
    // It creates the container that stores all Riverpod providers.
    const ProviderScope(
      child: KachipapaStoreApp(),
    ),
  );
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
        '/home':          (_) => const HomeScreen(),
        '/admin':         (_) => const AdminLoginScreen(),
        '/admin/register':(_) => const AdminRegisterScreen(),
        '/category/home': (_) => const HomeCategoryScreen(),
        '/category/mens': (_) => const MensCategoryScreen(),
      },
    );
  }
}
