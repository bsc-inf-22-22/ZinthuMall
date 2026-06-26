// =============================================================
// FILE: lib/features/addresses/presentation/screens/addresses_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  int _defaultIndex = 0;

  final List<Map<String, dynamic>> _addresses = [
    {
      'label': 'Home',
      'name': 'Chisomo Banda',
      'phone': '0881234567',
      'address': 'House 12, Area 47',
      'city': 'Lilongwe',
      'icon': '🏠',
    },
    {
      'label': 'Work',
      'name': 'Chisomo Banda',
      'phone': '0881234567',
      'address': 'Office Block B, City Centre',
      'city': 'Lilongwe',
      'icon': '🏢',
    },
  ];

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
        title: Text('Delivery Addresses',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16,
            fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _addressCard(i),
          ),
        ),
        // Add address button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => _showAddressForm(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Add New Address',
              style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
          )),
        ),
      ]),
    );
  }

  Widget _addressCard(int index) {
    final addr = _addresses[index];
    final isDefault = index == _defaultIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault
              ? AppTheme.primaryRed
              : AppTheme.borderColor,
          width: isDefault ? 2 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(addr['icon'], style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(addr['label'],
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(width: 8),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: Text('Default',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primaryRed,
                  fontSize: 10, fontWeight: FontWeight.w700))),
          const Spacer(),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert,
              color: AppTheme.textHint),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'default', child: Text('Set as Default')),
              const PopupMenuItem(
                value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                  style: TextStyle(color: Colors.red))),
            ],
            onSelected: (v) {
              if (v == 'default') {
                setState(() => _defaultIndex = index);
              } else if (v == 'delete' && _addresses.length > 1) {
                setState(() => _addresses.removeAt(index));
              }
            },
          ),
        ]),
        const SizedBox(height: 10),
        _infoRow(Icons.person_outlined, addr['name']),
        const SizedBox(height: 4),
        _infoRow(Icons.phone_outlined, addr['phone']),
        const SizedBox(height: 4),
        _infoRow(Icons.location_on_outlined,
          '${addr['address']}, ${addr['city']}'),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 14, color: AppTheme.textHint),
    const SizedBox(width: 6),
    Text(text, style: GoogleFonts.dmSans(
      fontSize: 13, color: AppTheme.textSecondary)),
  ]);

  void _showAddressForm() {
    final nameCtrl    = TextEditingController();
    final phoneCtrl   = TextEditingController();
    final addressCtrl = TextEditingController();
    String selectedCity = 'Lilongwe';
    String selectedLabel = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
            Text('Add New Address',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // Label
            Row(children: ['Home', 'Work', 'Other'].map((label) =>
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setModalState(() => selectedLabel = label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedLabel == label
                          ? AppTheme.primaryRed
                          : const Color(0xFFF4F4F2),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(label,
                      style: GoogleFonts.dmSans(
                        color: selectedLabel == label
                            ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13))),
                ))).toList()),
            const SizedBox(height: 12),
            _formField(nameCtrl, 'Full Name', Icons.person_outlined),
            const SizedBox(height: 10),
            _formField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
              type: TextInputType.phone),
            const SizedBox(height: 10),
            _formField(addressCtrl, 'Street Address',
              Icons.location_on_outlined),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F2),
                borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCity,
                  isExpanded: true,
                  items: ['Lilongwe', 'Blantyre', 'Mzuzu', 'Zomba']
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c))).toList(),
                  onChanged: (v) =>
                      setModalState(() => selectedCity = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _addresses.add({
                    'label': selectedLabel,
                    'name': nameCtrl.text.isEmpty
                        ? 'My Address' : nameCtrl.text,
                    'phone': phoneCtrl.text,
                    'address': addressCtrl.text,
                    'city': selectedCity,
                    'icon': selectedLabel == 'Home' ? '🏠'
                        : selectedLabel == 'Work' ? '🏢' : '📍',
                  });
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              child: Text('Save Address',
                style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl, String hint, IconData icon,
    {TextInputType? type}) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textHint),
        filled: true,
        fillColor: const Color(0xFFF4F4F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryRed, width: 1.5))),
    );
}
