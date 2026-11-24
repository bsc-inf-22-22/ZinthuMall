// =============================================================
// FILE: lib/core/utils/format.dart
// =============================================================

import 'package:intl/intl.dart';

final _mk = NumberFormat('#,##0', 'en_US');

/// Formats an amount in Malawi Kwacha, e.g. 1250000 → "MK 1,250,000".
String formatMK(num amount) => 'MK ${_mk.format(amount)}';

/// Formats an ISO date from the API, e.g. "24 Nov 2026".
String formatDate(String? iso) {
  if (iso == null) return '';
  final date = DateTime.tryParse(iso);
  return date == null ? '' : DateFormat('d MMM yyyy').format(date.toLocal());
}

/// Human-readable labels for order and payment statuses from the API.
String statusLabel(String status) => switch (status) {
      'pending' => 'Pending',
      'processing' => 'Processing',
      'shipped' => 'Shipped',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      'paid' => 'Paid',
      'failed' => 'Failed',
      'refunded' => 'Refunded',
      _ => status,
    };

String paymentMethodLabel(String? method) => switch (method) {
      'airtel_money' => 'Airtel Money',
      'tnm_mpamba' => 'TNM Mpamba',
      'cash' => 'Cash on Delivery',
      _ => method ?? '',
    };
