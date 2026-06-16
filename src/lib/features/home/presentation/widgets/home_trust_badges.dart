// =============================================================
// FILE: lib/features/home/presentation/widgets/home_trust_badges.dart
//
// PURPOSE:
//   4 small cards showing key selling points:
//   Fast Delivery · Buyer Protection · Easy Returns · Mobile Pay
//
//   WHAT YOU LEARN HERE:
//   - Using a List of Maps to hold repetitive data
//     instead of writing 4 separate container widgets
//   - List.generate() to loop over data and build widgets
//   - The difference between hardcoded UI and data-driven UI
//
//   DATA-DRIVEN UI PRINCIPLE:
//   Instead of writing Container() × 4 with different text,
//   we define the data in a list and loop over it.
//   Adding a 5th badge = adding one Map to the list. Done.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class HomeTrustBadges extends StatelessWidget {
  const HomeTrustBadges({super.key});

  // ----------------------------------------------------------
  // BADGE DATA
  // Defined as a static const so it's created once at compile
  // time and shared across all instances of HomeTrustBadges.
  // ----------------------------------------------------------
  static const List<Map<String, dynamic>> _badges = [
    {
      'icon':  Icons.local_shipping_outlined,
      'title': 'Fast Delivery',
      'sub':   'Nationwide',
    },
    {
      'icon':  Icons.shield_outlined,
      'title': 'Buyer Protection',
      'sub':   '100% Guaranteed',
    },
    {
      'icon':  Icons.refresh,
      'title': 'Easy Returns',
      'sub':   '7-day policy',
    },
    {
      'icon':  Icons.phone_android,
      'title': 'Mobile Pay',
      'sub':   'Airtel & Mpamba',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      // List.generate(count, builder) creates [count] widgets
      children: List.generate(_badges.length, (index) {
        final badge       = _badges[index];
        final isLastItem  = index == _badges.length - 1;

        return Expanded(
          child: Container(
            // Add right margin to all except the last item
            margin: EdgeInsets.only(right: isLastItem ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in a colored circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    badge['icon'] as IconData,
                    size: 17,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badge['title'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  badge['sub'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
