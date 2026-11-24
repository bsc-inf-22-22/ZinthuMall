// =============================================================
// FILE: lib/core/providers/customer_data_providers.dart
//
// Data that belongs to the logged-in customer. Each provider
// reloads automatically when the customer logs in or out.
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'customer_session_provider.dart';

final myOrdersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(customerSessionProvider) == null) return [];
  return ApiService().getMyOrders();
});

final myReviewsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(customerSessionProvider) == null) return [];
  return ApiService().getMyReviews();
});
