// =============================================================
// FILE: lib/core/providers/customer_session_provider.dart
//
// The logged-in shopper (or null for guests). Persisted on the
// device so customers stay signed in between visits.
// =============================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';

class Customer {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? city;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.city,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
      };

  String get firstName => name.split(' ').first;
}

final customerSessionProvider =
    StateNotifierProvider<CustomerSessionNotifier, Customer?>((ref) => CustomerSessionNotifier());

class CustomerSessionNotifier extends StateNotifier<Customer?> {
  CustomerSessionNotifier() : super(null) {
    _restore();
  }

  final _api = ApiService();

  bool get isLoggedIn => state != null;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefCustomerToken);
    final json = prefs.getString(AppConstants.prefCustomerJson);
    if (token == null || json == null) return;
    state = Customer.fromJson(jsonDecode(json) as Map<String, dynamic>);

    // Refresh details in the background; sign out if the token expired.
    try {
      await refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
    }
  }

  Future<void> login(String email, String password) async {
    await _saveSession(await _api.loginCustomer(email: email, password: password));
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    await _saveSession(
        await _api.registerCustomer(name: name, email: email, password: password, phone: phone));
  }

  Future<void> refresh() async => _saveCustomer(Customer.fromJson(await _api.getCustomerProfile()));

  Future<void> updateProfile(Map<String, String> fields) async =>
      _saveCustomer(Customer.fromJson(await _api.updateCustomerProfile(fields)));

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefCustomerToken);
    await prefs.remove(AppConstants.prefCustomerJson);
    state = null;
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCustomerToken, response['access_token'] as String);
    await _saveCustomer(Customer.fromJson(response['customer'] as Map<String, dynamic>));
  }

  Future<void> _saveCustomer(Customer customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCustomerJson, jsonEncode(customer.toJson()));
    state = customer;
  }
}
