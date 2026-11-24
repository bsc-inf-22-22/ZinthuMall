// =============================================================
// FILE: lib/features/profile/presentation/screens/profile_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/customer_data_providers.dart';
import '../../../../core/providers/customer_session_provider.dart';
import '../../../../core/providers/products_provider.dart';
import '../../../../core/providers/wishlist_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerSessionProvider);

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
            style: GoogleFonts.dmSans(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (customer != null)
            IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined, color: Colors.black54),
              onPressed: () => _editProfile(context, ref, customer),
            ),
        ],
      ),
      body: customer == null ? const _LoggedOutView() : _LoggedInView(customer: customer),
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref, Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(customer: customer),
    );
  }
}

// ═══════════════════════════════════════════════
//  LOGGED OUT
// ═══════════════════════════════════════════════
class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('👤', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text('Sign in to your account',
                style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Access your orders, wishlist and more',
                textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 14)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                ),
                child: Text('Create Account',
                    style: GoogleFonts.dmSans(color: AppTheme.primaryRed, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/tracking'),
              icon: const Icon(Icons.local_shipping_outlined, color: AppTheme.textSecondary),
              label: Text('Track an order without an account',
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
            ),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════
//  LOGGED IN
// ═══════════════════════════════════════════════
class _LoggedInView extends ConsumerWidget {
  final Customer customer;
  const _LoggedInView({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider).value?.length;
    final reviews = ref.watch(myReviewsProvider).value?.length;
    final wishlist = ref.watch(wishlistProvider).length;

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: () async {
        ref.invalidate(myOrdersProvider);
        ref.invalidate(myReviewsProvider);
        await ref.read(customerSessionProvider.notifier).refresh().catchError((_) {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
                child: Center(
                  child: Text(customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
                      style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              Text(customer.name, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(customer.email, style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 13)),
              if (customer.phone != null) ...[
                const SizedBox(height: 4),
                Text(customer.phone!, style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 13)),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              _statItem(orders?.toString() ?? '–', 'Orders'),
              _divider(),
              _statItem('$wishlist', 'Wishlist'),
              _divider(),
              _statItem(reviews?.toString() ?? '–', 'Reviews'),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            child: Column(children: [
              _menuItem(Icons.shopping_bag_outlined, 'My Orders', 'View and track your orders',
                  () => Navigator.pushNamed(context, '/orders')),
              _menuDivider(),
              _menuItem(Icons.favorite_border, 'Wishlist', 'Items you saved',
                  () => Navigator.pushNamed(context, '/wishlist')),
              _menuDivider(),
              _menuItem(Icons.location_on_outlined, 'Delivery Address',
                  customer.address == null ? 'Add your delivery address' : '${customer.address}, ${customer.city ?? ''}',
                  () => Navigator.pushNamed(context, '/addresses')),
              _menuDivider(),
              _menuItem(Icons.star_border_outlined, 'My Reviews', 'Reviews you have written',
                  () => Navigator.pushNamed(context, '/reviews')),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            child: Column(children: [
              _menuItem(Icons.help_outline, 'Help & Support', 'Contact Kachipapa Store', () => _showSupport(context, ref)),
              _menuDivider(),
              _menuItem(Icons.info_outline, 'About Kachipapa', 'Version ${AppConstants.appVersion}', () {
                showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.appVersion,
                  applicationLegalese: '© ${DateTime.now().year} Kachipapa Store. Made in Malawi.',
                );
              }),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            child: _menuItem(Icons.logout, 'Sign Out', '', () => _confirmLogout(context, ref), isDestructive: true),
          ),
          const SizedBox(height: 32),
          Text('🇲🇼 Made in Malawi', style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 12)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showSupport(BuildContext context, WidgetRef ref) {
    final settings = ref.read(storeSettingsProvider).value ?? const {};
    final lines = [
      if (settings['storePhone'] != null) '📞 ${settings['storePhone']}',
      if (settings['storeEmail'] != null) '✉️ ${settings['storeEmail']}',
      if (settings['storeAddress'] != null) '📍 ${settings['storeAddress']}',
    ];
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Help & Support', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          lines.isEmpty ? 'Contact details will be available soon.' : lines.join('\n\n'),
          style: GoogleFonts.dmSans(height: 1.4),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: GoogleFonts.dmSans())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(customerSessionProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sign Out', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) => Expanded(
        child: Column(children: [
          Text(value, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textHint)),
        ]),
      );

  Widget _divider() => Container(width: 1, height: 40, color: AppTheme.borderColor);

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) =>
      ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFF4F4F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isDestructive ? Colors.red : AppTheme.textSecondary),
        ),
        title: Text(title,
            style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: isDestructive ? Colors.red : AppTheme.textPrimary)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textHint))
            : null,
        trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
        onTap: onTap,
      );

  Widget _menuDivider() => const Divider(height: 1, indent: 70, endIndent: 16);
}

// ═══════════════════════════════════════════════
//  EDIT PROFILE
// ═══════════════════════════════════════════════
class _EditProfileSheet extends ConsumerStatefulWidget {
  final Customer customer;
  const _EditProfileSheet({required this.customer});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.customer.name);
  late final _phone = TextEditingController(text: widget.customer.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(customerSessionProvider.notifier).updateProfile({
        'name': _name.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit Profile', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              validator: (v) => v != null && v.trim().isNotEmpty && !RegExp(r'^(\+?265|0)\d{8,9}$').hasMatch(v.trim())
                  ? 'Enter a valid Malawi number, e.g. 0881234567'
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
          ]),
        ),
      );
}
