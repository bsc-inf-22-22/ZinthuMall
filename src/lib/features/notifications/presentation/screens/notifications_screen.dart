// =============================================================
// FILE: lib/features/notifications/presentation/screens/notifications_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Order Shipped! 🚚',
      'body': 'Your order #KAC002 has been shipped and is on its way.',
      'time': '2 hours ago', 'type': 'order', 'read': false,
    },
    {
      'title': 'Flash Sale Starts Now! 🔥',
      'body': 'Up to 50% off on selected items. Limited time only!',
      'time': '5 hours ago', 'type': 'promo', 'read': false,
    },
    {
      'title': 'Order Delivered ✅',
      'body': 'Your order #KAC001 has been delivered. How was it?',
      'time': 'Yesterday', 'type': 'order', 'read': true,
    },
    {
      'title': 'New Arrivals 👗',
      'body': 'Check out the latest women\'s collection just added.',
      'time': '2 days ago', 'type': 'promo', 'read': true,
    },
    {
      'title': 'Price Drop Alert 💰',
      'body': 'Classic Oxford Shirt is now MK 4,500 — was MK 6,900.',
      'time': '3 days ago', 'type': 'price', 'read': true,
    },
    {
      'title': 'Review Reminder ⭐',
      'body': 'How was your Classic Oxford Shirt? Leave a review.',
      'time': '4 days ago', 'type': 'review', 'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications${unread > 0 ? ' ($unread)' : ''}',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16,
            fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              for (final n in _notifications) n['read'] = true;
            }),
            child: Text('Mark all read',
              style: GoogleFonts.dmSans(
                color: AppTheme.primaryRed, fontSize: 12,
                fontWeight: FontWeight.w600))),
        ],
      ),
      body: _notifications.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _notifCard(_notifications[i], i),
            ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🔔', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 16),
      Text('No notifications yet',
        style: GoogleFonts.dmSans(
          fontSize: 16, color: AppTheme.textHint)),
    ]),
  );

  Widget _notifCard(Map<String, dynamic> notif, int index) {
    Color iconBg;
    IconData icon;
    switch (notif['type']) {
      case 'order':  iconBg = Colors.blue;   icon = Icons.local_shipping_outlined; break;
      case 'promo':  iconBg = Colors.orange; icon = Icons.local_offer_outlined; break;
      case 'price':  iconBg = Colors.green;  icon = Icons.trending_down; break;
      case 'review': iconBg = Colors.purple; icon = Icons.star_border; break;
      default:       iconBg = Colors.grey;   icon = Icons.notifications_outlined;
    }

    return GestureDetector(
      onTap: () => setState(() => notif['read'] = true),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif['read'] ? Colors.white : const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif['read']
                ? AppTheme.borderColor
                : AppTheme.primaryRed.withOpacity(0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconBg, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notif['title'],
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text(notif['body'],
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textSecondary,
                  height: 1.4)),
              const SizedBox(height: 4),
              Text(notif['time'],
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppTheme.textHint)),
            ],
          )),
          if (!notif['read'])
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle)),
        ]),
      ),
    );
  }
}
