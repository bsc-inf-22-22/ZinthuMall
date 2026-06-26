// =============================================================
// FILE: lib/features/profile/presentation/screens/profile_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data — replace with real auth later
  final Map<String, String> _user = {
    'name':  'Chisomo Banda',
    'email': 'chisomo@gmail.com',
    'phone': '0881234567',
    'city':  'Lilongwe',
  };

  bool _isLoggedIn = true; // change to false to test logged out state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Account',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16,
            fontWeight: FontWeight.w700)),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black54),
              onPressed: () => _editProfile(),
            ),
        ],
      ),
      body: _isLoggedIn ? _loggedInView() : _loggedOutView(),
    );
  }

  // ═══════════════════════════════════════════════
  //  LOGGED OUT VIEW
  // ═══════════════════════════════════════════════
  Widget _loggedOutView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👤', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text('Sign in to your account',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Access your orders, wishlist and more',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppTheme.textHint, fontSize: 14)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              child: Text('Sign In',
                style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryRed),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              child: Text('Create Account',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    ),
  );

  // ═══════════════════════════════════════════════
  //  LOGGED IN VIEW
  // ═══════════════════════════════════════════════
  Widget _loggedInView() => SingleChildScrollView(
    child: Column(children: [
      // Profile header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Column(children: [
          // Avatar
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              shape: BoxShape.circle),
            child: Center(
              child: Text(
                _user['name']!.substring(0, 1).toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white, fontSize: 32,
                  fontWeight: FontWeight.w700))),
          ),
          const SizedBox(height: 12),
          Text(_user['name']!,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_user['email']!,
            style: GoogleFonts.dmSans(
              color: AppTheme.textHint, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_user['phone']!,
            style: GoogleFonts.dmSans(
              color: AppTheme.textHint, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 12),

      // Order stats
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          _statItem('0', 'Orders'),
          _divider(),
          _statItem('0', 'Wishlist'),
          _divider(),
          _statItem('0', 'Reviews'),
        ]),
      ),
      const SizedBox(height: 12),

      // Menu items
      Container(
        color: Colors.white,
        child: Column(children: [
          _menuItem(Icons.shopping_bag_outlined, 'My Orders',
            'View your order history', () => Navigator.pushNamed(context, '/orders')),
          _menuDivider(),
          _menuItem(Icons.favorite_border, 'Wishlist',
            'Items you saved', () => Navigator.pushNamed(context, '/wishlist')),
          _menuDivider(),
          _menuItem(Icons.location_on_outlined, 'Delivery Addresses',
            'Manage your addresses', () => Navigator.pushNamed(context, '/addresses')),
          _menuDivider(),
          _menuItem(Icons.payment_outlined, 'Payment Methods',
            'Airtel Money, TNM Mpamba', () {}),
          _menuDivider(),
          _menuItem(Icons.star_border_outlined, 'My Reviews',
            'Reviews you have written', () => Navigator.pushNamed(context, '/reviews')),
        ]),
      ),
      const SizedBox(height: 12),

      // Settings
      Container(
        color: Colors.white,
        child: Column(children: [
          _menuItem(Icons.notifications_outlined, 'Notifications',
            'Manage your alerts', () => Navigator.pushNamed(context, '/notifications')),
          _menuDivider(),
          _menuItem(Icons.help_outline, 'Help & Support',
            'FAQs and contact us', () {}),
          _menuDivider(),
          _menuItem(Icons.info_outline, 'About Kachipapa',
            'Version 1.0.0', () {}),
        ]),
      ),
      const SizedBox(height: 12),

      // Logout
      Container(
        color: Colors.white,
        child: _menuItem(
          Icons.logout, 'Sign Out', '',
          () => _confirmLogout(),
          isDestructive: true),
      ),
      const SizedBox(height: 32),

      Text('🇲🇼 Made in Malawi',
        style: GoogleFonts.dmSans(
          color: AppTheme.textHint, fontSize: 12)),
      const SizedBox(height: 16),
    ]),
  );

  Widget _statItem(String value, String label) => Expanded(
    child: Column(children: [
      Text(value, style: GoogleFonts.dmSans(
        fontSize: 20, fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary)),
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 12, color: AppTheme.textHint)),
    ]),
  );

  Widget _divider() => Container(
    width: 1, height: 40,
    color: AppTheme.borderColor);

  Widget _menuItem(
    IconData icon, String title, String subtitle,
    VoidCallback onTap, {bool isDestructive = false}) =>
    ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : const Color(0xFFF4F4F2),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon,
          size: 20,
          color: isDestructive ? Colors.red : AppTheme.textSecondary)),
      title: Text(title, style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDestructive ? Colors.red : AppTheme.textPrimary)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: GoogleFonts.dmSans(
              fontSize: 12, color: AppTheme.textHint))
          : null,
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right,
              color: AppTheme.textHint, size: 20),
      onTap: onTap,
    );

  Widget _menuDivider() => const Divider(
    height: 1, indent: 70, endIndent: 16);

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Edit Profile',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _editField('Full Name', _user['name']!),
          const SizedBox(height: 12),
          _editField('Phone Number', _user['phone']!),
          const SizedBox(height: 12),
          _editField('City', _user['city']!),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            child: Text('Save Changes',
              style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  Widget _editField(String label, String value) => TextField(
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(
        fontSize: 12, color: AppTheme.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF4F4F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.primaryRed, width: 1.5))),
    controller: TextEditingController(text: value),
  );

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
          style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLoggedIn = false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: Text('Sign Out',
              style: GoogleFonts.dmSans(color: Colors.white))),
        ],
      ),
    );
  }
}
