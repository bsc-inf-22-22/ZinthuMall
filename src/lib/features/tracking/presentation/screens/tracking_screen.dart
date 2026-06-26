// =============================================================
// FILE: lib/features/tracking/presentation/screens/tracking_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class TrackingScreen extends StatelessWidget {
  final String? orderId;
  const TrackingScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final id = orderId ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        '#KAC002';

    final steps = [
      {
        'title': 'Order Placed',
        'subtitle': 'Your order has been confirmed',
        'time': 'Jun 18, 2026 · 10:30 AM',
        'done': true,
      },
      {
        'title': 'Payment Confirmed',
        'subtitle': 'Payment received via TNM Mpamba',
        'time': 'Jun 18, 2026 · 10:35 AM',
        'done': true,
      },
      {
        'title': 'Preparing Order',
        'subtitle': 'Seller is packing your items',
        'time': 'Jun 18, 2026 · 2:00 PM',
        'done': true,
      },
      {
        'title': 'Shipped',
        'subtitle': 'Your order is on its way',
        'time': 'Jun 19, 2026 · 9:00 AM',
        'done': true,
      },
      {
        'title': 'Out for Delivery',
        'subtitle': 'Delivery agent is nearby',
        'time': 'Expected today',
        'done': false,
      },
      {
        'title': 'Delivered',
        'subtitle': 'Package delivered successfully',
        'time': 'Pending',
        'done': false,
      },
    ];

    final currentStep = steps.lastIndexWhere((s) => s['done'] == true);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Track Order $id',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 15,
            fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF3D0012)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Text('🚚', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Out for Delivery',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Expected delivery: Today by 5:00 PM',
                style: GoogleFonts.dmSans(
                  color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),

          // Order details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor)),
            child: Column(children: [
              _detailRow('Order ID', id),
              const Divider(height: 16),
              _detailRow('Delivery Address', 'Blantyre CBD'),
              const Divider(height: 16),
              _detailRow('Items', '2 items'),
              const Divider(height: 16),
              _detailRow('Payment', 'TNM Mpamba · MK 27,000'),
            ]),
          ),
          const SizedBox(height: 20),

          // Tracking timeline
          Text('Tracking Timeline',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor)),
            child: Column(
              children: steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isLast = i == steps.length - 1;
                final isDone = step['done'] as bool;
                final isCurrent = i == currentStep + 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    Column(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.primaryRed
                              : isCurrent
                                  ? Colors.orange
                                  : const Color(0xFFF4F4F2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? AppTheme.primaryRed
                                : isCurrent
                                    ? Colors.orange
                                    : AppTheme.borderColor,
                            width: 2)),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          size: isDone ? 14 : 8,
                          color: isDone || isCurrent
                              ? Colors.white
                              : AppTheme.borderColor)),
                      if (!isLast)
                        Container(
                          width: 2, height: 40,
                          color: isDone
                              ? AppTheme.primaryRed
                              : AppTheme.borderColor),
                    ]),
                    const SizedBox(width: 16),
                    // Step content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step['title'] as String,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDone
                                    ? AppTheme.textPrimary
                                    : AppTheme.textHint)),
                            const SizedBox(height: 2),
                            Text(step['subtitle'] as String,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                            const SizedBox(height: 2),
                            Text(step['time'] as String,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppTheme.textHint)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Contact support
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor)),
            child: Row(children: [
              const Icon(Icons.support_agent_outlined,
                color: AppTheme.primaryRed, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need help?',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('Contact us about your order',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textHint)),
                ],
              )),
              TextButton(
                onPressed: () {},
                child: Text('Contact',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w700))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Row(children: [
    Text(label, style: GoogleFonts.dmSans(
      fontSize: 13, color: AppTheme.textHint)),
    const Spacer(),
    Text(value, style: GoogleFonts.dmSans(
      fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}
