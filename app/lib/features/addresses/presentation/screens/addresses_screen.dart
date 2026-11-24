// =============================================================
// FILE: lib/features/addresses/presentation/screens/addresses_screen.dart
//
// The customer's default delivery address, saved to their account
// and used to pre-fill checkout.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/malawi_cities.dart';
import '../../../../core/providers/customer_session_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_states.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address;
  String _city = malawiCities.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(customerSessionProvider);
    _address = TextEditingController(text: customer?.address ?? '');
    if (customer?.city != null && malawiCities.contains(customer!.city)) _city = customer.city!;
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(customerSessionProvider.notifier).updateProfile({
        'address': _address.text.trim(),
        'city': _city,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery address saved')));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(customerSessionProvider) != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Delivery Address',
            style: GoogleFonts.dmSans(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: !loggedIn
          ? const SignInPrompt(message: 'Sign in to save a delivery address.')
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Text('We use this address to pre-fill your checkout.',
                        style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Area, street, house number or landmark',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your delivery address' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _city,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.location_city_outlined)),
                      items: [for (final c in malawiCities) DropdownMenuItem(value: c, child: Text(c))],
                      onChanged: (v) => setState(() => _city = v ?? _city),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Address'),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}
